import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_shared_screenshot_use_case.dart';

/// Wraps the app shell and listens for images shared into SHOTO from other
/// apps (via the OS share sheet). Each image is saved into the device
/// gallery under the "SHOTO" album straight away (so it shows up on Home
/// immediately), then the user is prompted to file it into a folder.
class ShareIntentListener extends StatefulWidget {
  final Widget child;
  const ShareIntentListener({super.key, required this.child});

  @override
  State<ShareIntentListener> createState() => _ShareIntentListenerState();
}

class _ShareIntentListenerState extends State<ShareIntentListener> {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  @override
  void initState() {
    super.initState();
    _handleInitialShare();
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedFiles,
    );
  }

  Future<void> _handleInitialShare() async {
    final List<SharedMediaFile> files = await ReceiveSharingIntent.instance
        .getInitialMedia();
    if (files.isEmpty) return;
    await _handleSharedFiles(files);
    await ReceiveSharingIntent.instance.reset();
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    final List<SharedMediaFile> images = files
        .where((file) => file.type == SharedMediaType.image)
        .toList();
    if (images.isEmpty) return;

    final List<String> importedIds = [];
    for (final SharedMediaFile file in images) {
      try {
        importedIds.add(await sl<ImportSharedScreenshotUseCase>()(file.path));
      } catch (_) {
        // Best-effort import — skip files that fail (e.g. unreadable path).
      }
    }
    if (importedIds.isEmpty) return;

    // Wait for the current frame so the shell (and a Navigator/Overlay to
    // host the bottom sheet) is guaranteed to be mounted, including on a
    // cold start triggered by the share itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _promptForFolder(importedIds, count: images.length);
    });
  }

  void _promptForFolder(List<String> assetIds, {required int count}) {
    showMoveToFolderSheet(
      context,
      title: count == 1
          ? 'Screenshot saved! Add it to a folder?'
          : 'Screenshots saved! Add them to a folder?',
      noFolderLabel: "Don't add to a folder",
      onSelected: (folderId) async {
        await sl<AssignFolderUseCase>()(assetIds, folderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                count == 1 ? 'Screenshot saved' : '$count screenshots saved',
              ),
              backgroundColor: AppColors.surfaceVariant,
            ),
          );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
