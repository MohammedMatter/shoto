import 'dart:convert';

/// Raised when a file does not describe a Shoto backup at all, or describes
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

/// A verb the user wrote for themselves, travelling without its id.
///
/// Same reasoning as [BackupFolder], one step further. A custom intent's id is
/// generated from the clock on the device that made it, so carrying it across
/// would either collide with a row the receiving account already has (restoring
/// your own backup onto the same phone) or bake one device's timestamps into
/// another's database forever. Items point at these **by position in the
/// manifest's list**, and the restore assigns real ids as it inserts.
///
/// The label is the user's own words and is never translated — see
/// [CustomIntent].
class BackupCustomIntent {
  final String label;

  /// Names a glyph in `IntentIcons`. An unknown key falls back at display
  /// time, so a backup made by a newer build restores with a plain flag rather
  /// than failing.
  final String iconKey;

  const BackupCustomIntent({required this.label, required this.iconKey});

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'icon': iconKey,
  };

  static BackupCustomIntent? tryFrom(Object? raw) {
    if (raw is! Map) return null;
    final Object? label = raw['label'];
    // The label is the whole intent. Without it there is no verb to restore,
    // and an unnamed chip is worse than a screenshot that simply arrives with
    // nothing set.
    if (label is! String || label.trim().isEmpty) return null;
    return BackupCustomIntent(
      label: label,
      iconKey: raw['icon'] is String ? raw['icon'] as String : _fallbackIcon,
    );
  }

  /// Matches `IntentIcons.fallback`, kept as a literal so this file stays free
  /// of Flutter imports.
  static const String _fallbackIcon = 'flag';
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

  /// A built-in intent's permanent id — `buy`, `read` — or null.
  ///
  /// **The one identifier in this format that is carried verbatim**, and it
  /// can be because it is not a database key: it is a constant this app ships,
  /// the same string in every install of every version. An id the receiving
  /// build does not know reads as no intent, exactly as it does everywhere
  /// else.
  final String? intentId;

  /// Index into [BackupManifest.customIntents], or null.
  ///
  /// Mutually exclusive with [intentId]: a screenshot has one intent, and it
  /// is either one Shoto ships or one the user wrote.
  final int? customIntentIndex;

  /// When the user ticked this intent off, or null while it is still waiting.
  ///
  /// Carried rather than reset, so a restored library does not present a
  /// hundred finished tasks as outstanding work — which would make the app's
  /// one shrinking number jump on the day the user's phone broke.
  final DateTime? intentDoneAt;

  const BackupItem({
    required this.path,
    required this.folderIndex,
    required this.isFavorite,
    required this.ocrText,
    required this.phash,
    required this.visualLabels,
    required this.addedAt,
    this.intentId,
    this.customIntentIndex,
    this.intentDoneAt,
  });

  BackupItem copyWith({
    int? folderIndex,
    bool clearFolder = false,
    bool clearIntent = false,
  }) {
    return BackupItem(
      path: path,
      folderIndex: clearFolder ? null : (folderIndex ?? this.folderIndex),
      isFavorite: isFavorite,
      ocrText: ocrText,
      phash: phash,
      visualLabels: visualLabels,
      addedAt: addedAt,
      intentId: clearIntent ? null : intentId,
      customIntentIndex: clearIntent ? null : customIntentIndex,
      // Dropped with the intent it belonged to. A completion timestamp with
      // nothing to have completed is a fact about no task.
      intentDoneAt: clearIntent ? null : intentDoneAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'path': path,
    if (folderIndex != null) 'folder': folderIndex,
    if (isFavorite) 'fav': true,
    if (ocrText != null && ocrText!.isNotEmpty) 'text': ocrText,
    if (phash != null && phash!.isNotEmpty) 'phash': phash,
    if (visualLabels.isNotEmpty) 'labels': visualLabels,
    if (intentId != null) 'intent': intentId,
    if (customIntentIndex != null) 'customIntent': customIntentIndex,
    if (intentDoneAt != null)
      'intentDone': intentDoneAt!.toUtc().millisecondsSinceEpoch,
    'added': addedAt.toUtc().millisecondsSinceEpoch,
  };

  /// Null when the entry carries no usable path — the one field without which
  /// there is nothing to restore.
  static BackupItem? tryFrom(Object? raw) {
    if (raw is! Map) return null;
    final Object? path = raw['path'];
    if (path is! String || path.trim().isEmpty) return null;

    // A built-in id wins if a malformed file somehow carries both. It is the
    // one of the two that needs nothing else to resolve, so preferring it
    // cannot leave the screenshot pointing at a verb that is not there.
    final String? intentId = raw['intent'] is String
        ? raw['intent'] as String
        : null;

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
      intentId: intentId,
      customIntentIndex: intentId == null ? _asInt(raw['customIntent']) : null,
      intentDoneAt: _asDate(raw['intentDone']),
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

/// The index of a Shoto backup: what is in the archive and how it was filed.
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

  /// The verbs this account wrote for itself. Empty for most backups, and
  /// absent entirely from any made before custom intents existed.
  final List<BackupCustomIntent> customIntents;

  final List<BackupItem> items;

  const BackupManifest({
    required this.version,
    required this.createdAt,
    required this.folders,
    required this.items,
    this.customIntents = const <BackupCustomIntent>[],
  });

  BackupManifest.now({
    required this.folders,
    required this.items,
    this.customIntents = const <BackupCustomIntent>[],
  }) : version = currentVersion,
       createdAt = DateTime.now().toUtc();

  String encode() => jsonEncode(<String, Object?>{
    'kind': kind,
    'version': version,
    'created': createdAt.toUtc().millisecondsSinceEpoch,
    'folders': folders.map((BackupFolder f) => f.toJson()).toList(),
    // Omitted entirely when there are none, which is the common case. An
    // absent key and an empty list mean the same thing to the reader, and the
    // absent one keeps the manifest readable for the people this format is a
    // plain zip for.
    if (customIntents.isNotEmpty)
      'customIntents': customIntents
          .map((BackupCustomIntent i) => i.toJson())
          .toList(),
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
      throw const BackupFormatException('not a Shoto backup');
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
        'made by a newer version of Shoto (format $version)',
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

    // Damaged entries are dropped silently rather than counted. The two
    // skipped-counters are shown to the user as "part of your backup could not
    // be read", and a lost verb is not that: the screenshots it described all
    // still restore, with their pictures, their folders and their favourites
    // intact, minus one word. Putting it in the same number as a lost
    // screenshot would make a trivial loss look like a serious one.
    final List<BackupCustomIntent> customIntents = <BackupCustomIntent>[];
    if (root['customIntents'] is List) {
      for (final Object? raw in root['customIntents'] as List) {
        final BackupCustomIntent? intent = BackupCustomIntent.tryFrom(raw);
        if (intent != null) customIntents.add(intent);
      }
    }

    int skippedItems = 0;
    final List<BackupItem> items = <BackupItem>[];
    if (root['items'] is List) {
      for (final Object? raw in root['items'] as List) {
        BackupItem? item = BackupItem.tryFrom(raw);
        if (item == null) {
          skippedItems++;
          continue;
        }

        // Same rule as the folder index below, for the same reason: dropping a
        // damaged verb renumbers every one after it, and an index written
        // against the original list would then name the wrong verb. A
        // screenshot that arrives with no intent is a small, visible loss; one
        // that arrives filed under somebody else's word is a wrong answer
        // nobody goes looking for.
        final int? intentIndex = item.customIntentIndex;
        if (intentIndex != null &&
            (intentIndex < 0 || intentIndex >= customIntents.length)) {
          item = item.copyWith(clearIntent: true);
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
        customIntents: customIntents,
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
