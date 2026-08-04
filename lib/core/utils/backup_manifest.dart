import 'dart:convert';

/// Raised when a file does not describe a SHOTO backup at all, or describes
/// one this build cannot safely read.
///
/// Deliberately separate from "some entries were unusable": a manifest that
/// cannot be parsed means restoring nothing, and the user has to be told that
/// plainly rather than shown an empty library and left to guess.
class BackupFormatException implements Exception {
  final String reason;
  const BackupFormatException(this.reason);

  @override
  String toString() => 'BackupFormatException: $reason';
}

/// A folder as it travels, which is to say without its primary key.
///
/// The database id is meaningless on the machine this is restored onto —
/// `folders.id` is an AUTOINCREMENT column and the receiving database has its
/// own sequence. Items therefore point at folders by **position in the
/// manifest's list**, and the restore assigns real ids as it inserts.
class BackupFolder {
  final String name;
  final int color;
  final bool isPrivate;
  final DateTime createdAt;

  const BackupFolder({
    required this.name,
    required this.color,
    required this.isPrivate,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'color': color,
    'private': isPrivate,
    'created': createdAt.toUtc().millisecondsSinceEpoch,
  };

  static BackupFolder? tryFrom(Object? raw) {
    if (raw is! Map) return null;
    final Object? name = raw['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return BackupFolder(
      name: name,
      // A folder whose colour did not survive is still a folder. Falling back
      // beats dropping it and taking every screenshot filed in it along.
      color: _asInt(raw['color']) ?? _fallbackColor,
      isPrivate: raw['private'] == true,
      createdAt: _asDate(raw['created']) ?? DateTime.now().toUtc(),
    );
  }

  /// Matches the first entry of `kFolderColors`; the restore has to pick
  /// something and the palette's own first colour is the least surprising.
  static const int _fallbackColor = 0xFF3355FF;
}

/// One screenshot: where its bytes sit inside the archive, plus everything the
/// app knows about it that a photo file cannot carry.
class BackupItem {
  /// Path inside the archive, e.g. `images/00001.png`.
  final String path;

  /// Index into [BackupManifest.folders], or null for unfiled.
  final int? folderIndex;

  final bool isFavorite;

  /// Recognised text, kept so a restored library is searchable immediately
  /// instead of paying for OCR a second time.
  final String? ocrText;

  final String? phash;
  final List<String> visualLabels;
  final DateTime addedAt;

  const BackupItem({
    required this.path,
    required this.folderIndex,
    required this.isFavorite,
    required this.ocrText,
    required this.phash,
    required this.visualLabels,
    required this.addedAt,
  });

  BackupItem copyWith({int? folderIndex, bool clearFolder = false}) {
    return BackupItem(
      path: path,
      folderIndex: clearFolder ? null : (folderIndex ?? this.folderIndex),
      isFavorite: isFavorite,
      ocrText: ocrText,
      phash: phash,
      visualLabels: visualLabels,
      addedAt: addedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    if (folderIndex != null) 'folder': folderIndex,
    if (isFavorite) 'fav': true,
    if (ocrText != null && ocrText!.isNotEmpty) 'text': ocrText,
    if (phash != null && phash!.isNotEmpty) 'phash': phash,
    if (visualLabels.isNotEmpty) 'labels': visualLabels,
    'added': addedAt.toUtc().millisecondsSinceEpoch,
  };

  /// Null when the entry carries no usable path — the one field without which
  /// there is nothing to restore.
  static BackupItem? tryFrom(Object? raw) {
    if (raw is! Map) return null;
    final Object? path = raw['path'];
    if (path is! String || path.trim().isEmpty) return null;

    return BackupItem(
      path: path,
      folderIndex: _asInt(raw['folder']),
      isFavorite: raw['fav'] == true,
      ocrText: raw['text'] is String ? raw['text'] as String : null,
      phash: raw['phash'] is String ? raw['phash'] as String : null,
      visualLabels: <String>[
        if (raw['labels'] is List)
          for (final Object? label in raw['labels'] as List)
            if (label is String) label,
      ],
      addedAt: _asDate(raw['added']) ?? DateTime.now().toUtc(),
    );
  }
}

/// What a parse recovered, and what it could not.
///
/// The count is not decoration. A restore that silently drops entries is the
/// worst possible outcome for a backup — the user believes they are whole and
/// finds out months later — so the number is carried out of the parser and
/// shown.
class BackupParseResult {
  final BackupManifest manifest;

  /// Entries present in the file but too damaged to use.
  final int skippedItems;
  final int skippedFolders;

  const BackupParseResult({
    required this.manifest,
    required this.skippedItems,
    required this.skippedFolders,
  });

