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

/// Writes one screenshot at a time into an open archive.
///
/// **The whole point is that it never holds the library.** The obvious version
/// of this class collected every screenshot's bytes into a list and handed the
/// lot to the zip encoder, which then built the finished archive as a second
/// copy in memory. Peak cost was twice the library, so a phone with a few
/// hundred screenshots — the phones this feature exists for — ran out of memory
/// and the backup died. Here each image is written through to the sink and
/// released before the next one is read, so the cost is one screenshot no
/// matter how big the library gets.
///
/// The manifest is the one thing that does accumulate, because it cannot be
/// written until every entry has been named. It is text, and small next to the
/// pictures it describes.
class BackupWriter {
  final ZipEncoder _encoder;
  final OutputStream _sink;
  final List<BackupFolder> _folders;
  final List<BackupItem> _items = <BackupItem>[];
  bool _closed = false;

  BackupWriter._(this._encoder, this._sink, this._folders);

  /// How many screenshots have been written so far.
  int get count => _items.length;

  /// Writes [source] into the archive and forgets its bytes.
  ///
  /// Entry names are assigned here rather than by the caller, zero-padded so a
  /// directory listing sorts the way the library does. That matters only to a
  /// human poking around inside the zip — but that human is the whole reason
  /// the format is a zip.
  void add(BackupSource source) {
    if (_closed) {
      throw StateError('BackupWriter.add called after close');
    }

    final String name =
        '${BackupManifest.imageDirectory}/'
        '${(count + 1).toString().padLeft(5, '0')}'
        '${BackupArchive._extensionOf(source.originalName)}';

    // autoClose lets the encoder release the entry's bytes the moment they are
    // on their way to the sink, which is what keeps the loop flat.
    _encoder.add(ArchiveFile.bytes(name, source.bytes));

    _items.add(
      BackupItem(
        path: name,
        // Trusted from the caller but bounded here as well: an index the
        // manifest cannot resolve on the way back in would silently unfile
        // the screenshot, and it is cheaper to refuse to write it.
        folderIndex:
            source.folderIndex != null &&
                source.folderIndex! >= 0 &&
                source.folderIndex! < _folders.length
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

  /// Appends the manifest, finishes the zip, and returns the archive's size.
  ///
  /// The manifest goes in last so the images are already present when a reader
  /// streams the file, and sits at the root so it is the first thing anybody
  /// opening the zip sees.
  int close() {
    if (_closed) {
      throw StateError('BackupWriter.close called twice');
    }
    _closed = true;

    _encoder.add(
      ArchiveFile.string(
        BackupManifest.fileName,
        BackupManifest.now(folders: _folders, items: _items).encode(),
      ),
    );
    _encoder.endEncode();

    final int length = _sink.length;
    _sink.closeSync();
    return length;
  }
}

/// Reads an archive one screenshot at a time.
///
/// The mirror of [BackupWriter], and for the same reason: the eager version
/// decoded every image into a list before the restore had saved a single one,
/// which cost the whole library in memory on top of the copy already read off
/// disk. Here the zip's directory is read up front — it is small — and each
/// image is pulled from the file only when the caller asks for it.
class BackupReader {
  final BackupManifest manifest;
  final int skippedItems;
  final int skippedFolders;

  final Archive _archive;
  final InputFileStream? _input;
  final Map<String, ArchiveFile> _byName;
  int _missing = 0;

  BackupReader._({
    required this.manifest,
    required this.skippedItems,
    required this.skippedFolders,
    required Archive archive,
    required InputFileStream? input,
    required Map<String, ArchiveFile> byName,
  }) : _archive = archive,
       _input = input,
       _byName = byName;

  /// Entries the manifest listed whose image was missing from the archive.
  ///
  /// Only meaningful once [entries] has been walked to the end.
  int get missingImages => _missing;

  /// Walks the archive, yielding each screenshot the manifest can account for.
  ///
  /// A missing image is counted rather than thrown: a truncated archive still
  /// holds most of somebody's library, and refusing all of it to punish the
  /// part that did not survive helps nobody.
  Iterable<BackupEntry> entries() sync* {
    _missing = 0;
    for (final BackupItem item in manifest.items) {
      final ArchiveFile? file = _byName[BackupArchive._normalize(item.path)];
      final Uint8List? content = file?.readBytes();
      if (content == null || content.isEmpty) {
        _missing++;
        continue;
      }
      yield BackupEntry(item: item, bytes: content);
      // Releases this entry's decoded bytes before the next one is read.
      file!.closeSync();
    }
  }

  void close() {
    _archive.clearSync();
    _input?.closeSync();
  }
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

  /// Opens an archive that writes straight to [path].
  ///
  /// This is what the app uses. Nothing is buffered beyond the screenshot
  /// currently being written, so a library of any size costs the same.
  static BackupWriter openWriter({
    required String path,
    required List<BackupFolder> folders,
  }) => _openWriter(OutputFileStream(path), folders);

  /// Opens the archive at [path] for reading, without loading it.
  ///
  /// Throws [BackupFormatException] when the file is not a zip, holds no
  /// manifest, or holds one this build must refuse.
  static BackupReader openReader(String path) {
    final InputFileStream input = InputFileStream(path);
    try {
      return _openReader(_decode(() => ZipDecoder().decodeStream(input)), input);
    } catch (_) {
      input.closeSync();
      rethrow;
    }
  }

  /// Builds the archive entirely in memory and returns its bytes.
  ///
  /// Kept for tests and small callers. **Not for the library** — that is what
  /// [openWriter] is for, and the whole reason it exists.
  static Uint8List write({
    required List<BackupFolder> folders,
    required List<BackupSource> sources,
  }) {
    final OutputMemoryStream sink = OutputMemoryStream();
    final BackupWriter writer = _openWriter(sink, folders);
    for (final BackupSource source in sources) {
      writer.add(source);
    }
    writer.close();
    return sink.getBytes();
  }

  /// Reads an archive held in memory.
  ///
  /// Kept for tests and small callers, with the same caveat as [write]: the
  /// app restores through [openReader] so it never holds the library at once.
  static BackupContents read(Uint8List bytes) {
    final BackupReader reader = _openReader(
      _decode(() => ZipDecoder().decodeBytes(bytes)),
      null,
    );
    final List<BackupEntry> entries = reader.entries().toList();
    return BackupContents(
      manifest: reader.manifest,
      entries: entries,
      missingImages: reader.missingImages,
      skippedItems: reader.skippedItems,
      skippedFolders: reader.skippedFolders,
    );
  }

  static BackupWriter _openWriter(
    OutputStream sink,
    List<BackupFolder> folders,
  ) {
    final ZipEncoder encoder = ZipEncoder();
    encoder.startEncode(sink, level: DeflateLevel.none);
    return BackupWriter._(encoder, sink, folders);
  }

  static BackupReader _openReader(Archive archive, InputFileStream? input) {
    // Built once instead of scanning the file list per manifest line. The scan
    // was quadratic, which nobody notices at ten screenshots and everybody
    // notices at a thousand.
    final Map<String, ArchiveFile> byName = <String, ArchiveFile>{};
    for (final ArchiveFile file in archive.files) {
      if (file.isFile) byName.putIfAbsent(_normalize(file.name), () => file);
    }

    final ArchiveFile? manifestFile = byName[_normalize(
      BackupManifest.fileName,
    )];
    if (manifestFile == null) {
      throw const BackupFormatException('no manifest inside the archive');
    }

    final BackupParseResult parsed = BackupManifest.decode(
      utf8.decode(manifestFile.readBytes() ?? <int>[], allowMalformed: true),
    );
    manifestFile.closeSync();

    return BackupReader._(
      manifest: parsed.manifest,
      skippedItems: parsed.skippedItems,
      skippedFolders: parsed.skippedFolders,
      archive: archive,
      input: input,
      byName: byName,
    );
  }

  static Archive _decode(Archive Function() decode) {
    try {
      return decode();
    } catch (_) {
      throw const BackupFormatException('not a readable zip archive');
    }
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
