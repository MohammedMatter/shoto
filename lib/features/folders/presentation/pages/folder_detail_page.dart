import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_event.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_actions_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_mark.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/browsing_only.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_body.dart';

class FolderDetailPage extends StatefulWidget {
  final FolderEntity folder;
  const FolderDetailPage({super.key, required this.folder});

  @override
  State<FolderDetailPage> createState() => _FolderDetailPageState();
}

class _FolderDetailPageState extends State<FolderDetailPage> {
  late bool _unlocked = !widget.folder.isPrivate;
  bool _authenticating = false;

  /// Held in state rather than read straight off the widget so an edit made
  /// from this page updates the header immediately instead of showing the
  /// stale name until you navigate away and back.
  late FolderEntity _folder = widget.folder;

  /// The grid this page was opened from.
  ///
  /// Captured rather than looked up where it is used, because the listener
  /// below fires from inside a `BlocProvider` that owns a *different* bloc of
  /// its own — reading `FoldersBloc` from that context works, but reading it
  /// once here says plainly that this is the grid's bloc, handed over by the
  /// page that pushed this route, and not something this page created.
  late final FoldersBloc _foldersBloc = context.read<FoldersBloc>();

  /// Only used to pick the glyph on the Unlock button, so the fingerprint
  /// default is safe: it is what the button showed unconditionally before,
  /// and it is replaced the moment the device reports a face instead.
  BiometricKind _lockKind = BiometricKind.fingerprint;

  @override
  void initState() {
    super.initState();
    if (widget.folder.isPrivate) _loadLockKind();
  }

  Future<void> _loadLockKind() async {
    final BiometricKind kind = await sl<BiometricAuthService>().enrolledKind();
    if (!mounted) return;
    setState(() => _lockKind = kind);
  }

  /// A fingerprint glyph on a phone that unlocks by face is a small lie about
  /// what the next tap will ask for, so the face-only case gets its own.
  /// Everything else keeps the fingerprint: it is the one gesture the button
  /// can promise when both are enrolled, and the honest fallback when Android
  /// declines to name the modality at all.
  IconData get _unlockIcon => _lockKind == BiometricKind.face
      ? Icons.face_rounded
      : Icons.fingerprint_rounded;

