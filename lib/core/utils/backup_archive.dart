import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:shoto/core/utils/backup_manifest.dart';

/// One screenshot on its way into an archive: its bytes and everything the
/// manifest needs to describe it.
///
/// [path] is filled in by [BackupArchive.write], not by the caller — naming is
/// the archive's job, and letting callers choose is how two screenshots end up
/// writing to the same entry.
class BackupSource {
  final Uint8List bytes;

  /// Used only for its extension, so a restored JPEG is still a JPEG.
  final String originalName;

  final int? folderIndex;
  final bool isFavorite;
  final String? ocrText;
  final String? phash;
  final List<String> visualLabels;
  final DateTime addedAt;

  const BackupSource({
    required this.bytes,
    required this.originalName,
    required this.folderIndex,
    required this.isFavorite,
    required this.ocrText,
    required this.phash,
    required this.visualLabels,
    required this.addedAt,
  });
}

/// A screenshot recovered from an archive.
class BackupEntry {
  final BackupItem item;
  final Uint8List bytes;
  const BackupEntry({required this.item, required this.bytes});
}

/// What reading an archive produced, including what it could not.
class BackupContents {
  final BackupManifest manifest;
  final List<BackupEntry> entries;

  /// Entries the manifest listed whose image was missing from the archive.
  ///
  /// Distinct from a damaged manifest line: here the app knows a screenshot
  /// existed and knows where it belonged, but the bytes are gone. That is
  /// worth telling the user separately, because it means the archive itself
  /// was truncated rather than merely written by an older build.
  final int missingImages;

  /// Manifest lines too damaged to read at all.
  final int skippedItems;
  final int skippedFolders;

  const BackupContents({
    required this.manifest,
    required this.entries,
    required this.missingImages,
    required this.skippedItems,
    required this.skippedFolders,
  });

  bool get isComplete =>
      missingImages == 0 && skippedItems == 0 && skippedFolders == 0;
}

/// Reads and writes the SHOTO backup container.
///
/// **A plain ZIP, deliberately.** A private format would be marginally smaller
/// and would make the backup worthless the day this app stops being
/// installable — which is the one day a backup most needs to work. Any unzip
/// tool on any machine gets the pictures out, and the manifest beside them is
/// readable JSON explaining how they were filed.
///
/// Stored without compression on purpose: PNG and JPEG are already compressed,
/// so deflating them again spends real time on a large library to save
/// approximately nothing.
abstract class BackupArchive {
  BackupArchive._();

  /// Builds the archive bytes.
  ///
  /// Entry names are assigned here and zero-padded so a directory listing
  /// sorts the way the library does, which matters only to a human poking
  /// around inside the zip — but that human is the whole reason the format is
  /// a zip.
  static Uint8List write({
    required List<BackupFolder> folders,
    required List<BackupSource> sources,
  }) {
    final Archive archive = Archive();
    final List<BackupItem> items = <BackupItem>[];

    for (int i = 0; i < sources.length; i++) {
      final BackupSource source = sources[i];
      final String name =
          '${BackupManifest.imageDirectory}/'
          '${(i + 1).toString().padLeft(5, '0')}'
          '${_extensionOf(source.originalName)}';

      archive.add(ArchiveFile.bytes(name, source.bytes));
      items.add(
        BackupItem(
          path: name,
          // Trusted from the caller but bounded here as well: an index the
          // manifest cannot resolve on the way back in would silently unfile
          // the screenshot, and it is cheaper to refuse to write it.
          folderIndex:
              source.folderIndex != null &&
                  source.folderIndex! >= 0 &&
                  source.folderIndex! < folders.length
              ? source.folderIndex
              : null,
          isFavorite: source.isFavorite,
          ocrText: source.ocrText,
          phash: source.phash,
          visualLabels: source.visualLabels,
          addedAt: source.addedAt,
        ),
      );
    }

    // Written last so the images are already in the archive when a reader
    // streams it, and named at the root so it is the first thing anybody
    // opening the zip sees.
    archive.add(
      ArchiveFile.string(
        BackupManifest.fileName,
        BackupManifest.now(folders: folders, items: items).encode(),
      ),
    );

    return ZipEncoder().encodeBytes(archive, level: DeflateLevel.none);
  }

  /// Reads an archive produced by [write].
  ///
  /// Throws [BackupFormatException] when the file is not a zip, holds no
  /// manifest, or holds one this build must refuse. Individual images going
  /// missing is not fatal — it is counted in [BackupContents.missingImages]
  /// and the rest are restored, because a truncated archive still holds most
  /// of somebody's library.
  static BackupContents read(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupFormatException('not a readable zip archive');
    }

    final ArchiveFile? manifestFile = _findFile(
      archive,
      BackupManifest.fileName,
    );
    if (manifestFile == null) {
      throw const BackupFormatException('no manifest inside the archive');
    }

    final BackupParseResult parsed = BackupManifest.decode(
      utf8.decode(manifestFile.readBytes() ?? <int>[], allowMalformed: true),
    );

    int missing = 0;
    final List<BackupEntry> entries = <BackupEntry>[];
    for (final BackupItem item in parsed.manifest.items) {
      final ArchiveFile? file = _findFile(archive, item.path);
      final List<int>? content = file?.readBytes();
      if (content == null || content.isEmpty) {
        missing++;
        continue;
      }
      entries.add(
        BackupEntry(item: item, bytes: Uint8List.fromList(content)),
      );
    }

    return BackupContents(
      manifest: parsed.manifest,
      entries: entries,
      missingImages: missing,
      skippedItems: parsed.skippedItems,
      skippedFolders: parsed.skippedFolders,
    );
  }

  /// Zip entries can be written with either separator and some tools prefix a
  /// leading `./`, so matching on the exact string alone loses files that are
  /// present.
  static ArchiveFile? _findFile(Archive archive, String path) {
    final String wanted = _normalize(path);
    for (final ArchiveFile file in archive.files) {
      if (!file.isFile) continue;
      if (_normalize(file.name) == wanted) return file;
    }
    return null;
  }

  static String _normalize(String path) {
    String value = path.replaceAll('\\', '/');
    while (value.startsWith('./')) {
      value = value.substring(2);
    }
    while (value.startsWith('/')) {
      value = value.substring(1);
    }
    return value.toLowerCase();
  }

  /// Falls back to `.png` rather than writing an extensionless entry: the
  /// restore hands these to the gallery, which decides how to store an image
  /// partly by its name.
  static String _extensionOf(String name) {
    final int dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return '.png';
    final String extension = name.substring(dot).toLowerCase();
    if (extension.length > 5 || extension.contains('/')) return '.png';
    return extension;
  }
}
