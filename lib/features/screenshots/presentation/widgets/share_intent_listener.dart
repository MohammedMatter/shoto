import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/use_cases/assign_folder_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/import_shared_screenshot_use_case.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/shared_image_choice_sheet.dart';

/// Wraps the app shell and listens for images shared into Shoto from other
/// apps (via the OS share sheet). Each image is saved into the device
/// gallery under the "Shoto" album straight away (so it shows up on Home
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

    // Wait for the current frame so the shell (and a Navigator/Overlay to
    // host the bottom sheet) is guaranteed to be mounted, including on a
    // cold start triggered by the share itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _offer(images);
    });
  }

  /// **The choice comes before the import, not after it.**
  ///
  /// Every shared picture used to be written into the gallery and the library
  /// on arrival, and only then was the user asked anything — so somebody who
  /// shared a screenshot in order to cover an account number had already
  /// gained a library item they never asked for by the time they were offered
  /// a folder for it. Asking first is what makes "nothing joins your library
  /// until you say so" true on this path as well as the others.
  Future<void> _offer(List<SharedMediaFile> images) async {
    // Covering is offered for one picture only, and the rule lives in
    // [coveringOffered] rather than here — the quick-save sheet asks the same
    // question on the path Android actually takes, and the two answering
    // differently is how the wrong three pictures get sent.
    if (coveringOffered(images.length)) {
      final SharedImageChoice? choice = await showSharedImageChoiceSheet(
        context,
      );
      if (choice == null || !mounted) return;
      if (choice == SharedImageChoice.protect) {
        await _protect(images.first);
        return;
      }
    }

    await _save(images);
  }

  /// Straight into Safe Share on the file the other app handed over, which is
  /// never imported. Covering it and sending it on leaves nothing behind.
  Future<void> _protect(SharedMediaFile image) async {
    await Navigator.of(context).push(
      FadeSlidePageRoute(
        builder: (_) => SafeSharePage.incoming(incoming: File(image.path)),
      ),
    );
  }

  Future<void> _save(List<SharedMediaFile> images) async {
    final List<String> importedIds = [];
    for (final SharedMediaFile file in images) {
      try {
        importedIds.add(await sl<ImportSharedScreenshotUseCase>()(file.path));
      } catch (_) {
        // Best-effort import — skip files that fail (e.g. unreadable path).
      }
    }
    if (importedIds.isEmpty || !mounted) return;
    await _promptForFolder(importedIds, count: images.length);
  }

  Future<void> _promptForFolder(
    List<String> assetIds, {
    required int count,
  }) async {
    // Freshly imported assets have no meta row yet, so filing any of them
    // (even "don't add to a folder") creates one — all of them count as new.
    final bool allowed = await ensureUnderScreenshotLimit(
      context,
      additionalNewItems: assetIds.length,
    );
    if (!allowed || !mounted) return;
    showMoveToFolderSheet(
      context,
      title: context.l10n.shareSavedPrompt(count),
      noFolderLabel: "Don't add to a folder",
      onSelected: (folderId) async {
        await sl<AssignFolderUseCase>()(assetIds, folderId);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.shareSavedCount(count)),
              backgroundColor: context.colors.surfaceVariant,
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
