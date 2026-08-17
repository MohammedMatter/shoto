import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
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
import 'package:shoto/features/screenshots/presentation/widgets/photo_chrome.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_actions.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_limit_gate.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_text_layer.dart';
import 'package:shoto/features/screenshots/presentation/widgets/text_selection_bar.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/smart_actions/presentation/widgets/action_options.dart';
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

  /// The recognised text of the screenshot being looked at, once there is a
  /// reason to have read it. Null while a page is settling or being swiped
  /// past — see [_syncText].
  ScreenshotTextController? _text;

  /// Which screenshot [_text] belongs to, so a swipe cannot leave one
  /// picture's words highlighted over another's.
  String? _textFor;
  Timer? _textDebounce;

  /// Where the finger is while a selection handle is being dragged, in global
  /// coordinates. Null when nothing is being dragged.
  Offset? _magnifier;

  /// Whether the one-time "press and hold" hint is on screen.
  bool _hintVisible = false;
  Timer? _hintTimer;

  /// The screenshot currently on screen, recorded during build so the things
  /// that happen outside a build — a page settling, a debounce firing — know
  /// what they are about.
  ScreenshotEntity? _currentItem;

  bool get _selecting => _text?.hasSelection ?? false;

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

    // Cleared first, because the picture on screen is already this screen's
    // current one: [_syncText] does nothing for a screenshot it is *already*
    // pointed at, and the pointer was set — and the reading skipped — by the
    // call that ran before the flight had landed.
    final ScreenshotEntity? item = _currentItem;
    if (item == null) return;
    _textFor = null;
    _syncText(item);
  }

  /// Points [_text] at [item], reading it shortly after the swiping stops.
  ///
  /// **The delay is the whole of the performance story.** Reading a screenshot
  /// costs a decode and an ML Kit pass on the largest image the phone
  /// produces, and a thumb flicking through forty pictures would otherwise
  /// order forty of them — for a feature none of those forty were opened for.
  /// Waiting for the swiping to stop means the work only happens on the
  /// picture somebody is actually looking at, and by the time their finger
  /// gets to a long press it is usually already done.
  ///
  /// It waits for [_settled] for the same reason everything else on this
  /// screen does: nothing but the picture is allowed to happen while the
  /// opening flight is in the air.
  void _syncText(ScreenshotEntity item) {
    if (_textFor == item.id) return;

    _textDebounce?.cancel();
    _text?.removeListener(_onTextChanged);
    _text?.dispose();
    _text = null;
    _textFor = item.id;
    _magnifier = null;
    setState(() {});

    if (!_settled) return;

    _textDebounce = Timer(_readDelay, () {
      if (!mounted || _textFor != item.id) return;
      final int width = item.asset.width;
      final int height = item.asset.height;
      final ScreenshotTextController controller = ScreenshotTextController(
        recognition: sl(),
        open: () => item.asset.file,
        // The shape [_Photo] is drawing the picture at. Handed over so the
        // controller can refuse to offer a selection it would have to place by
        // guesswork — see `_agrees`.
        displayAspect: (width > 0 && height > 0) ? width / height : 0,
      )..addListener(_onTextChanged);
      setState(() => _text = controller);
      controller.load();
    });
  }

  static const Duration _readDelay = Duration(milliseconds: 400);

  void _onTextChanged() {
    if (!mounted) return;
    // A selection that arrives while the chrome is hidden has nowhere to put
    // its bar, and the bar is the only way to act on it.
    if (_selecting && !_chromeVisible) {
      _chromeVisible = true;
      _applySystemBars();
    }
    if ((_text?.hasText ?? false) && !_selecting) _maybeHint();
    setState(() {});
  }

  /// Says the gesture out loud, once per install.
  ///
  /// A long press is the right gesture and an invisible one: nothing about a
  /// photograph suggests its words can be touched. This is the smallest honest
  /// fix — one line, on the first screenshot Shoto finds text in, that leaves
  /// on its own and never comes back. A permanent affordance would be chrome
  /// over every picture forever to teach a thing you only need told once.
  Future<void> _maybeHint() async {
    final AppPreferences prefs = sl<AppPreferences>();
    if (_hintVisible || prefs.hasSeenCopyTextHint) return;

    await prefs.markCopyTextHintSeen();
    if (!mounted) return;

    setState(() => _hintVisible = true);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _hintVisible = false);
    });
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
    _textDebounce?.cancel();
    _hintTimer?.cancel();
    _text?.removeListener(_onTextChanged);
    _text?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Puts the whole picture's text under a selection, for the two entry points
  /// that are not a long press.
  ///
  /// Everything selected rather than nothing: a button called "Select text"
  /// that selects no text has only told the user the feature exists. From here
  /// the handles narrow it down, which is a smaller job than finding the first
  /// word by hand.
  Future<void> _selectText() async {
    final ScreenshotTextController? controller = _text;
    if (controller == null) return;

    if (!controller.isLoaded) await controller.load();
    if (!mounted) return;

    if (!controller.hasText) {
      showAppSnackBar(context, context.l10n.copyTextNone);
      return;
    }
    controller.selectAll();
  }

  /// **Copying is free, and unlimited, and that is a decision rather than an
  /// omission.**
  ///
  /// It was behind the paywall for exactly one afternoon, with a free copy a
  /// month, and the argument against it is the one already written into
  /// `PremiumFeature.all` about search: charging for something the app hands
  /// out is *«the exact failure ... on the screen where somebody decides
  /// whether to trust the price»*. Reading a screenshot is one OCR pass, Shoto
  /// already runs it for free so that search works, and selling the second use
  /// of a pass it gives away is a distinction only the source code can see.
  ///
  /// The stronger reason is what the phone already does. Both platforms lift
  /// text out of a picture for nothing — Live Text in Photos, Lens in Google
  /// Photos, on the same screenshot, one app-switch away. A price on this does
  /// not read as *premium*, it reads as Shoto charging for what the phone does
  /// free, and that verdict does not stay on this feature: it is carried to
  /// the price of Safe Share, which genuinely is Shoto's own.
  ///
  /// And a paid copy fails in the worst possible moment. The second one lands
  /// mid-task, on somebody holding a number they can see and cannot take —
  /// maximum frustration, minimum willingness to pay, and one app-switch from
  /// learning that Shoto is the slow way to do this. That lesson does not come
  /// back. What this feature is worth is the *habit*: the person who opens
  /// Shoto every day to lift a code out of a picture is the person who reaches
  /// the library ceiling and meets Safe Share. Gating the habit gates the
  /// funnel that feeds everything else.
  ///
  /// What stays paid is [_runSelectionAction] — the layer above the copy,
  /// which is Shoto's own and which no gallery offers.
  Future<void> _copySelection() async {
    final String text = _text?.selectedText ?? '';
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    Haptics.confirm();
    if (!mounted) return;
    showAppSnackBar(
      context,
      context.l10n.actionsCopied,
      kind: SnackKind.success,
    );
  }

  Future<void> _shareSelection() async {
    final String text = _text?.selectedText ?? '';
    if (text.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Opening a link, starting directions, writing the event down — the one
  /// part of a selection that is **not** something the phone's own gallery
  /// will do for you.
  ///
  /// Gated like the actions sheet it borrows its detectors from, and with no
  /// free trial for the same reason that sheet has none: it appears only when
  /// there is genuinely something extra to do, so it is an offer arriving at a
  /// moment of value rather than a gate standing in front of a task. Copy is
  /// right there beside it, free, and it can do everything this can — by hand.
  Future<void> _runSelectionAction(ActionOption option) async {
    if (!await ensurePremium(context) || !mounted) return;
    // Read before the run, not after: the sentence is needed on the failure
    // path, and by then the launch has been awaited.
    final String noApp = context.l10n.actionsNoApp;
    final bool handled = await option.run();
    if (!handled && mounted) showAppSnackBar(context, noApp);
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
        _currentItem = current;
        final bool selecting = _selecting;

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
                    // A selection is dragged sideways as often as downwards,
                    // and the page under it must not take that as "next
                    // picture" — losing the selection *and* the screenshot it
                    // was on in one gesture.
                    physics: selecting
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _syncText(items[index.clamp(0, items.length - 1)]);
                    },
                    itemBuilder: (context, index) => GestureDetector(
                      // While something is selected, a tap on the picture
                      // means "never mind" — the way tapping away from a
                      // selection has meant since text had selections. It
                      // costs the tap that would have hidden the chrome, which
                      // is the lesser of the two.
                      onTap: selecting ? _text!.clear : _toggleChrome,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        // One finger selects while a selection is live; two
                        // still pan and zoom. Without this the viewer's own
                        // recogniser would fight every drag of a handle.
                        panEnabled: !selecting,
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
                            // Only the picture in front of the user can be
                            // selected on. The neighbours a PageView keeps
                            // built have no business holding a live gesture.
                            text: index == safeIndex ? _text : null,
                            onDragPoint: (Offset? at) =>
                                setState(() => _magnifier = at),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Built only once the picture has landed — see [_settled]. Until
                // then these are three full-screen blurs the flight would be
                // paying for and nobody would be using.
                //
                // **And they blur the picture once between them, not three
                // times each.** Every piece of glass on this screen is over the
                // same thing — the photograph below — and a `BackdropFilter`
                // left to itself snapshots and blurs the screen behind it
                // independently of every other one. Three bars meant three
                // snapshots and three blurs of one unchanged picture, on every
                // frame any of them moved. A [BackdropGroup] hands them a
                // single shared backdrop.
                //
                // **The group starts here, below the bars and above the
                // photo**, and that placement is the whole of its correctness:
                // a grouped filter reads what was painted *before* the group,
                // so the picture has to be outside it. Wrapped one level
                // higher, around the [PageView] as well, the bars would be
                // blurring the black page behind the photograph instead of the
                // photograph, and the glass would come out dark and empty.
                if (_settled) ...[
                  Positioned.fill(
                    child: BackdropGroup(
                      child: Stack(
                        children: <Widget>[
                          _Chrome(
                            visible: _chromeVisible,
                            alignment: Alignment.topCenter,
                            child: _TopBar(
                              position: safeIndex + 1,
                              total: items.length,
                              // Only once the picture has been read and turned out to
                              // have words in it. A button that is present on every
                              // photograph and does nothing on most of them teaches
                              // people to stop pressing it.
                              onSelectText: (_text?.hasText ?? false)
                                  ? _selectText
                                  : null,
                            ),
                          ),
                          _Chrome(
                            visible: _chromeVisible,
                            alignment: Alignment.bottomCenter,
                            // Both bars are built at their natural size and one is
                            // shown — a cross-fade, so the bottom of the screen
                            // changes its mind in one movement rather than jumping.
                            child: AnimatedSwitcher(
                              duration: AppMotion.duration(
                                context,
                                AppMotion.normal,
                              ),
                              switchInCurve: AppMotion.standard,
                              switchOutCurve: AppMotion.standard,
                              child: selecting
                                  ? TextSelectionBar(
                                      key: const ValueKey<String>('selection'),
                                      selection: _text!.selectedText,
                                      onCopy: _copySelection,
                                      onShare: _shareSelection,
                                      onSelectAll: _text!.selectAll,
                                      onClose: _text!.clear,
                                      onAction: _runSelectionAction,
                                    )
                                  : Column(
                                      key: const ValueKey<String>('actions'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        if (_hintVisible) const _CopyTextHint(),
                                        // Above the verbs, not among them. Everything
                                        // in the bar below *does* something to the
                                        // screenshot right now; this states what the
                                        // user means to do about it later, and a
                                        // seventh icon in that row would read as a
                                        // seventh thing to trigger — the same reason
                                        // it sits above the actions in the
                                        // quick-actions sheet.
                                        _IntentBar(item: current),
                                        _ActionBar(
                                          item: current,
                                          onFavorite: () =>
                                              _toggleFavorite(context, current),
                                          onActions: () =>
                                              showSmartActionsSheet(
                                                context,
                                                current,
                                              ),
                                          onSafeShare: () =>
                                              _safeShare(context, current),
                                          onShare: () =>
                                              shareScreenshot(current),
                                          onMove: () => _move(context, current),
                                          onDelete: () =>
                                              _delete(context, current),
                                          onSelectText:
                                              (_text?.hasText ?? false)
                                              ? _selectText
                                              : null,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Outside the group, and last in the stack: it magnifies
                // whatever is painted beneath it — which has to include the
                // bars, not just the picture — and a shared backdrop would
                // hand it the photograph without them.
                if (_magnifier != null) SelectionMagnifier(at: _magnifier!),
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

  /// The words in this picture, when it is the one in front of the user.
  final ScreenshotTextController? text;

  final ValueChanged<Offset?> onDragPoint;

  const _Photo({
    required this.item,
    required this.full,
    required this.onDragPoint,
    this.text,
    this.heroTag,
  });

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
          // Inside the picture's own box, so every rectangle the recogniser
          // reported can be drawn in the picture's own coordinates — and so a
          // zoom moves the highlight with the words it is on.
          if (widget.text != null)
            ScreenshotTextLayer(
              controller: widget.text!,
              onDragPoint: widget.onDragPoint,
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

  /// Null until this screenshot has been read and found to contain text.
  final VoidCallback? onSelectText;

  const _TopBar({
    required this.position,
    required this.total,
    this.onSelectText,
  });

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
            AppPalette.overlay.withValues(alpha: 0.55),
            AppPalette.overlay.withValues(alpha: 0.28),
            AppPalette.overlay.withValues(alpha: 0),
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
              PhotoGlassCircle(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              GlassLayer(
                radius: 999,
                sigma: AppBlur.overPhoto,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: PhotoChromePalette.circleFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: PhotoChromePalette.rim),
                  ),
                  child: Text(
                    context.l10n.countPosition(position, total),
                    style: context.text.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              // The slot on the right is occupied either way: by the button
              // when there is text to select, and by an invisible copy of the
              // back button when there is not. That is what keeps the counter
              // *centred* rather than sliding half a button sideways the
              // moment recognition finishes — a shift the eye reads as the
              // screen twitching for no reason.
              //
              // A one-frame swap between two things of the same size, so it
              // fades rather than pops.
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.normal),
                child: onSelectText == null
                    ? Opacity(
                        key: const ValueKey<String>('balance'),
                        opacity: 0,
                        child: IgnorePointer(
                          child: PhotoGlassCircle(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {},
                          ),
                        ),
                      )
                    : PhotoGlassCircle(
                        key: const ValueKey<String>('select-text'),
                        icon: Icons.text_fields_rounded,
                        onTap: onSelectText!,
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
              sigma: AppBlur.overPhoto,
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
                    gradient: PhotoChromePalette.barFill,
                    border: Border.all(color: PhotoChromePalette.rim),
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
                          state?.ref.label(context) ??
                              context.l10n.intentPrompt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall.asMedium.copyWith(
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
            PhotoGlassCircle(
              icon: isDone
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
              // Filled, not merely tinted — the same green the badge on the
              // thumbnail turns and the same green the sheet's button fills
              // with, so finishing something looks like one event no matter
              // which of the three surfaces you happened to be on.
              fill: isDone ? context.colors.success : null,
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

  /// Null when this screenshot has no readable text — the row is simply not
  /// offered, rather than offered and refused.
  final VoidCallback? onSelectText;

  const _ActionBar({
    required this.item,
    required this.onFavorite,
    required this.onActions,
    required this.onSafeShare,
    required this.onShare,
    required this.onMove,
    required this.onDelete,
    this.onSelectText,
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
        sigma: AppBlur.overPhoto,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.r),
            gradient: PhotoChromePalette.barFill,
            border: Border.all(color: PhotoChromePalette.rim),
          ),
          child: Row(
            children: [
              Expanded(
                child: PhotoBarAction(
                  icon: item.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  // The one coloured icon in the row: it is the only action
                  // here that has an on/off state to communicate.
                  tint: item.isFavorite ? context.colors.error : Colors.white,
                  label: context.l10n.detailFavorite,
                  onTap: onFavorite,
                  // Favouriting changes an outline into a filled shape and
                  // moves nothing else on screen, which at a glance is easy
                  // to miss. The pop is the confirmation.
                  pop: item.isFavorite,
                ),
              ),
              Expanded(
                child: PhotoBarAction(
                  icon: Icons.auto_fix_high_rounded,
                  label: context.l10n.detailActions,
                  onTap: onActions,
                ),
              ),
              Expanded(
                child: PhotoBarAction(
                  icon: Icons.shield_outlined,
                  label: context.l10n.detailSafeShare,
                  onTap: onSafeShare,
                ),
              ),
              Expanded(
                child: PhotoBarAction(
                  icon: Icons.ios_share_rounded,
                  label: context.l10n.commonShare,
                  onTap: onShare,
                ),
              ),
              // **Move and Delete are behind this, and Delete especially.**
              //
              // The row used to be six equal cells, which said the six were
              // equally ordinary. They are not: four of them are reversible —
              // unfavourite it, close the sheet, share it again — and one
              // permanently deletes the picture. Giving *delete the same
              // weight as favourite*, one cell away from it, on a screen the
              // user is swiping through quickly, is the shape of an accident.
              //
              // Two cells fewer also buys the four that stayed about a third
              // more width each, which is what stops their labels crowding at
              // 360pt in German.
              Expanded(
                child: PhotoBarAction(
                  icon: Icons.more_horiz_rounded,
                  label: context.l10n.detailMore,
                  onTap: () => _showMoreSheet(
                    context,
                    onMove: onMove,
                    onDelete: onDelete,
                    onSelectText: onSelectText,
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

/// The two verbs that left the bar.
///
/// A sheet rather than a popup menu because that is what the rest of the app
/// uses for exactly this — see `showFolderActionsSheet`, which offers the same
/// pair of "rename it / destroy it" choices in the same shape. Two entry
/// points that behave differently for no reason is its own small bug.
///
/// The destructive item keeps its own confirmation ([_delete] still asks); the
/// red here is not the safeguard, it is the warning that one is coming.
Future<void> _showMoreSheet(
  BuildContext context, {
  required VoidCallback onMove,
  required VoidCallback onDelete,
  VoidCallback? onSelectText,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => SheetSurface(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // First, and above the two verbs that were always here: it is the
            // only one of the three that is neither destructive nor a chore,
            // and it is the one somebody who came looking for a menu is most
            // likely to be looking for.
            if (onSelectText != null)
              ListTile(
                leading: Icon(
                  Icons.text_fields_rounded,
                  color: context.colors.textPrimary,
                ),
                title: Text(
                  context.l10n.copyTextSelect,
                  style: context.text.bodyLarge,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelectText();
                },
              ),
            ListTile(
              leading: Icon(
                Icons.folder_open_rounded,
                color: context.colors.textPrimary,
              ),
              title: Text(
                context.l10n.libraryActionMove,
                style: context.text.bodyLarge,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onMove();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.error,
              ),
              title: Text(
                context.l10n.commonDelete,
                style: context.text.bodyLarge.copyWith(
                  color: context.colors.error,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onDelete();
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    ),
  );
}

/// "Press and hold any text to copy it" — once, ever.
///
/// Deliberately not a dialog, a coach mark with a cutout, or an arrow pointing
/// at the picture. All three interrupt somebody who opened a screenshot to
/// look at it, to teach them about a feature they have not asked for yet. A
/// line of text at the bottom of the screen that leaves by itself is the
/// weakest interruption that can still do the job, and the job is small: the
/// gesture is one people already know from every other place text lives.
class _CopyTextHint extends StatelessWidget {
  const _CopyTextHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassLayer(
          radius: 999,
          sigma: AppBlur.overPhoto,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: PhotoChromePalette.circleFill,
              border: Border.all(color: PhotoChromePalette.rim),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.touch_app_rounded,
                  size: 15.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    context.l10n.copyTextHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