  void _showActions() {
    showFolderActionsSheet(
      context,
      folder: _folder,
      bloc: context.read<FoldersBloc>(),
      onRenamed: (name) =>
          setState(() => _folder = _folder.copyWith(name: name)),
      // The folder this page exists to show is gone — there's nothing left
      // to display, so step back to the grid.
      onDeleted: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _authenticate() async {
    setState(() => _authenticating = true);
    final bool success = await sl<BiometricAuthService>().authenticate(
      reason: context.l10n.folderLockedTitle(widget.folder.name),
    );
    if (!mounted) return;
    setState(() {
      _authenticating = false;
      _unlocked = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) return _locked(context);

    final FolderEntity folder = _folder;
    return BlocProvider(
      create: (_) =>
          sl<ScreenshotsBloc>()..add(LoadScreenshotsEvent(folderId: folder.id)),
      // **The number on the tile behind this page has to follow what happens
      // on it.**
      //
      // `ScreenshotsBloc` is registered as a *factory*, so this page runs its
      // own instance: moving screenshots out of this folder, or deleting them,
      // is invisible to the shell's bloc and to the folders grid underneath.
      // The grid reloads when the Folders tab is selected and when the app
      // resumes, and neither of those happens on the way back from here — so
      // the folder you had just emptied went on saying "24 screenshots" until
      // something unrelated happened to refresh it.
      //
      // Watched by count rather than fired on the way out: the grid behind is
      // already correct by the time the pop begins, so nothing re-numbers
      // itself mid-animation, and a visit that only browsed — or that
      // favourited something, which changes no count — costs nothing.
      //
      // Length is the whole test, and it is enough: moving a screenshot to
      // another folder takes it out of *this* list too (the bloc re-filters on
      // its own folder id), and the reload re-counts every folder rather than
      // this one, so the folder it landed in is right as well.
      child: BlocListener<ScreenshotsBloc, ScreenshotsState>(
        listenWhen: (ScreenshotsState previous, ScreenshotsState current) =>
            previous is ScreenshotsLoadedState &&
            current is ScreenshotsLoadedState &&
            previous.screenshots.length != current.screenshots.length,
        listener: (BuildContext context, ScreenshotsState state) =>
            _foldersBloc.add(LoadFoldersEvent()),
        child: Scaffold(
          backgroundColor: context.colors.background,
          body: ScreenshotsBody(
            emptyTitle: context.l10n.folderEmptyTitle,
            emptyMessage: context.l10n.folderEmptyMessage,
            showFavoritesFilter: false,
            // Its own namespace even though this is its own route:
            // the library grid below it is showing the same
            // screenshots, and relying on route boundaries to keep two
            // identical tags apart is a trap for whoever changes how
            // this screen is presented later.
            heroPrefix: 'folder',
            // **The header goes inside the scroll view.**
            //
            // It was a `Column`: a fixed strip above a grid, on screen at every
            // scroll position for the whole length of the folder. That is the
            // exact arrangement `ScreenshotsBody.leadingSlivers` was added to
            // replace — its own doc says a header passed here "collapses with
            // the list instead of standing on top of it forever" — and this page
            // was the one caller still doing it the old way.
            leadingSlivers: <Widget>[
              _FolderHeader(folder: folder, onMore: _showActions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 48.sp,
                color: context.colors.textSecondary,
              ),
              SizedBox(height: 16.h),
              Text(
                widget.folder.name,
                style: context.text.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                context.l10n.folderLockedMessage,
                style: context.text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              PrimaryButton(
                label: context.l10n.commonUnlock,
                icon: _unlockIcon,
                isLoading: _authenticating,
                onPressed: _authenticate,
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.l10n.commonCancel,
                  style: context.text.button.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The folder's own header: who this is, and the two things you can do to it.
///
/// **Two states of one header, not two headers.** Expanded it is the folder
/// badge, the name at headline size and the count under it — the same three
/// facts the card on the grid carries, so arriving here reads as the tile
/// opening rather than as a new screen loading. Collapsed it is a 56dp bar
/// with the badge and the name in it, because a folder of two hundred
/// screenshots is scrolled a long way from its title and "which folder am I
/// in" has to stay answerable.
///
/// The cross-fade between them is driven from [FlexibleSpaceBarSettings]
/// rather than by a `FlexibleSpaceBar`. The stock bar scales one title between
/// two sizes, which cannot express this: the count belongs to the expanded
/// state and must be *gone* — not shrunk — by the time the bar is 56dp tall,
/// and the badge has to hold its size through the whole travel rather than
/// growing with the type.
class _FolderHeader extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onMore;

  const _FolderHeader({required this.folder, required this.onMore});

  static double get _expandedHeight => 118.h;

  /// Whether there is anything in this folder to pick.
  ///
  /// An empty folder still draws its header, and a Select button over an
  /// empty state opens a mode that cannot be satisfied.
  static bool _hasItems(ScreenshotsState state) =>
      state is ScreenshotsLoadedState && state.visibleScreenshots.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      // Pinned, so back and the folder's own actions stay reachable at any
      // depth. Same call the library's header makes, and for the same reason.
      pinned: true,
      backgroundColor: context.colors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: _expandedHeight,
      collapsedHeight: 56.h,
      toolbarHeight: 56.h,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final FlexibleSpaceBarSettings? settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();

          // 0 fully expanded, 1 fully collapsed. Null settings would mean this
          // is being built outside a sliver app bar, which is not a case the
          // page has — treating it as expanded is the harmless reading.
          final double range = settings == null
              ? 0
              : settings.maxExtent - settings.minExtent;
          final double t = settings == null || range <= 0
              ? 0
              : ((settings.maxExtent - settings.currentExtent) / range).clamp(
                  0.0,
                  1.0,
                );

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // The expanded block, anchored to the bottom so it slides up
              // under the toolbar rather than being squashed against it.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Opacity(
                  // Gone by the time the bar is two thirds closed, so the two
                  // states are never both half-legible on top of each other.
                  opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      20.w,
                      0,
                      20.w,
                      12.h,
                    ),
                    child: _Identity(folder: folder, isCompact: false),
                  ),
                ),
              ),
              // The toolbar row, which never moves.
              //
              // Offset by the status bar by hand. A `FlexibleSpaceBar` would
              // have done it; a bare widget in `flexibleSpace` is handed the
              // *whole* bar including the inset, so pinning to `top: 0` here
              // puts the back button behind the clock.
              Positioned(
                top: MediaQuery.paddingOf(context).top,
                left: 0,
                right: 0,
                height: 56.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: <Widget>[
                      // **`maybePop`, not `pop`.** `ScreenshotsBody` puts a
                      // `PopScope` around the grid so the system back gesture
                      // leaves selection mode before it leaves the screen —
                      // and only `maybePop` consults it. With a bare `pop`
                      // this button would close the folder out from under a
                      // live selection while the gesture two inches below it
                      // did something else entirely.
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: context.l10n.commonBack,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Opacity(
                          // The mirror of the block below: it arrives only
                          // once that has left, so the handover reads as one
                          // label moving rather than two crossing.
                          opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                          child: _Identity(folder: folder, isCompact: true),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Rename, lock, delete — none of them a thing to offer
                      // somebody halfway through picking screenshots *inside*
                      // this folder, and one of them would take the folder
                      // out from under them. The header itself stays put; only
                      // this goes. See [BrowsingOnly].
                      //
                      // Select stands down with them for the plainer reason
                      // that it is the door into the mode you are already in.
                      BrowsingOnly(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // The same button in the same corner as the
                            // Library's, because a folder is a grid of
                            // screenshots too and the long-press that used to
                            // start a selection here now opens one
                            // screenshot's own actions instead. Two grids that
                            // answered the same gesture differently would be
                            // the worse half of this change.
                            BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                              buildWhen:
                                  (
                                    ScreenshotsState previous,
                                    ScreenshotsState current,
                                  ) => _hasItems(previous) != _hasItems(current),
                              builder:
                                  (
                                    BuildContext context,
                                    ScreenshotsState state,
                                  ) => !_hasItems(state)
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        end: 8.w,
                                      ),
                                      child: HeaderIconButton(
                                        icon: Icons.checklist_rounded,
                                        tooltip: context.l10n.librarySelect,
                                        onTap: () =>
                                            context.read<ScreenshotsBloc>().add(
                                              EnterSelectionModeEvent(),
                                            ),
                                      ),
                                    ),
                            ),
                            HeaderIconButton(
                              icon: Icons.more_horiz_rounded,
                              tooltip: context.l10n.foldersOptions,
                              onTap: onMore,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The badge, the name and — expanded only — the count.
class _Identity extends StatelessWidget {
  final FolderEntity folder;
  final bool isCompact;

  const _Identity({required this.folder, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        FolderMark(folder: folder, size: isCompact ? 28.w : 38.w),
        SizedBox(width: isCompact ? 10.w : 12.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                folder.name,
                style: isCompact
                    ? context.text.titleLarge
                    : context.text.headlineMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // **Only on the expanded header**, and only there because it is
              // the one place on this screen that states it. The library says
              // its own total on a filter chip; this page has no chips — it is
              // one folder, unfiltered — so without this the count the user
              // was just reading on the tile disappears the moment they open
              // it.
              //
              // Read live from the grid's own bloc rather than from the folder
              // entity, which was counted when the grid loaded and is stale the
              // moment anything here is deleted or moved out.
              if (!isCompact)
                BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                  builder: (BuildContext context, ScreenshotsState state) {
                    final int count = state is ScreenshotsLoadedState
                        ? state.screenshots.length
                        : folder.screenshotCount;
                    return Text(
                      context.l10n.countScreenshots(count),
                      style: context.text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