  bool get isComplete => skippedItems == 0 && skippedFolders == 0;
}

/// The index of a SHOTO backup: what is in the archive and how it was filed.
///
/// **Nothing here is a database id.** Asset ids are MediaStore ids, which
/// belong to one device and are reassigned when an image is imported
/// elsewhere; folder ids come from an AUTOINCREMENT sequence that the
/// receiving database does not share. A manifest that stored either would
/// restore a library of folders pointing at screenshots that do not exist —
/// so images are addressed by their path inside the archive and folders by
/// their position in this list.
///
/// Signed-in identity is not stored either. A backup restores into whichever
/// account is signed in when it is opened, which is both simpler to reason
/// about and the only behaviour that lets somebody move to a new phone and a
/// new account without their library becoming unreachable.
class BackupManifest {
  /// Marks the file as ours before anything else is read.
  static const String kind = 'shoto.backup';

  /// Bumped only for changes older builds could misread. Adding an optional
  /// field is not one of those — every reader here already tolerates absence.
  static const int currentVersion = 1;

  /// Where the manifest lives inside the archive.
  static const String fileName = 'manifest.json';

  /// Directory inside the archive holding the images.
  static const String imageDirectory = 'images';

  final int version;
  final DateTime createdAt;
  final List<BackupFolder> folders;
  final List<BackupItem> items;

  const BackupManifest({
    required this.version,
    required this.createdAt,
    required this.folders,
    required this.items,
  });

  BackupManifest.now({required this.folders, required this.items})
    : version = currentVersion,
      createdAt = DateTime.now().toUtc();

  String encode() => jsonEncode(<String, Object?>{
    'kind': kind,
    'version': version,
    'created': createdAt.toUtc().millisecondsSinceEpoch,
    'folders': folders.map((BackupFolder f) => f.toJson()).toList(),
    'items': items.map((BackupItem i) => i.toJson()).toList(),
  });

  /// Parses [source], recovering as much as it can.
  ///
  /// Throws [BackupFormatException] only for the three failures that make the
  /// whole file unusable: it is not JSON, it is not ours, or it is newer than
  /// this build understands. Everything else degrades — a damaged folder or
  /// item is skipped and counted, because losing one screenshot out of four
  /// hundred is a far better outcome than refusing all four hundred.
  static BackupParseResult decode(String source) {
    final Object? root;
    try {
      root = jsonDecode(source);
    } catch (_) {
      throw const BackupFormatException('not valid JSON');
    }

    if (root is! Map) throw const BackupFormatException('not an object');
    if (root['kind'] != kind) {
      throw const BackupFormatException('not a SHOTO backup');
    }

    final int? version = _asInt(root['version']);
    if (version == null) {
      throw const BackupFormatException('missing version');
    }
    if (version > currentVersion) {
      // Refusing is the safe answer. A newer manifest may encode a folder or
      // a flag this build has no idea about, and a "best effort" restore of a
      // format we do not know is how a backup quietly loses half of itself.
      throw BackupFormatException(
        'made by a newer version of SHOTO (format $version)',
      );
    }

    int skippedFolders = 0;
    final List<BackupFolder> folders = <BackupFolder>[];
    if (root['folders'] is List) {
      for (final Object? raw in root['folders'] as List) {
        final BackupFolder? folder = BackupFolder.tryFrom(raw);
        if (folder == null) {
          skippedFolders++;
        } else {
          folders.add(folder);
        }
      }
    }

    int skippedItems = 0;
    final List<BackupItem> items = <BackupItem>[];
    if (root['items'] is List) {
      for (final Object? raw in root['items'] as List) {
        final BackupItem? item = BackupItem.tryFrom(raw);
        if (item == null) {
          skippedItems++;
          continue;
        }

        // **A folder reference that does not resolve must not cost the
        // screenshot.** Dropping a folder above renumbers everything after
        // it, and an index written against the original list would then point
        // at the wrong folder — or off the end. Unfiling is recoverable by
        // hand in seconds; filing something into the wrong place is a
        // mistake nobody goes looking for.
        final int? index = item.folderIndex;
        if (index != null && (index < 0 || index >= folders.length)) {
          items.add(item.copyWith(clearFolder: true));
        } else {
          items.add(item);
        }
      }
    }

    return BackupParseResult(
      manifest: BackupManifest(
        version: version,
        createdAt: _asDate(root['created']) ?? DateTime.now().toUtc(),
        folders: folders,
        items: items,
      ),
      skippedItems: skippedItems,
      skippedFolders: skippedFolders,
    );
  }
}

int? _asInt(Object? raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

DateTime? _asDate(Object? raw) {
  final int? millis = _asInt(raw);
  if (millis == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}
