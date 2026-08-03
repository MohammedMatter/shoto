import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// The sheet that rises when an image is shared into SHOTO.
///
/// It runs in its own translucent Android activity, so what the user sees is
/// their current app dimmed slightly with a small panel sliding up over it —
/// the same shape as a system share sheet. Nothing about it should read as
/// "you have been moved into another app", because being thrown into the
/// full app is exactly what made sharing here not worth doing.
class QuickSavePage extends StatefulWidget {
  const QuickSavePage({super.key});

  @override
  State<QuickSavePage> createState() => _QuickSavePageState();
}

enum _Stage { loading, signedOut, ready, naming, saving, saved, failed }

class _QuickSavePageState extends State<QuickSavePage>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('shoto/share');

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.sheet,
    reverseDuration: AppMotion.normal,
  );

  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    // The one surface in the app with real distance to travel, so it gets
    // the strongest ease-out: almost all of the rise happens in the first
    // third, then it settles. That front-loading is what makes a sheet feel
    // like it was already on its way rather than starting when you looked.
    curve: AppMotion.emphasis,
    reverseCurve: AppMotion.exit,
  );

  /// Flick speed that dismisses regardless of how far the sheet was dragged.
  ///
  /// Was 700px/s, which is a hard throw — a normal downward flick sat around
  /// 300 and the sheet stubbornly sprang back. Dismissal should follow the
  /// gesture's *intent*, and 320px/s is comfortably above anything produced
  /// by scrolling or an accidental brush.
  static const double _flickVelocity = 320;

  /// Or drag it this far and let go, at any speed.
  static const double _dismissDistance = 110;

  /// Where the drag stops following the finger one-to-one.
  static const double _resistAfter = 180;

  /// Rubber-banding past [_resistAfter].
  ///
  /// Without it the sheet tracks the finger all the way to 600px and simply
  /// stops dead, which feels like the gesture broke. Resistance says "you
  /// have gone far enough for this to count" through the movement itself,
  /// so the user knows the throw has registered before they let go.
  static double _resist(double offset) {
    if (offset <= _resistAfter) return offset.clamp(0, _resistAfter);
    return _resistAfter + (offset - _resistAfter) * 0.35;
  }

  _Stage _stage = _Stage.loading;

  /// Everything this share brought in. One image is just the common case —
  /// selecting several screenshots in the gallery and sharing them all is a
  /// single trip through this sheet.
  List<_SharedImage> _images = const [];

  /// How many images Android handed over beyond what the sheet accepts, so
  /// the user is told rather than quietly given fewer than they picked.
  int _skipped = 0;

  List<FolderEntity> _folders = const [];
  FolderEntity? _selected;

  int get _alreadyInLibraryCount =>
      _images.where((image) => image.isAlreadyInLibrary).length;

  bool get _allAlreadyInLibrary =>
      _images.isNotEmpty && _alreadyInLibraryCount == _images.length;

  /// A folder is the point. Saving to the library and stopping there just
  /// makes another pile to sort later, which is the problem SHOTO exists to
  /// solve — so the button waits until somewhere has been chosen.
  bool get _inert => _selected == null;

  /// How far the user has dragged the sheet down, in logical pixels. Kept
  /// separate from the controller so a drag can be abandoned and spring back
  /// without fighting the entrance animation.
  double _dragOffset = 0;
  bool _closing = false;

  /// Completes once the sheet has finished arriving.
  ///
  /// [_load] waits on this before swapping the spinner out for the form. The
  /// work itself still starts immediately in [initState] — what is deferred is
  /// only the *rebuild*, because landing it mid-slide meant an AnimatedSize
  /// relayout and an AnimatedSwitcher crossfade running on top of a surface
  /// that was still translating. Three animations of three different kinds,
  /// on the same subtree, in the same frames.
  final Completer<void> _entered = Completer<void>();

  void _markEntered() {
    if (!_entered.isCompleted) _entered.complete();
  }

  @override
  void initState() {
    super.initState();
    // Both start now. Only the rebuild waits — see [_entered].
    _controller.forward().whenComplete(_markEntered);
    _load();
  }

  @override
  void dispose() {
    // A cancelled ticker never completes its future, so `whenComplete` above
    // would not fire and anything awaiting [_entered] would hang forever.
    _markEntered();
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<Object?, Object?>? shared = await _channel
          .invokeMethod<Map<Object?, Object?>>('getSharedImages');
      final List<Object?> raw =
          (shared?['images'] as List<Object?>?) ?? const [];
      if (raw.isEmpty) {
        if (mounted) setState(() => _stage = _Stage.failed);
        return;
      }

      // A library belongs to an account. With nobody signed in there is no
      // library to save into — the image would land in the gallery owned by
      // no one and be invisible in the app, which is worse than saying so.
      if (sl<AuthRepository>().currentUser == null) {
        if (mounted) setState(() => _stage = _Stage.signedOut);
        return;
      }

      final ScreenshotRepository repository = sl<ScreenshotRepository>();
      final List<_SharedImage> images = [];
      for (final Object? entry in raw) {
        final Map<Object?, Object?> map = entry as Map<Object?, Object?>;
        final String? path = map['path'] as String?;
        if (path == null) continue;

        // Sharing a screenshot SHOTO already shows used to write a *second*
        // copy into the gallery, so the app then listed the same picture
        // twice and the whole feature looked pointless. Resolving the
        // MediaStore id means anything already in the library is only filed.
        final String? mediaId = map['mediaId'] as String?;
        images.add(
          _SharedImage(
            path: path,
            mediaId: mediaId,
            existingAssetId: mediaId == null
                ? null
                : await repository.findLibraryAsset(mediaId),
          ),
        );
      }

      if (images.isEmpty) {
        if (mounted) setState(() => _stage = _Stage.failed);
        return;
      }

      final List<FolderEntity> folders = await sl<GetFoldersUseCase>()();

      await _entered.future;
      // `_closing` as well as `mounted`: the entrance can be released by a
      // dismissal rather than by finishing, and swapping the spinner for the
      // form on a sheet that is already sliding away is worse than the mid-
      // slide rebuild this deferral exists to prevent.
      if (!mounted || _closing) return;
      setState(() {
        _images = images;
        _skipped = (shared?['skipped'] as int?) ?? 0;
        _folders = folders;
        _stage = _Stage.ready;
      });
    } catch (_) {
      if (mounted) setState(() => _stage = _Stage.failed);
    }
  }

  Future<void> _save() async {
    final FolderEntity? folder = _selected;
    if (folder == null) return;

    // Resolved here, synchronously, before a single `await` runs.
    //
    // Both are read off `context`, and everything below is asynchronous — the
    // import, the filing, then a two-second wait during which the user can
    // drag the sheet away. Reading a MediaQuery off an element that has since
    // been unmounted is how a delay like this becomes a crash nobody can
    // reproduce.
    //
    // **The dwell is two seconds, and that is deliberate.** It went
    // 950 -> 420 -> 800 -> 2000 before landing, and the mistake in the middle
    // is worth recording: 420 came from applying the 300ms UI ceiling to it.
    // That ceiling is for motion a user is *waiting on* — a sheet opening, a
    // button answering a press. This is not that. Nothing is blocked; the
    // save is already committed and the sheet leaves on its own. It is a
    // confirmation, and a confirmation's only job is to be read.
    //
    // Read by whom, and from where, is what sets the number. This panel
    // appears over a completely different app, so the eye has to travel to it
    // before it can start reading — and the tick still needs AppMotion.normal
    // to arrive through the AnimatedSwitcher below. At 800ms it was landing
    // as a flash. Two seconds is a dwell, the length a toast sits for, and
    // nothing waits on it: every exit stays live throughout, so anyone who has
    // already read it leaves immediately.
    final Duration dwell = AppMotion.duration(
      context,
      const Duration(seconds: 2),
    );

    // The one exit in this sheet that **nobody asked for**.
    //
    // `reverseDuration` is AppMotion.normal — 220ms — because every other way
    // out of here is user-initiated: a drag, the back gesture, a tap on the
    // scrim. In all of those the user has decided and is now waiting on the
    // app, so the exit should snap. This one is the app leaving on its own
    // while the user is still reading, and 220ms across a full-height sheet
    // reads as the panel being yanked rather than withdrawing.
    final Duration exit = AppMotion.duration(context, AppMotion.sheet);

    setState(() => _stage = _Stage.saving);
    try {
      final ScreenshotRepository repository = sl<ScreenshotRepository>();

      // Import only what this account does not already have; everything else
      // is purely a filing operation on an asset that is already there.
      final List<String> assetIds = [];
      for (final _SharedImage image in _images) {
        assetIds.add(
          image.existingAssetId ??
              await repository.importSharedFile(
                image.path,
                sourceAssetId: image.mediaId,
              ),
        );
      }

      // One call for the whole batch rather than one per image — filing is
      // the single thing the user asked for, so it either happened or it
      // didn't.
      await repository.assignFolder(assetIds, folder.id);

      if (!mounted) return;
      Haptics.confirm();
      setState(() => _stage = _Stage.saved);
    } catch (error, stack) {
      // Still reported as a failed save rather than crashing the sheet — but
      // no longer swallowed. Everything that goes wrong in here used to
      // surface as "Could not read that image", which points at the file and
      // sends anyone debugging it to the wrong place.
      debugPrint('SHOTO: quick save failed — $error\n$stack');
      if (mounted) setState(() => _stage = _Stage.failed);
      return;
    }

    // Deliberately **outside** the try.
    //
    // The close used to sit inside it, which meant a failure while dismissing
    // was caught by the same handler as a failure while saving — and that
    // handler flips the sheet to `_Stage.failed`. So a screenshot that had
    // been imported and filed correctly could still report that it had not
    // been, purely because the platform channel that finishes the activity
    // threw on the way out. Telling someone their save failed when it did not
    // is worse than any close error the try was protecting against.
    await Future<void>.delayed(dwell);
    if (!mounted) return;

    // Two seconds is long enough that the user often beats it. The drag, the
    // back gesture and the scrim all route through [_close], which sets
    // `_closing` and starts the reverse. Without this guard the auto-close
    // would reach in and rewrite `reverseDuration` on a controller that is
    // already reversing, then call [_close] a second time. Neither is harmful
    // today — the controller reads its duration when the reverse begins, and
    // [_close] returns early on `_closing` — but both stop being harmless the
    // moment somebody changes one of them.
    if (_closing) return;

    _controller.reverseDuration = exit;
    await _close();
  }

  /// Plays the sheet back down before handing control to Android, so the
  /// activity never vanishes mid-animation.
  final TextEditingController _nameController = TextEditingController();
  int _newFolderColor = kFolderColors.first;

  Future<void> _createFolder() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    final FolderEntity created = await sl<CreateFolderUseCase>()(
      name,
      _newFolderColor,
    );
    if (!mounted) return;
    // Drop straight back into the save flow with the new folder already
    // chosen — making someone pick it again right after naming it would be
    // asking the same question twice.
    setState(() {
      _folders = [..._folders, created];
      _selected = created;
      _stage = _Stage.ready;
      _nameController.clear();
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    // Releases anything waiting on the entrance.
    //
    // `reverse()` below cancels the in-flight `forward()`, and a cancelled
    // Ticker's future never completes — so `whenComplete` never fires and
    // [_load] would sit on `_entered.future` until dispose happened to free
    // it. Dragging the sheet away during its own 280ms arrival is a real
    // thing to do, and "it works because the widget gets destroyed later" is
    // not a guarantee worth depending on.
    _markEntered();
    if (mounted) setState(() => _dragOffset = 0);
    await _controller.reverse();
    await _channel.invokeMethod<void>('close');
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_stage == _Stage.saving || _stage == _Stage.saved) return;
    setState(() => _dragOffset = _resist(_dragOffset + details.delta.dy));
  }

  void _onDragEnd(DragEndDetails details) {
    if (_stage == _Stage.saving || _stage == _Stage.saved) return;
    // Either a decisive flick or dragged far enough to mean it. Anything else
    // springs back, which is what makes an accidental brush feel forgiving.
    final bool dismissed =
        details.velocity.pixelsPerSecond.dy > _flickVelocity ||
        _dragOffset > _dismissDistance;
    if (dismissed) {
      _close();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        // Transparent all the way down, so the app behind stays visible.
        backgroundColor: Colors.transparent,
        // The sheet lifts itself above the keyboard (see [_Sheet]) rather than
        // letting Scaffold resize the body. Scaffold's version would shrink
        // the *scrim* too, exposing a strip of the app behind it, and this
        // activity is translucent so that strip is the user's home screen.
        resizeToAvoidBottomInset: false,
        body: AnimatedBuilder(
          animation: _rise,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55 * _rise.value),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - _rise.value),
                    child: Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          },
          // The sheet is rasterised once and then only re-composited as it
          // slides and as it is dragged. Without this the whole subtree
          // repainted on every frame of both — the same pixels at a different
          // offset, which is exactly what a repaint boundary exists to tell
          // Flutter it can skip.
          //
          // It earned its place against a full-width `BoxShadow` at
          // `blurRadius: 32` that used to sit on this panel, redrawn sixty
          // times a second for a surface that was only moving. That shadow is
          // gone now (see [AppColors]), so the saving is smaller — but the
          // panel is still the widest, deepest subtree in the app and it still
          // moves under a finger, which is the case this is for.
          child: RepaintBoundary(
            child: _Sheet(
              onDragUpdate: _onDragUpdate,
              onDragEnd: _onDragEnd,
              child: AnimatedSize(
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  switchInCurve: AppMotion.standard,
                  // Was missing, so the outgoing stage faded out on a linear
                  // curve while the incoming one eased in.
                  switchOutCurve: AppMotion.standard,
                  child: _content(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_stage) {
      case _Stage.loading:
        return Padding(
          key: const ValueKey('loading'),
          padding: EdgeInsets.symmetric(vertical: 46.h),
          child: Center(
            // A spinner repaints on every single frame, for as long as it is
            // on screen. Unboxed, that marked the entire sheet dirty sixty
            // times a second — the whole panel, for a 40-pixel spinner — so
            // widget whose job is to say "please wait" was itself the reason
            // the wait looked rough. Its own boundary keeps those repaints to
            // the 40 or so pixels that actually change.
            child: RepaintBoundary(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        );

      case _Stage.failed:
        return _Status(
          key: const ValueKey('failed'),
          icon: Icons.error_outline_rounded,
          tint: AppColors.error,
          title: context.l10n.quickSaveFailedTitle,
          subtitle: context.l10n.quickSaveFailedBody,
        );

      case _Stage.signedOut:
        return _Status(
          key: const ValueKey('signedOut'),
          icon: Icons.lock_outline_rounded,
          tint: AppColors.primary,
          title: context.l10n.quickSaveSignedOutTitle,
          subtitle: context.l10n.quickSaveSignedOutBody,
        );

      case _Stage.saved:
        return _Status(
          key: const ValueKey('saved'),
          icon: Icons.check_rounded,
          tint: AppColors.success,
          title: context.l10n.quickSaveSaved,
          subtitle: _savedSubtitle(context),
        );

      case _Stage.naming:
        return _newFolderForm();

      case _Stage.ready:
      case _Stage.saving:
        return _form();
    }
  }

  /// Naming a folder without leaving the sheet.
  ///
  /// Sending someone into the full app to make a folder and then back out to
  /// finish saving would break the one promise this sheet makes — that it
  /// does not take you anywhere.
  Widget _newFolderForm() {
    return Column(
      key: const ValueKey('naming'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PressableScale(
              scale: 0.9,
              onTap: () => setState(() => _stage = _Stage.ready),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(context.l10n.foldersNew, style: AppTextStyles.titleLarge),
          ],
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: AppTextStyles.bodyLarge,
          onSubmitted: (_) => _createFolder(),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: context.l10n.foldersNameHint,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textDisabled,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            for (final int color in kFolderColors) ...[
              PressableScale(
                scale: 0.85,
                onTap: () => setState(() => _newFolderColor = color),
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _newFolderColor == color
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 9.w),
            ],
          ],
        ),
        SizedBox(height: 20.h),
        PressableScale(
          onTap: _nameController.text.trim().isEmpty ? null : _createFolder,
          child: Container(
            height: 52.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _nameController.text.trim().isEmpty
                  ? null
                  : AppColors.primaryGradient,
              color: _nameController.text.trim().isEmpty
                  ? AppColors.surfaceVariant
                  : null,
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: Text(
              context.l10n.foldersCreate,
              style: AppTextStyles.button.copyWith(
                color: _nameController.text.trim().isEmpty
                    ? AppColors.textDisabled
                    : AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    final bool busy = _stage == _Stage.saving;

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // The preview is the confirmation that the *right* images
            // arrived, which matters more than it sounds when several apps
            // can share — and more still once a share can carry a dozen.
            _SharedPreview(images: _images),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(context), style: AppTextStyles.titleLarge),
                  SizedBox(height: 2.h),
                  Text(
                    _folders.isEmpty
                        ? context.l10n.quickSaveNeedFolder
                        : context.l10n.quickSavePickFolder,
                    style: AppTextStyles.bodySmall,
                  ),
                  if (_skipped > 0) ...[
                    SizedBox(height: 3.h),
                    Text(
                      context.l10n.quickSaveSkipped(_images.length),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_folders.isEmpty) ...[
          SizedBox(height: 18.h),
          // No folders yet. Rather than a disabled control and no explanation,
          // the sheet says what a folder is for and offers to make one here.
          PressableScale(
            scale: 0.98,
            onTap: () => setState(() => _stage = _Stage.naming),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.create_new_folder_rounded,
                    color: AppColors.primary,
                    size: 19.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.quickSaveCreateFirstFolder,
                          style: AppTextStyles.titleSmall,
                        ),
                        Text(
                          context.l10n.quickSaveCreateFirstFolderWhy,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.add_rounded,
                    color: AppColors.primary,
                    size: 19.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_folders.isNotEmpty) ...[
          SizedBox(height: 20.h),
          SizedBox(
            height: 38.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // "New" leads, then the folders. It sits first because the
              // folder you want is often the one that doesn't exist yet, and
              // at the far end of a scrolling strip it was effectively
              // hidden behind however many folders you already had.
              itemCount: _folders.length + 1,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FolderChip(
                    label: context.l10n.quickSaveNewChip,
                    icon: Icons.add_rounded,
                    selected: false,
                    onTap: () => setState(() => _stage = _Stage.naming),
                  );
                }
                final FolderEntity folder = _folders[index - 1];
                return _FolderChip(
                  label: folder.name,
                  icon: Icons.folder_rounded,
                  tint: Color(folder.color),
                  selected: _selected?.id == folder.id,
                  onTap: () => setState(() => _selected = folder),
                );
              },
            ),
          ),
        ],
        SizedBox(height: 20.h),
        PressableScale(
          // Dimmed until a folder is picked. Filing is the whole action here,
          // so a button that could run without one would be offering to do
          // nothing.
          onTap: busy || _inert ? null : _save,
          child: Container(
            height: 54.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _inert ? null : AppColors.primaryGradient,
              color: _inert ? AppColors.surfaceVariant : null,
              borderRadius: BorderRadius.circular(17.r),
            ),
            child: busy
                ? SizedBox(
                    width: 21.w,
                    height: 21.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        color: _inert
                            ? AppColors.textDisabled
                            : AppColors.onPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 9.w),
                      Text(
                        // Branches on where the screenshot is going rather
                        // than on whether the button is tappable — the two
                        // are the same thing again now that a folder is the
                        // only way to file, but writing it this way is what
                        // keeps `_selected!` provably safe.
                        _selected != null
                            ? context.l10n.quickSaveFileIn(_selected!.name)
                            : context.l10n.quickSavePickFolder,
                        style: AppTextStyles.button.copyWith(
                          color: _inert
                              ? AppColors.textDisabled
                              : AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Where it went.
  ///
  /// `_selected` is non-null by construction here: [_save] returns early
  /// without a folder, so the sheet can only reach [_Stage.saved] with one
  /// chosen.
  String _savedSubtitle(BuildContext context) =>
      context.l10n.quickSaveFiled(_selected!.name);

  /// Says how many, and whether this is an import or only a filing job.
  String _title(BuildContext context) {
    final int count = _images.length;
    if (count == 1) {
      return _allAlreadyInLibrary
          ? context.l10n.quickSaveFileOne
          : context.l10n.quickSaveTitleOne;
    }
    return _allAlreadyInLibrary
        ? context.l10n.quickSaveFileMany(count)
        : context.l10n.quickSaveTitleMany(count);
  }
}

/// One image handed over by another app, and whether SHOTO already has it.
class _SharedImage {
  final String path;

  /// The gallery id it came from, when Android gave one. Lets an image
  /// already sitting in SHOTO's album be taken into this account's library
  /// rather than copied a second time.
  final String? mediaId;

  /// Set when the *signed-in account's* library already holds this exact
  /// image, in which case there is nothing to import — only to file.
  final String? existingAssetId;

  const _SharedImage({
    required this.path,
    required this.mediaId,
    required this.existingAssetId,
  });

  bool get isAlreadyInLibrary => existingAssetId != null;
}

/// What is about to be filed: one thumbnail, or a small stack with a count.
///
/// Stacked rather than a scrolling row because this is a confirmation, not a
/// gallery — the question it answers is "did the right things arrive", and
/// three corners plus a number answers it in the same space one image took.
class _SharedPreview extends StatelessWidget {
  final List<_SharedImage> images;
  const _SharedPreview({required this.images});

  static const int _maxVisible = 3;

  @override
  Widget build(BuildContext context) {
    final int visible = images.length.clamp(0, _maxVisible);
    final int hidden = images.length - visible;

    return SizedBox(
      width: 62.w,
      height: 62.w,
      child: Stack(
        children: [
          for (int i = visible - 1; i >= 0; i--)
            Positioned(
              left: i * 4.w,
              top: i * 4.w,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13.r),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                  color: AppColors.surfaceVariant,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(File(images[i].path), fit: BoxFit.cover),
              ),
            ),
          if (hidden > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  '+$hidden',
                  style: AppTextStyles.caption.asSemiBold.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The panel itself: rounded top, drag handle, and a grab area that covers
/// the whole header so the sheet can be pulled down from anywhere near the
/// top rather than from a 4-pixel bar.
class _Sheet extends StatelessWidget {
  final Widget child;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  const _Sheet({
    required this.child,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: onDragUpdate,
      onVerticalDragEnd: onDragEnd,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            // Naming a folder opens the keyboard, and the Create button sits
            // at the very bottom of the sheet — without this it would be the
            // one control hidden behind the keyboard.
            padding: EdgeInsets.fromLTRB(
              20.w,
              10.h,
              20.w,
              18.h + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? tint;
  final bool selected;
  final VoidCallback onTap;

  const _FolderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tint ?? AppColors.primary;

    return PressableScale(
      scale: 0.94,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15.sp,
              color: selected ? accent : AppColors.textSecondary,
            ),
            SizedBox(width: 7.w),
            Text(
              label,
              style: AppTextStyles.bodySmall.asMedium.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;

  const _Status({
    super.key,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32.sp, color: tint),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge,
          ),
          SizedBox(height: 3.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
