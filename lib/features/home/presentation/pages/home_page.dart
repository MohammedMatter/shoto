import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/photo_hero.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/request_photo_permission_use_case.dart';
import 'package:shoto/features/screenshots/presentation/pages/intent_page.dart';
import 'package:shoto/features/screenshots/presentation/pages/open_triage_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/waiting_on_you.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/pages/search_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';

/// The app's home is a *hub*, not a second gallery.
///
/// It used to be a full-bleed grid of every screenshot, which made SHOTO
/// look like a copy of the system photo app: opening it answered "what do I
/// have?", a question the gallery already answers, instead of "what should I
/// do?". The full library still exists, on its own tab. This screen exists
/// to surface the one number that matters — how much is still unsorted —
/// plus the work the app can do on your behalf.
class HomePage extends StatefulWidget {
  /// Switches the shell to the library tab, **showing the slice named here**.
  ///
  /// It used to take no argument, and that was the bug: every route into the
  /// Library landed on the whole thing. Tapping a hero that reads "7
  /// screenshots you have not filed yet" and being handed all 8 makes the
  /// number decorative — the one question the screen exists to ask cannot be
  /// followed up on. Passed in rather than looked up so this page still has
  /// no dependency on how navigation happens to be built.
  final ValueChanged<LibraryFilter> onOpenLibrary;

  /// Starts a job that needs screenshots picked for it — see [LibraryIntent].
  ///
  /// This is what replaced the two tool rows that answered a tap with
  /// instructions. Safe share needs a screenshot and merging needs two, and
  /// Home has neither, so both used to print a sentence telling the user which
  /// screen to visit and which gesture to perform there. A row that looks like
  /// a button and behaves like a sign-post is the single least professional
  /// thing this screen did.
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;

  /// The folder count is a way in now, not a fact.
  final VoidCallback onOpenFolders;

