import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shoto/core/utils/backup_archive.dart';
import 'package:shoto/core/utils/backup_manifest.dart';
import 'package:shoto/features/backup/domain/entities/backup_outcome.dart';
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
  Future<RestoreResult> restoreBackup(
    String filePath, {
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
    final List<int> newFolderIds = <int>[];
    for (final BackupFolder folder in reader.manifest.folders) {
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
          // Writes the image into SHOTO's album and claims it for this
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
          restored++;
        } catch (error, stack) {
          // One picture the device refuses to save must not cost the other
          // four hundred. Counted, reported, and the loop carries on.
          debugPrint('SHOTO restore failed for ${entry.item.path}: $error');
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
