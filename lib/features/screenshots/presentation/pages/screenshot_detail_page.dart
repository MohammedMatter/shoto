import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/confirm_dialog.dart';
import 'package:shoto/core/widgets/photo_hero.dart';
import 'package:shoto/features/folders/presentation/widgets/move_to_folder_sheet.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_full_picker_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_actions.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/smart_actions/presentation/widgets/smart_actions_sheet.dart';
import 'package:shoto/core/widgets/glass_layer.dart';

class ScreenshotDetailPage extends StatefulWidget {
  final List<ScreenshotEntity> screenshots;
  final int initialIndex;

  /// Matches the namespace the grid that opened this viewer used for its own
  /// tags, so the picture grows out of the tile that was tapped. Null for
  /// entry points with no tile to grow from.
  final String? heroPrefix;

  const ScreenshotDetailPage({
    super.key,
    required this.screenshots,
    required this.initialIndex,
    this.heroPrefix,
  });

  @override
  State<ScreenshotDetailPage> createState() => _ScreenshotDetailPageState();
}

class _ScreenshotDetailPageState extends State<ScreenshotDetailPage> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  /// Tapping the image hides the chrome so the screenshot can be looked at
  /// on its own — the same gesture every photo viewer on both platforms
  /// uses, and the reason people can read fine print in a screenshot at all.
  bool _chromeVisible = true;

  /// Whether the opening flight has finished.
  ///
  /// **Nothing but the picture is allowed to happen while it is false**, and
  /// that single rule is what this screen was missing.
  ///
  /// Opening a screenshot used to start three expensive things on the very
  /// frame the route was pushed: reading the full-resolution file off disk,
  /// decoding it (a screenshot is captured at the device's own resolution, so
  /// this is the largest image the phone can produce), and building three
  /// frosted `BackdropFilter` panels — the most expensive widget Flutter has,
  /// blurring a full-screen photo on every one of the ~17 frames the flight
  /// lasts. All of it landed on the exact 280ms the user was watching a
  /// picture move, and the flight paid for it in dropped frames.
  ///
  /// None of it is urgent. The picture is already on screen as a cached
  /// thumbnail, and the toolbar is worth nothing until there is something to
  /// use it on. So the flight gets the frame budget to itself, and everything
  /// else arrives once it has landed.
  bool _settled = false;
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    // Post-frame because ModalRoute.of needs this element to be mounted, and
    // because reading an inherited widget in initState is forbidden.
    WidgetsBinding.instance.addPostFrameCallback(_watchArrival);
  }

  void _watchArrival(Duration _) {
    if (!mounted) return;
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _settle();
      return;
    }
    _routeAnimation = animation..addStatusListener(_onRouteStatus);
    // A picture that never sharpens is a far worse failure than one that
    // sharpens a fraction early, so the status listener has a floor under it
    // for any entry point whose animation never reports completion.
    Future<void>.delayed(
      AppMotion.sheet + const Duration(milliseconds: 120),
      _settle,
    );
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _settle();
  }

  void _settle() {
    if (!mounted || _settled) return;
    setState(() => _settled = true);
  }

  /// Shows or hides the toolbar, **and the phone's own bars with it**.
  ///
  /// The status bar is the one piece of chrome on this screen the app does not
  /// draw and cannot restyle per picture. Its icons are white here, which is
  /// correct over the black page and over most screenshots — and invisible over
  /// a white one, so opening a receipt or an article left the clock and the
  /// battery as white-on-white smudges.
  ///
  /// Two answers, and this screen needs both because they cover different
  /// moments. While the toolbar is up, [_TopBar] paints a scrim behind it that
  /// the status bar sits on. While it is down, there is nothing to put a scrim
  /// under — so the bars go away entirely, which is what the tap asked for in
  /// the first place: the picture, by itself, on the whole screen.
  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    _applySystemBars();
  }

  void _applySystemBars() {
    SystemChrome.setEnabledSystemUIMode(
      // Sticky rather than plain immersive: a swipe from the edge brings the
      // bars back for a moment and then lets them go again, instead of
      // permanently undoing a mode the user never sees a control for.
      _chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    // Global state, so it is restored on the way out no matter how the screen
    // was left — popped, swiped back, or replaced. Leaving it immersive would
    // hand the rest of the app a phone with no status bar.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _pageController.dispose();
    super.dispose();
  }

  /// Opens Safe Share with **no premium check**.
  ///
  /// The gate moved inside the screen, onto the "clean this screenshot"
  /// button. Scanning is free and unlimited on purpose: telling somebody
  /// their screenshot holds their address and their card number is worth
  /// knowing whether or not they ever pay, and charging to *find out there is
  /// a problem* is how a scanner stops being believed. The two entry points
  /// also disagreed — the library toolbar never checked at all — so this is
  /// one behaviour now instead of two.
  Future<void> _safeShare(BuildContext context, ScreenshotEntity item) async {
    await Navigator.of(
      context,
    ).push(FadeSlidePageRoute(builder: (_) => SafeSharePage(screenshot: item)));
  }

  Future<void> _delete(BuildContext context, ScreenshotEntity item) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final bool confirmed = await confirmDeletion(
      context,
      title: context.l10n.detailDeleteTitle,
      message: context.l10n.detailDeleteMessage,
    );
    if (confirmed) bloc.add(DeleteScreenshotEvent(item.id));
  }

  Future<void> _move(BuildContext context, ScreenshotEntity item) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final bool alreadyManaged = item.isFavorite || item.folderId != null;
    final bool allowed = await ensureUnderScreenshotLimit(
      context,
      additionalNewItems: alreadyManaged ? 0 : 1,
    );
    if (!allowed || !context.mounted) return;
    showMoveToFolderSheet(
      context,
      currentFolderId: item.folderId,
      onSelected: (folderId) =>
          bloc.add(MoveScreenshotToFolderEvent(item.id, folderId)),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    ScreenshotEntity item,
  ) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final bool alreadyManaged = item.isFavorite || item.folderId != null;
    final bool allowed = await ensureUnderScreenshotLimit(
      context,
      additionalNewItems: alreadyManaged ? 0 : 1,
    );
    if (!allowed) return;
    bloc.add(ToggleFavoriteEvent(item.id));
  }

  /// Resolves what this viewer should show.
  ///
  /// The **caller** decides which screenshots are in scope and in what order
  /// — a smart album, a folder, search results, the whole library. This used
  /// to throw that away and page through the bloc's full library instead,
  /// while still using the caller's index: opening the third item of an
  /// album showed the third item of the *entire library*, a completely
  /// unrelated picture.
  ///
  /// The bloc is still consulted, but only to look each screenshot up **by
  /// id** so live changes (favorited, moved, deleted elsewhere) show through.
  /// Anything the bloc no longer knows about has been deleted and drops out.
  List<ScreenshotEntity> _resolve(ScreenshotsState state) {
    if (state is! ScreenshotsLoadedState) return widget.screenshots;

    final Map<String, ScreenshotEntity> byId = {
      for (final ScreenshotEntity item in state.screenshots) item.id: item,
    };

    return [
      for (final ScreenshotEntity item in widget.screenshots)
        if (byId[item.id] != null) byId[item.id]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScreenshotsBloc, ScreenshotsState>(
      listener: (context, state) {
        // Everything this viewer was opened with is gone — there is nothing
        // left to look at.
        if (_resolve(state).isEmpty) Navigator.of(context).pop();
      },
      builder: (context, state) {
        final List<ScreenshotEntity> items = _resolve(state);
        if (items.isEmpty) return const SizedBox.shrink();

        final int safeIndex = _currentIndex.clamp(0, items.length - 1);
        final ScreenshotEntity current = items[safeIndex];

        return AnnotatedRegion<SystemUiOverlayStyle>(
          // The page is black in both themes, so the phone's own bars have to
          // be told. In light mode they were still styled for paper: dark
          // status icons that vanished against the black, and a bright system
          // navigation bar drawing a hard white band under the picture — the
          // single most eye-catching thing on a screen whose entire content is
          // one screenshot. The app's root region takes over again on close.
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
            // Always black, in both themes. A screenshot is the subject here,
            // and any tinted surround shifts how its colours read.
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: _toggleChrome,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: _Photo(
                            item: items[index],
                            // Only the page being looked at flies. A PageView
                            // keeps its neighbours built, and every one of them
                            // has a tag the grid also holds — leaving them
                            // tagged means three shared-element flights racing
                            // each other across the screen on a single tap.
                            heroTag:
                                index == safeIndex && widget.heroPrefix != null
                                ? '${widget.heroPrefix}-${items[index].id}'
                                : null,
                            full: _settled && index == safeIndex,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Built only once the picture has landed — see [_settled]. Until
                // then these are three full-screen blurs the flight would be
                // paying for and nobody would be using.
                if (_settled) ...[
                  _Chrome(
                    visible: _chromeVisible,
                    alignment: Alignment.topCenter,
                    child: _TopBar(
                      position: safeIndex + 1,
                      total: items.length,
                    ),
                  ),
                  _Chrome(
                    visible: _chromeVisible,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Above the verbs, not among them. Everything in the
                        // bar below *does* something to the screenshot right
                        // now; this states what the user means to do about it
                        // later, and a seventh icon in that row would read as
                        // a seventh thing to trigger — the same reason it sits
                        // above the actions in the quick-actions sheet.
                        _IntentBar(item: current),
                        _ActionBar(
                          item: current,
                          onFavorite: () => _toggleFavorite(context, current),
                          onActions: () =>
                              showSmartActionsSheet(context, current),
                          onSafeShare: () => _safeShare(context, current),
                          onShare: () => shareScreenshot(current),
                          onMove: () => _move(context, current),
                          onDelete: () => _delete(context, current),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The screenshot itself, and the other half of the shared-element flight.
///
/// Two things had to be true for the flight to look like one picture growing
/// rather than two pictures swapping.
///
/// **It is sized by aspect ratio, not by `BoxFit.contain`.** The grid tile is
/// a square filled with a cropped thumbnail. If this side were a full-screen
/// box with the image contained inside it, the flight would interpolate a
/// square into a full screen while the picture inside it changed crop
/// halfway, and the eye reads that as a glitch. Sizing the hero box to the
/// picture's own proportions means the box that lands is exactly the picture,
/// both ends draw with the same fit, and the transition is a single rectangle
/// growing and un-cropping itself.
///
/// **The cached thumbnail is underneath.** The full-resolution file is read
/// off disk asynchronously, and it is never ready during the ~280ms the
/// flight lasts. This used to show a spinner there, which meant the default
/// flight would have carried a loading indicator across the screen. The
/// thumbnail is already decoded and in Flutter's image cache from the grid,
/// so it paints on the first frame and the full-size image cross-fades in on
/// top once it arrives — the user never sees the handover.
///
/// **And it does not even start until [full].** The read and the decode are
/// the heaviest work this screen does; letting them begin on the frame the
/// route was pushed put them squarely on top of the opening flight. They now
/// wait for it to finish, which costs a fraction of a second of softness on a
/// picture the user has only just begun looking at, and buys every frame of
/// the movement they are actually watching.
class _Photo extends StatefulWidget {
  final ScreenshotEntity item;
  final Object? heroTag;

  /// Whether this page may load the full-resolution image yet.
  final bool full;

  const _Photo({required this.item, required this.full, this.heroTag});

  @override
  State<_Photo> createState() => _PhotoState();
}

class _PhotoState extends State<_Photo> {
  /// Held in state rather than created inside `build`.
  ///
  /// `asset.file` hands back a **new** future every call, and this page
  /// rebuilds on every tap (hiding and showing the chrome). Built inline, each
  /// of those taps restarted the disk read and dropped the FutureBuilder back
  /// to no-data — the full-resolution image would blink away and return for
  /// no reason connected to what the user did. This is the same trap
  /// [AssetThumbnailImage] was written to close for the grid.
  ///
  /// Null until this page is allowed to load it at all.
  late Future<File?>? _file = widget.full ? widget.item.asset.file : null;

  @override
  void didUpdateWidget(_Photo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A PageView recycles its pages, so the same State can be handed a
    // different screenshot. Only then is a new read actually warranted.
    if (oldWidget.item.id != widget.item.id) {
      _file = widget.full ? widget.item.asset.file : null;
    } else if (widget.full && _file == null) {
      // Started once and then kept, deliberately: a page loses `full` as soon
      // as the user swipes past it, and dropping the image there would blur
      // the picture they are still looking at on its way off screen.
      _file = widget.item.asset.file;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guarded: a few assets report zero dimensions, and an AspectRatio of
    // NaN takes the whole frame down.
    final int w = widget.item.asset.width;
    final int h = widget.item.asset.height;
    final double aspect = (w > 0 && h > 0) ? w / h : 1;

    final Widget picture = AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AssetThumbnailImage(
            asset: widget.item.asset,
            background: Colors.black,
          ),
          FutureBuilder<File?>(
            future: _file,
            builder: (context, snapshot) {
              final File? file = snapshot.data;
              return AnimatedOpacity(
                opacity: file == null ? 0 : 1,
                // Longer than a press: this is a soft picture becoming a sharp
                // one under a gaze that is already resting on it, and the
                // faster it is done the more it reads as a snap.
                duration: AppMotion.duration(context, AppMotion.normal),
                curve: AppMotion.standard,
                child: file == null
                    ? const SizedBox.expand()
                    // cover, not contain — the box is already the picture's
                    // shape, so the two are identical here, and cover is what
                    // the grid side draws.
                    : Image.file(file, fit: BoxFit.cover),
              );
            },
          ),
        ],
      ),
    );

    final Object? tag = widget.heroTag;
    return tag == null
        ? picture
        // Radius zero: full screen, no corners. The grid tile it flies from
        // declares its own, and the flight opens the corner out between them.
        : PhotoHero(tag: tag, child: picture);
  }
}

/// Fades and slides the overlays out of the way together, so hiding the
/// chrome reads as one movement rather than several things leaving at once.
///
/// It also animates the *first* time it is built. The viewer withholds the
/// chrome entirely until the opening flight has landed, and a widget that was
/// not in the tree a frame ago starts at its target value — so without this it
/// would appear fully formed, in one frame, which is precisely the jolt the
/// delay was meant to avoid. Starting hidden and flipping after the first
/// frame gives the same fade and slide the toggle already uses.
class _Chrome extends StatefulWidget {
  final bool visible;
  final Alignment alignment;
  final Widget child;

  const _Chrome({
    required this.visible,
    required this.alignment,
    required this.child,
  });

  @override
  State<_Chrome> createState() => _ChromeState();
}

class _ChromeState extends State<_Chrome> {
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _arrived = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool visible = widget.visible && _arrived;
    final bool fromTop = widget.alignment == Alignment.topCenter;
    return Align(
      alignment: widget.alignment,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(0, fromTop ? -0.4 : 0.4),
          duration: AppMotion.duration(context, AppMotion.normal),
          curve: AppMotion.standard,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: AppMotion.duration(context, AppMotion.normal),
            curve: AppMotion.standard,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int position;
  final int total;

  const _TopBar({required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // The status bar's own icons are painted by the system, over whatever is
      // behind them, in one fixed colour. This is the only thing that can make
      // them legible on a white screenshot: something dark underneath.
      //
      // It reaches above the SafeArea on purpose — the whole point is to cover
      // the strip the clock and the battery live in, which is the part
      // [SafeArea] exists to stay out of. Fading to nothing by the bottom, so it
      // reads as the picture darkening under the controls rather than as a bar
      // with an edge.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.overlay.withValues(alpha: 0.55),
            AppColors.overlay.withValues(alpha: 0.28),
            AppColors.overlay.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 14.h),
          child: Row(
            children: [
              _GlassCircle(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              GlassLayer(
                radius: 999,
                sigma: AppBlur.bar,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: _ChromePalette.circleFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _ChromePalette.rim),
                  ),
                  child: Text(
                    context.l10n.countPosition(position, total),
                    style: AppTextStyles.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              // Balances the row so the counter sits truly centred rather than
              // pushed off-axis by the single button on the left.
              Opacity(
                opacity: 0,
                child: IgnorePointer(
                  child: _GlassCircle(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {},
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

/// A floating frosted bar rather than a solid strip across the bottom.
///
/// Over a photo, an opaque toolbar cuts the image off at a hard line; glass
/// keeps the screenshot readable right to the edge of the screen while the
/// controls stay legible over whatever is behind them. Same material as the
/// tab bar, so the app feels like one piece.
/// What this screenshot is for, on the screen where you are actually looking
/// at it.
///
/// **This viewer used to be the one surface that could not answer the
/// question**, which was exactly backwards: the grid shows you a wall of
/// thumbnails, and this shows you the thing itself, full size, which is when a
/// person can tell whether the receipt still needs paying.
///
/// It opens the full picker directly rather than carrying the five-chip row.
/// A row of chips over somebody's photograph is chrome competing with the
/// picture, and this surface is the one place the picture wins every argument.
class _IntentBar extends StatelessWidget {
  final ScreenshotEntity item;

  const _IntentBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final IntentState? state = item.intent;
    final bool isDone = state?.isDone ?? false;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Row(
        children: <Widget>[
          Flexible(
            child: GlassLayer(
              radius: 20.r,
              sigma: AppBlur.panel,
              child: PressableScale(
                scale: 0.97,
                onTap: () => _pick(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    gradient: _ChromePalette.barFill,
                    border: Border.all(color: _ChromePalette.rim),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        state?.ref.icon ?? Icons.add_rounded,
                        size: 16.sp,
                        color: Colors.white.withValues(
                          alpha: isDone ? 0.55 : 0.95,
                        ),
                      ),
                      SizedBox(width: 9.w),
                      Flexible(
                        child: Text(
                          // With nothing set, the prompt itself is the label —
                          // the control has to say what it is for before it
                          // has anything to report.
                          state?.ref.label(context) ?? context.l10n.intentPrompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.asMedium.copyWith(
                            color: Colors.white.withValues(
                              alpha: isDone ? 0.55 : 0.95,
                            ),
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.white.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // The tick is a separate target from the label, because they are
          // opposite actions: one changes what you owe, the other says you
          // have paid it. Merged into one pill, every attempt to correct a
          // mistaken verb would risk marking it finished instead.
          if (state != null) ...<Widget>[
            SizedBox(width: 8.w),
            _GlassCircle(
              icon: isDone
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              // Filled, not merely tinted — the same green the badge on the
              // thumbnail turns and the same green the sheet's button fills
              // with, so finishing something looks like one event no matter
              // which of the three surfaces you happened to be on.
              fill: isDone ? AppColors.success : null,
              tint: Colors.white,
              onTap: () {
                Haptics.confirm();
                context.read<ScreenshotsBloc>().add(
                  SetIntentDoneEvent(item.id, !isDone),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final IntentPickerResult? result = await showIntentFullPickerSheet(
      context,
      selected: item.intent?.ref,
    );
    if (result == null) return;
    bloc.add(SetIntentEvent(item.id, result.intent));
  }
}

class _ActionBar extends StatelessWidget {
  final ScreenshotEntity item;
  final VoidCallback onFavorite;
  final VoidCallback onActions;
  final VoidCallback onSafeShare;
  final VoidCallback onShare;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const _ActionBar({
    required this.item,
    required this.onFavorite,
    required this.onActions,
    required this.onSafeShare,
    required this.onShare,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        bottomInset > 0 ? bottomInset + 6.h : 18.h,
      ),
      child: GlassLayer(
        radius: 26.r,
        sigma: AppBlur.panel,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.r),
            gradient: _ChromePalette.barFill,
            border: Border.all(color: _ChromePalette.rim),
          ),
          child: Row(
            children: [
              Expanded(
                child: _BarAction(
                  icon: item.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  // The one coloured icon in the row: it is the only action
                  // here that has an on/off state to communicate.
                  tint: item.isFavorite ? AppColors.error : Colors.white,
                  label: context.l10n.detailFavorite,
                  onTap: onFavorite,
                  // Favouriting changes an outline into a filled shape and
                  // moves nothing else on screen, which at a glance is easy
                  // to miss. The pop is the confirmation.
                  pop: item.isFavorite,
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.auto_fix_high_rounded,
                  label: context.l10n.detailActions,
                  onTap: onActions,
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.shield_moon_rounded,
                  label: context.l10n.detailSafeShare,
                  onTap: onSafeShare,
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.ios_share_rounded,
                  label: context.l10n.commonShare,
                  onTap: onShare,
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.folder_open_rounded,
                  label: context.l10n.libraryActionMove,
                  onTap: onMove,
                ),
              ),
              Expanded(
                child: _BarAction(
                  icon: Icons.delete_outline_rounded,
                  label: context.l10n.commonDelete,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  /// A value whose change should make the icon pop once. Null for the
  /// stateless actions in this bar, which have nothing to report.
  final Object? pop;

  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = Colors.white,
    this.pop,
  });

  @override
  Widget build(BuildContext context) {
    final Widget glyph = Icon(icon, color: tint, size: 21.sp);

    return PressableScale(
      scale: 0.88,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pop == null) glyph else ValuePop(value: pop, child: glyph),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9.5.sp,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chrome that floats over somebody else's picture.
///
/// Every control on this screen sits on top of a screenshot SHOTO did not
/// choose and cannot predict, and all three of them used to be **white glass**:
/// a white fill at 14%, a white hairline, white glyphs. Over a dark screenshot
/// that is a beautiful pane of frosted glass. Over a white one — a receipt, a
/// document, an article, which is most of what anybody screenshots — it is
/// white on white, and the entire toolbar disappears. Not dimmed: gone.
///
/// The rule this replaces it with is the one every photo viewer converges on,
/// because there is only one answer: **chrome over unknown content is dark with
/// light glyphs.** A light material can only work over dark content, so it fails
/// half the time by construction. A dark one works over both — white glyphs keep
/// their contrast against a dark fill no matter what is behind it.
///
/// The alphas are set by the worst case rather than the pretty one. Against pure
/// white, [barFill] composites to roughly `#565656`, which carries white 9pt
/// labels at about 5:1; the lighter [circleFill] is for glyphs only, where the
/// threshold is lower and the shape does more of the work. Both are still
/// translucent and still blurred — the picture moves underneath them, which is
/// what keeps them reading as glass rather than as a black bar bolted on.
abstract class _ChromePalette {
  _ChromePalette._();

  /// The action bar: the piece carrying small text, so the most opaque.
  static LinearGradient get barFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.overlay.withValues(alpha: 0.7),
      AppColors.overlay.withValues(alpha: 0.78),
    ],
  );

  /// The back button and the counter — icons and one short line.
  static Color get circleFill => AppColors.overlay.withValues(alpha: 0.66);

  /// The lit edge. Unchanged from the old white glass, and it still earns its
  /// place: over a dark screenshot the fill alone has no boundary, and this is
  /// what gives the control an edge to be seen by.
  static Color get rim => Colors.white.withValues(alpha: 0.18);
}

class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// White everywhere except on the intent tick, which is the one control in
  /// this chrome with a state worth colouring — see `IntentVisuals.tint`.
  final Color? tint;

  /// Replaces the glass fill, for the same one exception.
  final Color? fill;

  const _GlassCircle({
    required this.icon,
    required this.onTap,
    this.tint,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      onTap: onTap,
      child: GlassLayer(
        radius: 999,
        sigma: AppBlur.bar,
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppMotion.normal),
          curve: AppMotion.standard,
          width: 40.w,
          height: 40.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill ?? _ChromePalette.circleFill,
            border: Border.all(
              color: fill == null ? _ChromePalette.rim : Colors.transparent,
            ),
          ),
          child: AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.normal),
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder:
                (Widget child, Animation<double> animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.6, end: 1).animate(animation),
                    child: child,
                  ),
                ),
            child: Icon(
              icon,
              key: ValueKey<IconData>(icon),
              color: tint ?? Colors.white,
              size: 16.sp,
            ),
          ),
        ),
      ),
    );
  }
}