  const HomePage({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenLibraryForIntent,
    required this.onOpenFolders,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  /// The one deliberately visible piece of motion in SHOTO.
  ///
  /// Everywhere else the rule is restraint, because everywhere else is
  /// something the user does dozens of times a day. Home is different: it is
  /// built **once**, when the shell appears, and it survives inside an
  /// `IndexedStack` for the rest of the session — so switching tabs back to
  /// it does not replay this. Once per app launch is exactly the frequency
  /// tier where a bit of choreography is allowed to exist.
  ///
  /// Six sections, 60ms apart, 220ms each. The stagger is inside the 30–80ms
  /// band and the count is **at** the six-item ceiling; past either of those a
  /// cascade stops reading as choreography and starts reading as a slow
  /// screen.
  ///
  /// The total has to cover the last section's whole span, not just its start:
  /// section five begins at `5 × 60 = 300ms` and runs for 220, so anything
  /// under 520 makes [Interval] end past 1.0 and throws. It was 480 for five
  /// sections, which is exactly that number for one section fewer.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: _entranceTotal,
  )..forward();

  static const Duration _entranceTotal = Duration(milliseconds: 520);

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
            builder: (context, state) {
              final ScreenshotsLoadedState? loaded =
                  state is ScreenshotsLoadedState ? state : null;
              final List<ScreenshotEntity> all =
                  loaded?.screenshots ?? const [];

              // "Unsorted" is derived rather than stored: anything never
              // filed or starred is, by definition, still waiting on the
              // user. Deriving it means the number cannot drift out of sync
              // with reality the way a cached flag would.
              final int unsorted = all.where((s) => s.isUnsorted).length;

              // Order is the real design decision on this screen, and it was
              // backwards. Tools sat above Recent, so the four things the app
              // *can* do outranked the twelve things the user actually has —
              // and pushed their own screenshots off the bottom of the
              // screen entirely. What you own comes before what the app
              // offers; discovery is worth a scroll, your own library is not.
              // The list itself carries **no horizontal padding**, and every
              // section applies its own.
              //
              // That looks like extra work for nothing until you reach the
              // recent strip, which is supposed to run off the edge of the
              // screen. A row that stops neatly at the same margin as
              // everything above it reads as a finished list of four; a row
              // that leaves the page tells you there is more without
              // spending a single word saying so. It cannot do that from
              // inside a padded parent, and Flutter has no negative padding.
              return ListView(
                padding: EdgeInsets.only(top: 10.h, bottom: 130.h),
                children: [
                  _Enter(
                    parent: _entrance,
                    index: 0,
                    child: _Gutter(child: _Greeting()),
                  ),
                  SizedBox(height: 18.h),
                  // The inbox, and the invitation to have one.
                  //
                  // Above search and above the hero, because it is the only
                  // thing on this screen with a deadline attached: what you
                  // captured since you last looked is answerable now and
                  // steadily less answerable later. It draws nothing at all
                  // unless there is something to say — see [_Intake].
                  //
                  // It shares the search field's step in the entrance cascade
                  // rather than taking one of its own: the steps and the
                  // controller's total have to move together (see [_Enter]),
                  // and adding a step for a section that is usually not there
                  // would push the last one past the end of the clock on every
                  // launch to pay for a beat that is almost never used.
                  _Enter(
                    parent: _entrance,
                    index: 1,
                    child: _Gutter(child: _Intake(hasLibrary: all.isNotEmpty)),
                  ),
                  // **Second on the page, and the screen's only entry to
                  // search** — see `docs/decisions/home.md`.
                  //
                  // Not shown before there is anything to search. A control
                  // that cannot succeed is worse than no control: it reads as
                  // the app not knowing its own state.
                  if (all.isNotEmpty) ...[
                    _Enter(
                      parent: _entrance,
                      index: 1,
                      child: _Gutter(child: _SearchField()),
                    ),
                    SizedBox(height: 26.h),
                  ],
                  _Enter(
                    parent: _entrance,
                    index: 2,
                    child: _Gutter(
                      child: _UnsortedHeadline(
                        unsortedCount: unsorted,
                        hasLibrary: all.isNotEmpty,
                        isLoading: loaded == null,
                        onTap: widget.onOpenLibrary,
                        onImport: () => importScreenshots(
                          context,
                          bloc: context.read<ScreenshotsBloc>(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Directly under the hero, and above the totals. The hero is
                  // what has piled up; this is what the user themselves said
                  // they would do about some of it, and putting a shrinking
                  // number below the static ones would bury the only figure on
                  // this screen anybody can finish.
                  if (loaded != null && loaded.waitingByIntent.isNotEmpty) ...[
                    _Enter(
                      parent: _entrance,
                      index: 3,
                      child: _Gutter(
                        child: WaitingOnYou(
                          waiting: loaded.waitingByIntent,
                          onOpen: (IntentRef intent) =>
                              Navigator.of(context).push(
                                FadeSlidePageRoute(
                                  builder: (_) =>
                                      BlocProvider<ScreenshotsBloc>.value(
                                        value: context.read<ScreenshotsBloc>(),
                                        child: IntentPage(intent: intent),
                                      ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                  ],
                  // Three zeros are not three facts. The counts appear when
                  // there is something to count — the same rule the search
                  // field above follows.
                  if (all.isNotEmpty)
                    _Enter(
                      parent: _entrance,
                      index: 3,
                      child: _Gutter(
                        child: _StatLine(
                          total: all.length,
                          favorites: all.where((s) => s.isFavorite).length,
                          onOpenLibrary: widget.onOpenLibrary,
                          onOpenFolders: widget.onOpenFolders,
                        ),
                      ),
                    ),
                  if (all.isNotEmpty) ...[
                    SizedBox(height: 34.h),
                    _Enter(
                      parent: _entrance,
                      index: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Gutter(
                            child: _SectionTitle(
                              context.l10n.homeRecent,
                              // "See all" means all — this one is browsing,
                              // not the inbox.
                              onSeeAll: () =>
                                  widget.onOpenLibrary(LibraryFilter.all),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Deliberately outside the gutter.
                          _RecentStrip(screenshots: all.take(12).toList()),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 34.h),
                  _Enter(
                    parent: _entrance,
                    index: 5,
                    child: _Gutter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Two headings, because the list answers two
                          // different questions — where to begin, versus what
                          // is available. See `docs/decisions/home.md`.
                          _SectionTitle(
                            all.isEmpty
                                ? context.l10n.homeToolsTitleEmpty
                                : context.l10n.homeToolsTitle,
                          ),
                          SizedBox(height: 4.h),
                          _ToolList(
                            // The hero above already carries this action on a
                            // fresh install, and a screen that offers the same
                            // thing twice is not twice as discoverable — it is
                            // the argument this file already makes about
                            // search having lived both in the header and in
                            // this list. It also redirects every remaining
                            // row while there is nothing to use them on.
                            hasLibrary: all.isNotEmpty,
                            onOpenLibraryForIntent:
                                widget.onOpenLibraryForIntent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The page margin, applied per section rather than by the scroll view, so
/// the one section that is meant to break it can.
/// The one place SHOTO ever mentions a screenshot it does not have.
///
/// It has three states and two of them draw nothing:
///
/// * **The invitation**, once, when there is already a library — so the
///   question arrives after the app has shown what it is for, not on an empty
///   first screen where it would read as a permission grab.
/// * **The queue**, whenever captures are waiting.
/// * **Nothing**, which is most of the time, and is why this is a widget
///   rather than a section of the list: a card that says "0 new" is a card
///   that has to be looked at every single launch to learn nothing.
///
/// The count is read once per mount rather than watched. A stream of gallery
/// changes would repaint Home while somebody is taking screenshots in another
/// app, which nobody is watching, and would keep a platform listener alive for
/// the whole session for the sake of a number that is only acted on when the
/// app is opened.
class _Intake extends StatefulWidget {
  final bool hasLibrary;

  const _Intake({required this.hasLibrary});

  @override
  State<_Intake> createState() => _IntakeState();
}

class _IntakeState extends State<_Intake> {
  int _waiting = 0;

  @override
  void initState() {
    super.initState();
    _count();
  }

  Future<void> _count() async {
    final List<AssetEntity> captures = await sl<GetNewCapturesUseCase>()();
    if (!mounted) return;
    setState(() => _waiting = captures.length);
  }

  Future<void> _accept() async {
    // The OS permission is asked for *after* the user has said yes to the
    // idea, never before. A system dialog is not a way to ask a product
    // question: it has two buttons the app did not write and no room for the
    // sentence that makes the request reasonable.
    final PermissionState permission = await sl<RequestPhotoPermissionUseCase>()();
    if (!permission.hasAccess) {
      if (!mounted) return;
      await sl<AppPreferences>().setTriageEnabled(false);
      return;
    }

    await sl<AppPreferences>().setTriageEnabled(true);
    if (!mounted) return;
    await openTriagePage(context);
    if (!mounted) return;
    await _count();
  }

  Future<void> _decline() async {
    await sl<AppPreferences>().setTriageEnabled(false);
    if (mounted) setState(() {});
  }

  Future<void> _review() async {
    await openTriagePage(context);
    if (!mounted) return;
    await _count();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<AppPreferences>(),
      builder: (context, _) {
        final AppPreferences prefs = sl<AppPreferences>();

        if (!prefs.triageAsked) {
          if (!widget.hasLibrary) return const SizedBox.shrink();
          return _IntakeInvite(onAccept: _accept, onDecline: _decline);
        }

        if (!prefs.triageEnabled || _waiting == 0) {
          return const SizedBox.shrink();
        }

        return _IntakeQueue(count: _waiting, onTap: _review);
      },
    );
  }
}

class _IntakeInvite extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IntakeInvite({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.triageInviteTitle,
            style: AppTextStyles.titleLarge,
          ),
          SizedBox(height: 4.h),
          // The whole of it, not a summary with a "learn more". This is the
          // one place the app asks to look at something it does not own, and
          // the answer to "what will you do with it" has to be on the same
          // screen as the button that says yes.
          Text(context.l10n.triageInviteBody, style: AppTextStyles.bodySmall),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDecline,
                child: Text(
                  context.l10n.triageInviteDecline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAccept,
                child: Text(
                  context.l10n.triageInviteAccept,
                  style: AppTextStyles.bodyMedium.asMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntakeQueue extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _IntakeQueue({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 19.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                context.l10n.triageNewCount(count),
                style: AppTextStyles.bodyMedium.asMedium,
              ),
            ),
            Text(
              context.l10n.triageReview,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  final Widget child;
  const _Gutter({required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w),
    child: child,
  );
}

/// One section of the Home entrance cascade.
///
/// Driven off a single shared controller with an [Interval] per index rather
/// than a controller (and a `Future.delayed`) per section: one ticker for the
/// whole screen, and the sections cannot drift out of step with each other
/// because they are all reading the same clock.
class _Enter extends StatelessWidget {
  final Animation<double> parent;
  final int index;
  final Widget child;

  const _Enter({
    required this.parent,
    required this.index,
    required this.child,
  });

  /// Fractions of the parent controller's total. Kept as expressions rather
  /// than decimals so the relationship to the duration stays legible — these
  /// two and `_entranceTotal` have to move together or the last section's
  /// interval runs past the end of the clock.
  static const double _step = 60 / 520;
  static const double _span = 220 / 520;

  @override
  Widget build(BuildContext context) {
    // Reduced motion drops the whole cascade rather than shortening it. This
    // is decoration by definition — nothing here is telling the user
    // anything they would lose.
    if (AppMotion.reduced(context)) return child;

    // `drive` rather than a CurvedAnimation: this widget rebuilds on every
    // bloc emission, and a CurvedAnimation built in `build` is an object to
    // allocate and dispose on each one.
    final Animation<double> t = parent.drive(
      CurveTween(
        curve: Interval(
          index * _step,
          index * _step + _span,
          curve: AppMotion.standard,
        ),
      ),
    );

    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        // A few pixels. The point is that it arrived, not that it travelled.
        position: t.drive(
          Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

/// A number that counts to its value instead of appearing at it.
///
/// Two jobs, both legitimate. On first paint it gives the stat row something
/// to do while the library loads, so the screen resolves rather than blinks
/// from zeros to totals. Afterwards it is state indication: file a screenshot
/// and the unsorted count visibly ticks down, which is the app confirming the
/// thing you just did actually landed.
class _Count extends StatelessWidget {
  final int value;
  final TextStyle style;

  const _Count(this.value, {required this.style});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return Text('$value', style: style);

    return TweenAnimationBuilder<int>(
      // Longer than the 300ms UI ceiling on purpose: that budget is for
      // things the user is *waiting on*. Nothing is blocked by this — the
      // final number is legible from the first frames, and a count that
      // resolves in 150ms may as well not count at all.
      duration: const Duration(milliseconds: 420),
      curve: AppMotion.standard,
      tween: IntTween(begin: 0, end: value),
      builder: (context, current, _) => Text('$current', style: style),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final int hour = DateTime.now().hour;
    final String part = hour < 12
        ? context.l10n.homeGreetingMorning
        : hour < 18
        ? context.l10n.homeGreetingAfternoon
        : context.l10n.homeGreetingEvening;

    // No trailing button any more.
    //
    // The search circle used to live here, in the top-right corner — which on
    // a phone this tall is the one place a thumb cannot reach without
    // regripping. It is a full-width field of its own now, directly below.
    // What is left is a greeting and a name, which is all this row was ever
    // really for.
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part, style: AppTextStyles.bodyMedium),
              SizedBox(height: 1.h),
              // Plain text, not a ShaderMask.
              //
              // The mask was there to paint a blue→violet→coral sweep across
              // the wordmark. That sweep is gone from the palette, so the
              // shader had been reduced to filling the glyphs with a single
              // flat colour — an offscreen render pass and a saveLayer on
              // every frame of this screen, to produce exactly what `color`
              // produces for free.
              //
              // The wordmark is the one text in the app allowed to be marker.
              // It is a name rather than something to read, it appears once,
              // and it is what tells you which app you opened.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'SHOTO',
                    style: AppTextStyles.headlineLarge.copyWith(
                      // Ink, not the accent.
                      //
                      // With the coloured card gone this was the last saturated
                      // thing on Home, and at wordmark size it was also the
                      // largest — a 100%-saturation indigo, which is the single
                      // most recognisable fingerprint of a generated interface.
                      // The name reads perfectly well in ink, and the screen now
                      // has no accent on it at all until the palette question is
                      // settled.
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  // Locked to the wordmark rather than placed anywhere else on
                  // the screen, because what is Pro is the *app*, not any one
                  // feature on this page. It is the first thing seen on launch
                  // and the only place in SHOTO where a badge can say that
                  // without also implying something about the row beside it.
                  //
                  // Nothing at all for a free user — no greyed-out version, no
                  // "upgrade" prod. Home is where somebody checks what needs
                  // doing, and an advertisement pinned to the app's own name
                  // every single launch is the fastest way to make a person
                  // stop reading the top of the screen.
                  SizedBox(width: 8.w),
                  const ProBadgeIfSubscribed(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The app's best feature, made reachable and made obvious.
///
/// Not a real [TextField]. Tapping it opens the search page, which owns the
/// actual input, the results and the focus handling — a live field here would
/// mean two search UIs to keep in step, and a keyboard opening over Home every
/// time somebody's thumb brushed the top of the screen. This is a button
/// wearing a field's clothes, which is what the Files, Photos and Notes home
/// screens all use for the same reason.
///
/// The placeholder is [AppLocalizations.searchHint] — the same sentence the
/// real field uses, so the promise made here is the one kept there.
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Shallow: a full-width control shrinking by 3% moves a lot of pixels
      // and starts to read as the page flexing.
      scale: 0.99,
      onTap: () =>
          openSearchPage(context, bloc: context.read<ScreenshotsBloc>()),
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(14.w, 13.h, 12.w, 13.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 19.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                context.l10n.searchHint,
                style: AppTextStyles.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The screen's one hero. Everything else here is secondary to the question
/// "is there anything for me to do?".
///
/// **It is not a card, and it must not become one** — the figure carries the
/// screen on type size alone. See `docs/decisions/home.md` for the three
/// shapes this went through and why each container came off.
class _UnsortedHeadline extends StatelessWidget {
  final int unsortedCount;
  final bool hasLibrary;
  final bool isLoading;
  final ValueChanged<LibraryFilter> onTap;

  /// Opens the OS picker. Only ever used by the empty state — see the button
  /// in that branch for why the hero has an action at all.
  final VoidCallback onImport;

  const _UnsortedHeadline({
    required this.unsortedCount,
    required this.hasLibrary,
    required this.isLoading,
    required this.onTap,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    // `isLoading` is handled by its own early return below, so it is not part
    // of this any more.
    final bool needsAttention = hasLibrary && unsortedCount > 0;

    // Type size *is* the urgency here, so there is no giant figure when
    // there is no work. An app that shows you a 58px "0" every morning has
    // spent its loudest voice on nothing, and the next time it shouts you
    // will not look up.
    // **Nothing at all until the answer is known** — no word, no shimmer.
    //
    // This slot used to read the literal word "Loading" at headline size, with
    // "Reading your library" under it: a placeholder in the most prominent
    // position on the screen, where a number belongs, announcing the one thing
    // nobody opened the app to find out. A skeleton was tried in its place and
    // was the same mistake wearing better clothes — it still spends the hero
    // on the fact that a query is in flight.
    //
    // Falling through to the empty-library copy instead would be worse than
    // either: "Nothing saved" is a *claim*, and for somebody with a full
    // library it is briefly a false one. Silence is the only option here that
    // is never wrong, and the read is fast enough that there is nothing to
    // fill.
    if (isLoading) return const SizedBox.shrink();

    if (!needsAttention) {
      final String headline = !hasLibrary
          ? context.l10n.homeInboxEmpty
          : context.l10n.homeInboxClear;

      final String detail = !hasLibrary
          ? context.l10n.homeInboxEmptySubtitle
          : context.l10n.homeInboxClearSubtitle;

      return PressableScale(
        scale: 0.99,
        // Nothing is waiting, so this opens the library rather than an
        // "unsorted" filter that is empty by definition — tapping "all filed"
        // and landing on a blank grid would read as the app having lost them.
        onTap: hasLibrary ? () => onTap(LibraryFilter.all) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One step down from the wordmark, and for the reason this class
            // already argues about the figure below it.
            //
            // Both were `headlineLarge` — the same 23sp display face, 400px
            // apart, so the eye arrived at "SHOTO" and "all filed" with no way
            // to rank them. And of the two states this widget has, **the calm
            // one is the state with nothing to report**: "all filed" means
            // there is no work. Spending the page's largest voice on the
            // absence of news is exactly what the comment above refuses to do
            // with a giant `0`, and it was doing it here in words.
            //
            // The urgent branch below is untouched. When something *is*
            // waiting, the figure is still the biggest thing on the screen —
            // which is the whole design, and it only works if the calm state
            // stands down.
            Text(headline, style: AppTextStyles.headlineMedium),
            SizedBox(height: 5.h),
            Text(
              detail,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // **The empty room's way out, in the largest slot on the screen.**
            //
            // A brand-new library said "Nothing saved" and "Share a
            // screenshot into SHOTO to start", and stopped there. That is an
            // instruction to *leave*: the only route it named requires
            // switching to another app, finding a screenshot, opening its
            // share sheet and coming back. On the one screen where somebody
            // has just arrived and is deciding whether this was worth
            // installing, the app had nothing for them to do in it.
            //
            // The picker fixes that in one tap, and it does not cost the
            // opt-in premise a thing: it is the operating system's own
            // multi-select picker, running outside the app, which hands back
            // only what was chosen. SHOTO still never enumerates a gallery —
            // see [SystemPhotoPickerDataSource], which exists for exactly
            // this distinction.
            //
            // Only in the empty state. Once there is a library the hero has a
            // number to show and importing is a tool row like any other.
            if (!hasLibrary) ...[
              SizedBox(height: 16.h),
              PrimaryButton(
                label: context.l10n.homeEmptyImportCta,
                onPressed: onImport,
              ),
            ],
          ],
        ),
      );
    }

    return PressableScale(
      scale: 0.99,
      // The whole point of the change: the figure above and the grid this
      // opens are now the same set of screenshots.
      onTap: () => onTap(LibraryFilter.unsorted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The count animates on arrival and, more usefully, every time it
          // changes: file one screenshot and the number on Home visibly
          // drops. That is the app confirming the work landed, in the one
          // place the user is looking for confirmation.
          _Count(unsortedCount, style: AppTextStyles.displayHero),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeInboxCountSubtitle,
                  style: AppTextStyles.bodyLarge.asMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.arrow_forward_rounded,
                // The one action the whole screen is built around.
                color: AppColors.marker,
                size: 19.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The three counts, set as **one line of text**.
///
/// This was three bordered cards, then one card with three columns, and it
/// is now a sentence. Each step asked the same question — does this
/// information need a container? — and the honest answer for a set of totals
/// nobody acts on is no. They are context, not controls: you glance at them
/// to know the library is there and then you look at something else.
///
/// Boxing context is how a screen ends up with seven outlines on it. Setting
/// it as a line of type costs no borders, no shadows and no corner radii,
/// and it puts the emphasis where it belongs — on the figures, which stay in
/// the tabular mono face so they do not shift while they count.
/// ---
///
/// **Each pair is now a way in.**
///
/// The paragraph above argued these are context rather than controls, and that
/// was right about the *shape* and wrong about the destination: every one of
/// these three numbers already had a screen behind it. Favourites is a filter
/// the Library supports, folders is an entire tab, and the total is the
/// Library itself — so the line was quietly the shortest route to three places
/// while behaving like decoration.
///
/// Making them tappable changes no pixels when nothing is pressed, which is
/// the test it had to pass: the argument for setting this as a line of type
/// instead of three cards still holds, and a shortcut that costs nothing to
/// look at is the cheapest kind there is.
class _StatLine extends StatelessWidget {
  final int total;
  final int favorites;
  final ValueChanged<LibraryFilter> onOpenLibrary;
  final VoidCallback onOpenFolders;

  const _StatLine({
    required this.total,
    required this.favorites,
    required this.onOpenLibrary,
    required this.onOpenFolders,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FoldersBloc, FoldersState>(
      builder: (context, state) {
        final int folders = state is FoldersLoadedState
            ? state.folders.length
            : 0;

        final TextStyle label = AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        );
        TextStyle figure(Color color) => AppTextStyles.mono.asSemiBold.copyWith(
          fontSize: 12.sp,
          color: color,
        );

        Widget dot() => Padding(
          padding: EdgeInsets.symmetric(horizontal: 7.w),
          child: Text('·', style: label),
        );

        // **Label first, figure second** — and this is a grammar fix, not a
        // style preference.
        //
        // These three strings are bare plural nouns, written to sit *under* a
        // number in a tile. Setting them after one, as prose, produces "1
        // Folders" in English and "١ مجلدات" in Arabic, which is simply
        // wrong — and correcting it properly would mean ICU plural forms in
        // six languages, including Arabic's six-way split, for a line nobody
        // reads twice.
        //
        // Reversed, they are label-and-value pairs rather than sentences:
        // "Screenshots 12", "مجلدات 1". No agreement is implied, so no
        // agreement can be wrong, in any of the six. It also reads as an
        // index rather than a caption, which suits the screen better.
        //
        // Wrap rather than Row: the labels are much longer in some languages
        // and a Row would overflow instead of moving the last pair down.
        //
        // Each pair is wrapped individually rather than the whole line being
        // one target: three destinations need three targets, and a single tap
        // area spanning all of them could only ever go to one of the three.
        // **A zero gets no hue**, whatever the pair's colour is.
        //
        // The tints below are right — they are the same red the heart wears
        // and the same blue the folders wear, so the line reads as an index of
        // things you already recognise. But a red `0` beside "Favourites" does
        // not read as "none of these"; on a dark screen it reads as an alert,
        // because red at a glance means *something is wrong* and the eye gets
        // there long before the word does. Nothing is wrong. There are simply
        // no favourites yet.
        //
        // The rule generalises: a colour encodes what a value *means*, and
        // zero of something means nothing at all.
        Widget stat(String name, int value, Color tint, VoidCallback onTap) =>
            PressableScale(
              scale: 0.94,
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: label),
                  Text(
                    ' $value',
                    style: figure(value == 0 ? AppColors.textSecondary : tint),
                  ),
                ],
              ),
            );

        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // The total is just a total; it gets no hue.
            stat(
              context.l10n.homeStatScreenshots,
              total,
              AppColors.textPrimary,
              () => onOpenLibrary(LibraryFilter.all),
            ),
            dot(),
            // These two do carry meaning, and they carry the *same* meaning
            // the heart and the folder icons carry elsewhere in the app — so
            // tinting them here is consistency rather than decoration.
            stat(
              context.l10n.homeStatFavorites,
              favorites,
              AppColors.error,
              () => onOpenLibrary(LibraryFilter.favorites),
            ),
            dot(),
            stat(
              context.l10n.homeStatFolders,
              folders,
              AppColors.secondary,
              onOpenFolders,
            ),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionTitle(this.title, {this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sentence case, not `toUpperCase()`. Small caps at wide tracking is
        // a label style that works when it is doing real structural work; on
        // a screen where the hierarchy is already unmistakable it is just
        // the layout raising its voice for no reason, and every generated
        // dashboard does it.
        Text(title, style: AppTextStyles.sectionLabel),
        const Spacer(),
        if (onSeeAll != null)
          PressableScale(
            scale: 0.9,
            onTap: onSeeAll,
            child: Text(
              context.l10n.homeSeeAll,
              style: AppTextStyles.sectionLabel.asSemiBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Every capability the app has, stated in plain words.
///
/// Discoverability was the real gap: a feature reachable only from a
/// long-press or a row buried in Settings may as well not exist. Paid tools
/// are shown to everyone and gated on tap, so free users can see what they
/// would be buying rather than having it hidden from them.
class _ToolList extends StatelessWidget {
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;

  /// Whether there is anything for these tools to work on.
  ///
  /// Governs two things: the import row is dropped while this is false
  /// (the hero directly above is already offering it), and every remaining
  /// row is redirected — see [_orImportFirst].
  final bool hasLibrary;

  const _ToolList({
    required this.onOpenLibraryForIntent,
    required this.hasLibrary,
  });

  /// What a tool row does when there is nothing to do it to.
  ///
  /// On a fresh install all three of these rows were dead ends. Safe share
  /// and Merge opened the Library in selection mode with nothing to select,
  /// and Find duplicates was worse than a dead end — it went straight to the
  /// paywall, so the app's answer to "what does this do?" on an empty
  /// library was to ask for money for a scan of nothing.
  ///
  /// They are not hidden, because these rows are how somebody learns Safe
  /// Share exists, and Safe Share is what the product now leads with —
  /// making it invisible until the user has already succeeded would be
  /// backwards. Instead each one answers with the single step that has to
  /// happen first anyway. This is the same principle as the tool rows that
  /// stopped printing "long-press two screenshots, then tap Merge": a row
  /// that looks like a button performs the step rather than describing it.
  VoidCallback _orImportFirst(BuildContext context, VoidCallback whenReady) {
    if (hasLibrary) return whenReady;
    return () =>
        importScreenshots(context, bloc: context.read<ScreenshotsBloc>());
  }

  @override
  Widget build(BuildContext context) {
    // A list, not a two-by-two grid of cards.
    //
    // Four equal cards in a square is the layout every generated dashboard
    // reaches for, and it was costing more than it earned here: four
    // outlines, four icon tiles, and subtitles truncated to two lines
    // because a half-width card cannot hold a sentence. As rows the
    // subtitles fit, the tools read in a scannable column, and the section
    // weighs four hairlines instead of four containers — which is what puts
    // the emphasis back on the count at the top of the screen.
    final List<_Tool> tools = [
      // First, and the only one here that *adds* something.
      //
      // The other three operate on a library that already exists, which makes
      // this the one row that matters on the day the app is installed — and Home
      // is where somebody lands with nothing in it. Library has the same action
      // in its header; both call the same function, so the two can't drift.
      if (hasLibrary)
        _Tool(
          icon: Icons.add_photo_alternate_outlined,
          // Neutral. Adding a screenshot is not information, not completion and
          // not destruction, and the palette's rule is that anything with no job
          // to encode stays colourless.
          tint: AppColors.marker,
          title: context.l10n.importTitle,
          subtitle: context.l10n.homeToolImportSubtitle,
          onTap: () =>
              importScreenshots(context, bloc: context.read<ScreenshotsBloc>()),
        ),
      _Tool(
        icon: Icons.shield_moon_rounded,
        // Hiding something before you send it is a protective, informational
        // act, not a destructive one — the same job `secondary` does
        // everywhere else in the app.
        tint: AppColors.secondary,
        title: context.l10n.homeToolSafeShare,
        subtitle: context.l10n.homeToolSafeShareSubtitle,
        // Was: a snackbar reading "Open a screenshot, then tap Safe share."
        // Now it opens the Library already in selection mode, asking for the
        // one screenshot it needs. The app performs the step it used to
        // narrate.
        onTap: _orImportFirst(
          context,
          () => onOpenLibraryForIntent(LibraryIntent.protect),
        ),
      ),
      _Tool(
        icon: Icons.content_copy_rounded,
        // Deleting copies is the one tool here that removes something.
        tint: AppColors.error,
        title: context.l10n.homeToolDuplicates,
        subtitle: context.l10n.homeToolDuplicatesSubtitle,
        // The paywall sits *inside* the ready branch, so an empty library
        // never reaches it. Asking somebody to pay to scan nothing for
        // duplicates was the single worst interaction on the first screen.
        onTap: _orImportFirst(context, () async {
          if (!await ensurePremium(context)) return;
          if (!context.mounted) return;
          await Navigator.of(
            context,
          ).push(FadeSlidePageRoute(builder: (_) => DuplicatesPage()));
        }),
      ),
      // Search is **not** in this list any more.
      //
      // It is the field at the top of the screen now, which is both more
      // reachable and more prominent than a row four items down — and one
      // capability with two entry points on one screen is not twice as
      // discoverable, it just makes the list longer.
      _Tool(
        icon: Icons.photo_size_select_large_rounded,
        // Merging produces something finished.
        tint: AppColors.success,
        title: context.l10n.homeToolStitch,
        subtitle: context.l10n.homeToolStitchSubtitle,
        // Was: "Long-press two or more screenshots in your library, then tap
        // Merge." Three instructions, one of them a gesture with no visual
        // affordance, on a screen the user had to find first.
        onTap: _orImportFirst(
          context,
          () => onOpenLibraryForIntent(LibraryIntent.merge),
        ),
      ),
    ];

    return Column(
      children: [
        for (final (int index, _Tool tool) in tools.indexed) ...[
          if (index > 0)
            Divider(height: 1, thickness: 1, color: AppColors.border),
          _ToolRow(tool: tool),
        ],
      ],
    );
  }
}

class _Tool {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Which of the four semantic hues this tool belongs to.
  ///
  /// The palette's own rule is that colour must encode something or it is
  /// noise, and four differently-tinted squares for their own sake is exactly
  /// the noise it warns about. These four are not arbitrary: each tool is
  /// tinted by **what it does to your library** — teal protects, red removes,
  /// brass is the accent action, sage completes — which is the same mapping
  /// the rest of the app already uses for those colours.
  final Color tint;

  const _Tool({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ToolRow extends StatelessWidget {
  final _Tool tool;

  const _ToolRow({required this.tool});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // Shallow: a full-width row shrinking by 3% moves a lot of pixels and
      // starts to read as the whole list flexing.
      scale: 0.99,
      onTap: tool.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // The hue at low opacity rather than a solid fill: a row of
                // four saturated squares would outshout the count at the top
                // of the screen, which is the one thing here that is actually
                // asking for something.
                color: tool.tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(tool.icon, color: tool.tint, size: 19.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tool.title, style: AppTextStyles.titleSmall),
                  SizedBox(height: 2.h),
                  Text(
                    tool.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textDisabled,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enough of the newest screenshots to recognise "yes, my things are in
/// here" — without turning Home back into the gallery it replaced.
class _RecentStrip extends StatelessWidget {
  final List<ScreenshotEntity> screenshots;

  /// Home and Library are both alive inside the shell route at all times, and
  /// both can be showing the same screenshot, so their shared-element tags
  /// have to be told apart. Two heroes with one tag in a single route is an
  /// assertion failure, not a cosmetic problem.
  static const String _heroPrefix = 'home';

  const _RecentStrip({required this.screenshots});

  /// Tall enough to look like a screen rather than a swatch.
  ///
  /// The cards were 80×118, an aspect of 0.68 — and a phone screenshot is
  /// about 0.46, so every card was a **crop of the middle** of somebody's
  /// screenshot. On a page whose whole job is to say "this is what SHOTO is
  /// holding for you", the one strip that shows the user's own content was
  /// showing a slice too small to recognise and the wrong shape to read as a
  /// screen at all.
  ///
  /// At 96×176 (0.55) the card still crops — matching 0.46 exactly would make
  /// the strip taller than the tool list under it — but it now reads as a
  /// screen, and a screenshot's most recognisable part, its top, survives.
  static const double _cardWidth = 96;
  static const double _cardHeight = 176;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Margin on the leading side only. The row starts flush with the
        // text above it and then runs off the trailing edge of the screen,
        // which is the one thing on this page allowed to break the gutter —
        // and the cheapest possible way to say "there are more of these".
        // Directional so it flips with the language.
        padding: EdgeInsetsDirectional.only(start: 20.w, end: 6.w),
        itemCount: screenshots.length,
        separatorBuilder: (_, _) => SizedBox(width: 9.w),
        itemBuilder: (context, index) => PressableScale(
          scale: 0.95,
          onTap: () {
            final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
            Navigator.of(context).push(
              PhotoViewerRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: ScreenshotDetailPage(
                    screenshots: screenshots,
                    initialIndex: index,
                    heroPrefix: _heroPrefix,
                  ),
                ),
              ),
            );
          },
          // **A hairline, because half of these are dark screenshots.**
          //
          // The canvas is `#1A1A1A` and a screenshot of a dark app is very
          // nearly the same value, so a bare thumbnail had no edge at all —
          // on a device the first two cards in this strip read as holes cut
          // out of the page rather than as pictures sitting on it. The border
          // is the app's own `border` token, one pixel, drawn *over* the image
          // so it survives whatever the screenshot's own colours are.
          child: Container(
            width: _cardWidth.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            // The clip is inset by the border so the image does not paint over
            // the line that is there to contain it.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1),
              child: PhotoHero(
                tag: '$_heroPrefix-${screenshots[index].id}',
                radius: AppRadius.md - 1,
                child: AssetThumbnailImage(asset: screenshots[index].asset),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
