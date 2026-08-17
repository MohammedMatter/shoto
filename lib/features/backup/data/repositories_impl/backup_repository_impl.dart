import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shoto/core/utils/backup_archive.dart';
import 'package:shoto/core/utils/backup_manifest.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
import 'package:shoto/features/backup/domain/entities/restore_plan.dart';
import 'package:shoto/features/backup/domain/repositories/backup_repository.dart';
import 'package:shoto/features/folders/data/data_sources/folders_local_data_source.dart';
import 'package:shoto/features/folders/data/models/folder_model.dart';
import 'package:shoto/features/screenshots/data/data_sources/screenshot_metadata_local_data_source.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  final ScreenshotRepository _screenshots;
  final FoldersLocalDataSource _folders;
  final ScreenshotMetadataLocalDataSource _metadata;

  BackupRepositoryImpl(this._screenshots, this._folders, this._metadata);

  @override
  Future<BackupResult> createBackup({
    void Function(int done, int total)? onProgress,
  }) async {
    await _sweepOldArchives();

    final List<FolderModel> folders = await _folders.getFolders();
    final List<ScreenshotEntity> library = await _screenshots
        .getAllScreenshots();
    final Map<String, String> ocr = await _screenshots.getCachedOcrText();
    final Map<String, List<String>> labels = await _screenshots
        .getCachedVisualLabels();
    final Map<String, String> hashes = await _screenshots
        .getCachedPerceptualHashes();

    // Folder ids are meaningless in the archive, so the manifest's own list
    // order becomes the addressing scheme and this is the translation.
    final Map<int, int> indexOfFolder = <int, int>{
      for (int i = 0; i < folders.length; i++) folders[i].id: i,
    };

    // The same trick for the verbs the user wrote. Their ids are generated
    // from this device's clock, so they travel by position too.
    final List<CustomIntent> customIntents = await _screenshots
        .getCustomIntents();
    final Map<String, int> indexOfCustomIntent = <String, int>{
      for (int i = 0; i < customIntents.length; i++) customIntents[i].id: i,
    };

    final File file = File(
      p.join((await getTemporaryDirectory()).path, _fileName()),
    );

    // Opened before the loop and written through as we go. The images are
    // never collected into a list: on a library of several hundred that list
    // plus the finished archive beside it was more memory than the process
    // gets, and the backup died on exactly the libraries most worth backing up.
    final BackupWriter writer = BackupArchive.openWriter(
      path: file.path,
      folders: folders
          .map(
            (FolderModel f) => BackupFolder(
              name: f.name,
              color: f.color,
              isPrivate: f.isPrivate,
              createdAt: f.createdAt,
            ),
          )
          .toList(),
      customIntents: customIntents
          .map(
            (CustomIntent i) =>
                BackupCustomIntent(label: i.label, iconKey: i.iconKey),
          )
          .toList(),
    );

    int unreadable = 0;
    int bytesWritten;

    try {
      for (int i = 0; i < library.length; i++) {
        final ScreenshotEntity shot = library[i];
        onProgress?.call(i, library.length);

        // Original bytes, not a thumbnail. A backup that quietly downgrades
        // the picture is not a backup — the restored library would look right
        // until somebody zoomed in.
        final Uint8List? bytes = await shot.asset.originBytes;
        if (bytes == null || bytes.isEmpty) {
          // A gallery entry whose file is gone, or one that lives in the cloud
          // and never downloaded. Counted and reported rather than aborting
          // the whole backup for one picture.
          unreadable++;
          continue;
        }

        writer.add(
          BackupSource(
            bytes: bytes,
            originalName: await shot.asset.titleAsync,
            folderIndex: shot.folderId == null
                ? null
                : indexOfFolder[shot.folderId],
            isFavorite: shot.isFavorite,
            // Carried so a restored library is searchable straight away rather
            // than paying for recognition over again on the new phone.
            ocrText: ocr[shot.id],
            phash: hashes[shot.id],
            visualLabels: labels[shot.id] ?? const <String>[],
            // What the user said they would do with it, and whether they
            // have. Nothing else in a backup is a *promise* the person made to
            // themselves, and losing it is the one loss they would notice by
            // its absence rather than by looking for it.
            intentId: switch (shot.intent?.ref) {
              BuiltInIntent(:final ScreenshotIntent intent) => intent.id,
              _ => null,
            },
            customIntentIndex: switch (shot.intent?.ref) {
              CustomIntent(:final String id) => indexOfCustomIntent[id],
              _ => null,
            },
            intentDoneAt: shot.intent?.doneAt,
            addedAt: shot.asset.createDateTime,
          ),
        );
      }
      onProgress?.call(library.length, library.length);
      bytesWritten = writer.close();
    } catch (_) {
      // A half-written zip on disk is worse than none: the share sheet would
      // happily hand somebody a file that unpacks to nothing.
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }

    return BackupResult(
      filePath: file.path,
      screenshots: writer.count,
      folders: folders.length,
      bytes: bytesWritten,
      unreadable: unreadable,
    );
  }

  @override
  Future<BackupPreview> previewBackup(String filePath) async {
    final BackupReader reader = BackupArchive.openReader(filePath);
    try {
      final List<String> names = reader.manifest.folders
          .map((BackupFolder f) => f.name)
          .toList();
      final Set<String> existing = <String>{
        for (final FolderModel f in await _folders.getFolders())
          f.name.trim().toLowerCase(),
      };
      return BackupPreview(
        folderNames: names,
        screenshots: reader.manifest.items.length,
        // Compared case- and space-insensitively, because "Work" and "work "
        // are the same folder to the person who named them and asking about
        // them separately would look like the app cannot read.
        collidingFolderNames: <String>[
          for (final String name in names)
            if (existing.contains(name.trim().toLowerCase())) name,
        ],
      );
    } finally {
      reader.close();
    }
  }

  @override
  Future<RestoreResult> restoreBackup(
    String filePath, {
    FolderMergeChoice onNameClash = FolderMergeChoice.keepSeparate,
    void Function(int done, int total)? onProgress,
  }) async {
    // Opened, not read. `readAsBytes` on the archive cost the whole file in
    // memory before a single picture had been restored, and the decoded images
    // then landed beside it — the same doubling the backup side had.
    final BackupReader reader = BackupArchive.openReader(filePath);

    // Folders first, so every screenshot has somewhere to land. Created fresh
    // rather than matched by name: two folders called "Work" that are not the
    // same folder is a worse outcome than one duplicate the user can merge by
    // hand, and merging by name would silently pour a restored library into
    // folders that happen to share a word.
    // Existing folders by normalised name, so a merge lands in the folder the
    // user already has rather than beside it.
    final Map<String, int> existingByName = <String, int>{
      for (final FolderModel f in await _folders.getFolders())
        f.name.trim().toLowerCase(): f.id,
    };

    final List<int> newFolderIds = <int>[];
    for (final BackupFolder folder in reader.manifest.folders) {
      // **Merging is never assumed.** Two people can genuinely keep two
      // different folders called "Work", and pouring one into the other is a
      // mistake nobody notices until the wrong screenshots are sitting
      // together — so the caller has to have asked, and the default when
      // nobody asked is to keep them apart.
      final int? existing = onNameClash == FolderMergeChoice.merge
          ? existingByName[folder.name.trim().toLowerCase()]
          : null;
      if (existing != null) {
        newFolderIds.add(existing);
        continue;
      }

      final FolderModel created = await _folders.createFolder(
        folder.name,
        folder.color,
        isPrivate: folder.isPrivate,
        // Carried across so restored folders keep their original order. Without
        // this they were all stamped with the restore's own timestamp, and a
        // library of folders built up over a year came back looking as though
        // it had been made in one second.
        createdAt: folder.createdAt,
      );
      newFolderIds.add(created.id);
      // Registered so a backup holding the same name twice merges its own
      // duplicates too, instead of producing exactly the pile this option
      // exists to prevent.
      existingByName[created.name.trim().toLowerCase()] = created.id;
    }

    // **Verbs merge by name, without asking.** Folders get a prompt because
    // two folders called "Work" can genuinely be two different piles, and
    // pouring one into the other mixes contents that were meant to stay apart.
    // An intent has no contents to mix: it is a word, and two identical words
    // in one picker are not two categories, they are a bug the user has to
    // clean up by hand. Matched the same way folder names are compared, so
    // "Return it" and "return it " are the one verb they obviously are.
    final Map<String, CustomIntent> intentsByLabel = <String, CustomIntent>{
      for (final CustomIntent intent in await _screenshots.getCustomIntents())
        intent.label.trim().toLowerCase(): intent,
    };

    // Positional, parallel to the manifest's list, exactly like newFolderIds.
    // Null entries are verbs this restore could not create; the screenshots
    // pointing at them come back with no intent rather than the wrong one.
    final List<CustomIntent?> restoredIntents = <CustomIntent?>[];
    for (final BackupCustomIntent intent in reader.manifest.customIntents) {
      final String key = intent.label.trim().toLowerCase();
      final CustomIntent? existing = intentsByLabel[key];
      if (existing != null) {
        restoredIntents.add(existing);
        continue;
      }
      try {
        // Deliberately not checked against the free-tier cap. A restore is the
        // user getting their own data back, and every other part of it already
        // works this way — folders past the free limit and favourites past the
        // fifty-screenshot cap both restore in full. A backup that came back
        // missing the words its owner wrote would be a paywall placed on
        // recovering from a broken phone.
        final CustomIntent created = await _screenshots.createCustomIntent(
          label: intent.label,
          iconKey: intent.iconKey,
        );
        restoredIntents.add(created);
        // Registered so a backup holding the same verb twice merges its own
        // duplicates, same as the folder loop above.
        intentsByLabel[key] = created;
      } catch (error) {
        debugPrint('Shoto restore could not create "${intent.label}": $error');
        restoredIntents.add(null);
      }
    }

    int failed = 0;
    int restored = 0;
    int seen = 0;

    final int total = reader.manifest.items.length;
    try {
      // Pulled one at a time. Each image is decoded when the loop reaches it
      // and released once it has been saved, so a thousand-screenshot archive
      // costs the same as a ten-screenshot one.
      for (final BackupEntry entry in reader.entries()) {
        onProgress?.call(seen++, total);

        try {
          // Writes the image into Shoto's album and claims it for this
          // account, handing back the id the *new* device assigned. Everything
          // below is keyed off that id — the one from the old phone never
          // appears.
          final String assetId = await _screenshots.saveGeneratedImage(
            entry.bytes,
            filename: p.basenameWithoutExtension(entry.item.path),
            // The archive has carried this since the format was written and
            // the restore was throwing it away, so every restored library
            // came back dated to the day it was restored — one undifferentiated
            // block under "Today", with the real history gone.
            createdAt: entry.item.addedAt,
          );

          final int? folderIndex = entry.item.folderIndex;
          if (folderIndex != null && folderIndex < newFolderIds.length) {
            await _screenshots.assignFolder(<String>[
              assetId,
            ], newFolderIds[folderIndex]);
          }
          if (entry.item.isFavorite) {
            await _screenshots.setFavorite(assetId, true);
          }
          final String? text = entry.item.ocrText;
          if (text != null && text.isNotEmpty) {
            await _metadata.saveOcrText(assetId, text);
          }
          if (entry.item.visualLabels.isNotEmpty) {
            await _metadata.saveVisualLabels(assetId, entry.item.visualLabels);
          }
          final String? phash = entry.item.phash;
          if (phash != null && phash.isNotEmpty) {
            await _metadata.savePerceptualHashes(<String, String>{
              assetId: phash,
            });
          }

          final IntentRef? intent = _intentFor(entry.item, restoredIntents);
          if (intent != null) {
            // The original completion timestamp travels with it, so a library
            // where two hundred things were already ticked off does not come
            // back claiming two hundred things are owed — or claiming they
            // were all finished on the day of the restore.
            await _screenshots.setIntent(
              assetId,
              intent,
              doneAt: entry.item.intentDoneAt,
            );
          }
          restored++;
        } catch (error, stack) {
          // One picture the device refuses to save must not cost the other
          // four hundred. Counted, reported, and the loop carries on.
          debugPrint('Shoto restore failed for ${entry.item.path}: $error');
          debugPrintStack(stackTrace: stack, maxFrames: 6);
          failed++;
        }
      }
      onProgress?.call(total, total);
    } finally {
      // Releases the open handle on the archive even when a restore blows up
      // partway, so the file is not left locked on the device.
      reader.close();
    }

    return RestoreResult(
      screenshots: restored,
      folders: newFolderIds.length,
      missing: reader.missingImages + reader.skippedItems,
      failed: failed,
    );
  }

  /// Resolves what an item said its intent was against what this restore
  /// actually created.
  ///
  /// Null for three cases, all of which mean the screenshot arrives with no
  /// intent rather than the wrong one: it never had one, it names a built-in
  /// verb this build does not know (a backup from a newer version), or the
  /// custom verb it pointed at could not be created here.
  static IntentRef? _intentFor(BackupItem item, List<CustomIntent?> restored) {
    final String? builtInId = item.intentId;
    if (builtInId != null) {
      final ScreenshotIntent? intent = ScreenshotIntent.fromId(builtInId);
      return intent == null ? null : BuiltInIntent(intent);
    }
    final int? index = item.customIntentIndex;
    if (index == null || index < 0 || index >= restored.length) return null;
    return restored[index];
  }

  /// Deletes archives left behind by earlier runs.
  ///
  /// Both sides write into the cache directory — the backup builds its zip
  /// there before handing it to the share sheet, and the picker copies the
  /// chosen file there so Dart can read it — and neither used to clean up.
  /// Fourteen files and thirty megabytes had accumulated on the test device in
  /// one afternoon of trying the feature out.
  ///
  /// Run at the *start* of each operation rather than the end: the share sheet
  /// hands the file to another app, and deleting it the moment the sheet
  /// closes races whatever that app is still copying. Clearing last time's
  /// files this time is late enough to be safe and early enough that they
  /// never pile up.
  ///
  /// [keep] is the file about to be used, which must survive the sweep.
  Future<void> _sweepOldArchives({String? keep}) async {
    try {
      final Directory cache = await getTemporaryDirectory();
      if (!await cache.exists()) return;
      await for (final FileSystemEntity entity in cache.list()) {
        if (entity is! File) continue;
        final String name = p.basename(entity.path);
        final bool ours =
            name.startsWith('shoto-backup-') || name.startsWith('restore-');
        if (!ours || !name.endsWith('.zip')) continue;
        if (keep != null && entity.path == keep) continue;
        try {
          await entity.delete();
        } catch (_) {
          // A file another app still holds open. Skipping it costs one stale
          // archive; failing the backup over it costs the backup.
        }
      }
    } catch (error) {
      debugPrint('Shoto cache sweep failed: $error');
    }
  }

  /// Sortable and unambiguous: `shoto-backup-2026-08-04-1330.zip`.
  ///
  /// Dated because people keep several, and a name that collides would have
  /// the file manager silently overwrite last month's copy.
  static String _fileName() {
    final DateTime now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'shoto-backup-${now.year}-${two(now.month)}-${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}.zip';
  }
}
