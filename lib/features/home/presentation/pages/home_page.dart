import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/home/presentation/widgets/home_blocked_headline.dart';
import 'package:shoto/features/home/presentation/widgets/home_entrance.dart';
import 'package:shoto/features/home/presentation/widgets/home_greeting.dart';
import 'package:shoto/features/home/presentation/widgets/home_recent_strip.dart';
import 'package:shoto/features/home/presentation/widgets/home_search_field.dart';
import 'package:shoto/features/home/presentation/widgets/home_section_title.dart';
import 'package:shoto/features/home/presentation/widgets/home_inbox.dart';
import 'package:shoto/features/home/presentation/widgets/home_tool_list.dart';
import 'package:shoto/features/home/presentation/widgets/unsorted_headline.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/intent_page.dart';
import 'package:shoto/features/screenshots/presentation/pages/reminders_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<LibraryFilter> onOpenLibrary;
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;

  const HomePage({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenLibraryForIntent,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: HomeEnter.total,
  )..forward();

  /// Drives the greeting's parallax. A [ScrollController] is a [Listenable]
  /// that fires on every scrolled pixel, so it can be handed straight to an
  /// [AnimatedBuilder] — no listener, no `setState`, and nothing rebuilt except
  /// the two wrappers around the header.
  final ScrollController _scroll = ScrollController();

  /// How far the page has to travel before the greeting is fully gone.
  ///
  /// Roughly the greeting's own height. Shorter and it vanishes before it has
  /// visibly moved; longer and it is still hanging around, half-faded, over the
  /// first card — which reads as something failing to scroll rather than as
  /// depth.
  static double get _recedeDistance => 130.h;

  @override
  void dispose() {
    _scroll.dispose();
    _entrance.dispose();
    super.dispose();
  }

  /// 0 while the page is at rest, 1 once the greeting has receded.
  double get _receded {
    if (!_scroll.hasClients) return 0;
    final double pixels = _scroll.position.pixels;
    if (pixels <= 0) return 0;
    return (pixels / _recedeDistance).clamp(0.0, 1.0);
  }

  /// **The one piece of this page that does not move at the same speed as the
  /// rest of it.**
  ///
  /// A list where every pixel travels the same distance at the same rate is a
  /// sheet of paper behind a window: correct, and completely flat. What makes a
  /// page feel like it has depth is one plane moving slower than another, which
  /// is the whole trick behind an iOS large title and behind every scrolling
  /// header worth looking at.
  ///
  /// So the greeting lags. It is translated *down* by a third of whatever the
  /// list has scrolled up, which nets out to roughly two-thirds speed, and it
  /// dissolves and settles back a few per cent while it goes. The content slides
  /// over a header that is sinking away rather than being dragged off.
  ///
  /// Three constraints on it, all deliberate:
  ///
  /// * **`transform` and `opacity` only.** Both skip layout and paint; nothing
  ///   here re-measures on a scroll frame.
  /// * **The lag is clamped** to the recede distance. Unclamped, a translation
  ///   proportional to the scroll offset brings the greeting back onto the
  ///   screen from the top at about a thousand pixels down.
  /// * **Nothing at all under reduced motion.** This is decoration — it
  ///   explains no state and prevents no jarring change — so it is exactly the
  ///   kind of movement that setting exists to remove.
  Widget _parallax(Widget child) {
    if (AppMotion.reduced(context)) return child;

    return AnimatedBuilder(
      animation: _scroll,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = _receded;
        return Opacity(
          // **Gone at seven tenths of the travel, not at the end of it.**
          //
          // The lag is what creates the problem this line solves: holding the
          // greeting back means its top edge reaches the top of the viewport
          // while it is still two thirds opaque, and a `ListView` clips there.
          // So the first line was being *cut off* rather than fading — a hard
          // horizontal edge eating into "Good afternoon", which is the one
          // thing a dissolve must not look like. Finishing the fade early means
          // it is already gone by the time the clip could take it.
          opacity: (1 - t / 0.7).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, t * _recedeDistance * 0.35),
            child: Transform.scale(scale: 1 - 0.05 * t, child: child),
          ),
        );
      },
    );
  }

  /// The one block Home leads with, whatever the library turned out to be.
  ///
  /// Every state gets a sentence here — that is the point of the switch. Home
  /// is the first screen and the tab the app opens on, so a state it cannot
  /// draw is a blank first impression with no way out of it: a refused photo
  /// permission and a failed read both used to land in [UnsortedHeadline]'s
  /// loading branch and disappear, taking the count, the sentence and the
  /// import button with them. Only the genuinely transient states — initial
  /// and loading — still draw nothing, and they are the only ones that fix
  /// themselves.
  Widget _headline(
    BuildContext context,
    ScreenshotsState state,
    List<ScreenshotEntity> all,
  ) => switch (state) {
    // Asked, and said no. Settings is the only route left, because Android
    // will not put the dialog up a second time.
    ScreenshotsPermissionDeniedState(:final bool isPartialAccess) =>
      HomeBlockedHeadline.permission(partial: isPartialAccess),

    // Never asked. **This is the first thing a fresh install draws**, and it
    // arrived here as a blank screen: the switch below used to end in `_`, so
    // a state added to the bloc fell through to the loading skeleton and Home
    // opened on nothing at all — the exact bug this switch was written to
    // stop, reintroduced by the wildcard that was left in it.
    ScreenshotsPermissionUnaskedState() => HomeBlockedHeadline.unasked(
      onRetry: () =>
          context.read<ScreenshotsBloc>().add(RequestPhotoAccessEvent()),
    ),

    ScreenshotsErrorState(:final AppMessage message) =>
      HomeBlockedHeadline.failure(
        message,
        onRetry: () =>
            context.read<ScreenshotsBloc>().add(LoadScreenshotsEvent()),
      ),

    // **A cold start draws the user's real inbox, not a blank.**
    //
    // The load is two halves and only one of them is slow. Enumerating the
    // gallery is the slow one; the counts on this card come out of two local
    // tables that answer in a millisecond, so the bloc reads those first and
    // hands them over as `summary` — see `LibrarySummary`. What is missing at
    // this point is the *thumbnails*, and they arrive into tiles already laid
    // out for them.
    //
    // This branch used to be `SizedBox.shrink`, which is why closing Shoto and
    // reopening it showed a hole where this block belongs and then jolted the
    // whole page when the read landed.
    ScreenshotsLoadingState(:final LibrarySummary? summary)
        when summary != null && !summary.isEmpty =>
      HomeInbox.preview(count: summary.unsorted, waiting: summary.waiting),

    // Nothing is known yet — the handler has not run, or the summary read
    // itself failed. Written out rather than left to a wildcard, same rule as
    // the rest of this switch.
    ScreenshotsInitialState() ||
    ScreenshotsLoadingState() => const HomeInboxSkeleton(),

    // **An empty library still gets the headline, a filled one does not.**
    //
    // With nothing in it there is no summary to draw and the only useful
    // thing on the page is the invitation to put something in it, which is
    // what [UnsortedHeadline] is. Once there *is* a library, the same fact —
    // how much is waiting on you — is the first card of [HomeStatGrid], and
    // running both meant a giant "1" directly above a card that also said 1.
    ScreenshotsLoadedState() when all.isEmpty => UnsortedHeadline(
      unsortedCount: 0,
      hasLibrary: false,
      onTap: widget.onOpenLibrary,
      onImport: () =>
          importScreenshots(context, bloc: context.read<ScreenshotsBloc>()),
    ),

    ScreenshotsLoadedState(
      :final Map<IntentRef, int> waitingByIntent,
      :final List<ScreenshotEntity> reminders,
    ) =>
      HomeInbox(
        unsorted: all.where((s) => s.isUnsorted).toList(),
        waiting: waitingByIntent,
        reminders: reminders,
        onOpenLibrary: widget.onOpenLibrary,
        onOpenReminders: () => Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => BlocProvider<ScreenshotsBloc>.value(
              value: context.read<ScreenshotsBloc>(),
              child: const RemindersPage(),
            ),
          ),
        ),
        onOpenIntent: (IntentRef intent) => Navigator.of(context).push(
          FadeSlidePageRoute(
            builder: (_) => BlocProvider<ScreenshotsBloc>.value(
              value: context.read<ScreenshotsBloc>(),
              child: IntentPage(intent: intent),
            ),
          ),
        ),
      ),
  };

  /// Rendered in one of two places depending on whether anything is waiting —
  /// see the ordering note in `build`. A method rather than two copies, so the
  /// two positions can never drift apart.
  ///
  /// [isPending] is a library known to exist whose pictures are still being
  /// read. It draws the strip at full height with placeholder cards in it,
  /// because this section is the tallest thing on Home — a hundred and
  /// seventy-six pixels plus its heading — and it appearing late is by far the
  /// largest of the shifts a cold start used to make.
  Widget _recentSection(
    BuildContext context,
    List<ScreenshotEntity> all, {
    required bool isPending,
  }) {
    if (all.isEmpty && !isPending) return const SizedBox.shrink();
    return HomeEnter(
      parent: _entrance,
      index: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeGutter(
            child: HomeSectionTitle(
              context.l10n.homeRecent,
              // No route out of a section with nothing in it yet. The
              // destination is the library this screen is still waiting for.
              onSeeAll: isPending
                  ? null
                  : () => widget.onOpenLibrary(LibraryFilter.all),
            ),
          ),
          SizedBox(height: 12.h),
          if (isPending)
            const HomeRecentStrip.pending()
          else
            HomeRecentStrip(screenshots: all.take(12).toList()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<ThemeController>(),
      builder: (context, child) => Scaffold(
        backgroundColor: context.colors.background,
        body: Stack(
          children: [
            // **A brand moment, and the only one on this screen.**
            //
            // A wash of the accent behind the greeting, gone by the time the
            // content starts. The reference this was drawn from puts a full
            // mesh gradient here — red into magenta into orange — and that is
            // the one thing from it that could not come across unchanged: this
            // app's whole argument is that the frame stays quiet because the
            // content is other people's screenshots, and a saturated blob at
            // the top of Home is a temperature applied to every one of them.
            //
            // So the *gesture* is kept and the volume is not. One hue, the
            // app's own, at 9% — enough that the top of the page is clearly
            // lit rather than flat, faint enough that a white card sitting in
            // it still reads as white. It is `IgnorePointer` because it is
            // scenery: the search field underneath must stay tappable.
            // Fades on the same curve as the greeting it sits behind. The wash
            // is the light *on* the header; leaving it lit under a header that
            // has gone reads as a glow with nothing making it.
            AnimatedBuilder(
              animation: _scroll,
              builder: (BuildContext context, Widget? child) => Opacity(
                opacity: (1 - _receded / 0.7).clamp(0.0, 1.0),
                child: child,
              ),
              child: const _HeroWash(),
            ),
            SafeArea(
              bottom: false,
              child: BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
                builder: (context, state) {
                  final ScreenshotsLoadedState? loaded =
                      state is ScreenshotsLoadedState ? state : null;
                  final List<ScreenshotEntity> all =
                      loaded?.screenshots ?? const [];

                  // **"Is there a library" and "do I have the pictures" are
                  // two questions, and this page used to ask only the second.**
                  //
                  // Everything structural below — the pinned search field, the
                  // Recent section, which of two headings Tools gets — was
                  // gated on `all.isNotEmpty`, which is false for the whole of
                  // a cold start no matter how full the library is. So Home
                  // opened in the shape of a fresh install and then rebuilt
                  // itself into the shape of a used one: the search bar
                  // appeared, a 176-pixel strip of recents pushed in, and the
                  // tools heading changed its wording. That is the jolt, and
                  // it is a layout decision made from the wrong fact.
                  //
                  // The summary answers the first question immediately, so the
                  // page can be laid out correctly from the first frame and
                  // only the *contents* of those sections arrive late.
                  final LibrarySummary? summary =
                      state is ScreenshotsLoadingState ? state.summary : null;
                  final bool hasLibrary =
                      all.isNotEmpty || (summary != null && !summary.isEmpty);

                  /// True while the page is laid out for a library whose
                  /// pictures have not arrived — the only state that draws
                  /// placeholders instead of content.
                  final bool isPending = hasLibrary && all.isEmpty;

                  // "Nothing needs you" — no unsorted pile and no intent left
                  // open. The same condition `HomeInbox` collapses on, read
                  // here because it also decides the order of the two blocks
                  // below it.
                  //
                  // **Answered from the summary too**, and it has to be: this
                  // decides the *order* of the two sections below it, so
                  // getting it wrong for the first second means Recent and
                  // Tools swap places once the read lands. The summary holds
                  // exactly the two facts the condition is made of, which is
                  // why it can be asked the same question rather than a
                  // similar one.
                  final bool isClear = loaded != null
                      ? loaded.waitingByIntent.isEmpty &&
                            !all.any((ScreenshotEntity s) => s.isUnsorted)
                      : summary != null &&
                            !summary.isEmpty &&
                            summary.unsorted == 0 &&
                            summary.waiting.isEmpty;

                  // **Slivers, for one reason: the search field pins.**
                  //
                  // Home was a `ListView`, which cannot hold a child in place
                  // while the rest scrolls past it. Everything below is the
                  // same content in the same order — only the search field
                  // behaves differently, and it is the one control on this page
                  // worth being able to reach without scrolling back to the
                  // top.
                  //
                  // It is also what the page was missing to feel like anything
                  // was happening: the greeting sinking away and the content
                  // sliding *under* a bar that stops and stays is the whole
                  // read of depth on this screen.
                  return CustomScrollView(
                    controller: _scroll,
                    slivers: <Widget>[
                      SliverPadding(
                        // The air under the greeting used to be a `SizedBox`
                        // between two list children; with the search field
                        // promoted to a pinned header the gap has to belong to
                        // the greeting, or the date line and the field sit
                        // directly on top of each other.
                        //
                        // The gap *above* it was 10 and read as an accident.
                        // This is the first line of the app and it is centred
                        // with nothing beside it, so it has no neighbour to
                        // take its alignment from — which leaves the distance
                        // to the status bar doing all the work of saying the
                        // page starts here. At 10 it looked pinned to the top
                        // edge rather than placed under it.
                        padding: EdgeInsets.only(top: 34.h, bottom: 16.h),
                        sliver: SliverToBoxAdapter(
                          child: HomeEnter(
                            parent: _entrance,
                            index: 0,
                            child: _parallax(
                              const HomeGutter(child: HomeGreeting()),
                            ),
                          ),
                        ),
                      ),
                      if (hasLibrary)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _SearchHeader(
                            entrance: _entrance,
                            background: context.colors.background,
                            hairline: context.colors.border,
                            extent: _SearchHeader.resolveExtent(context),
                          ),
                        ),
                      SliverList.list(
                        children: <Widget>[
                          if (hasLibrary) SizedBox(height: 12.h),
                          HomeEnter(
                            parent: _entrance,
                            index: 2,
                            child: HomeGutter(
                              child: _headline(context, state, all),
                            ),
                          ),
                          // **The page reads state → action → content, and the
                          // last two swap when there is no state to act on.**
                          //
                          // Home is a hub rather than a second gallery — that is
                          // why the full grid lives in the Library tab — so when
                          // something is waiting on you, Tools comes first: a hub's
                          // job is routing to what you can *do*, and Recent only
                          // repeats what Library already shows one tap away.
                          // Nothing that duplicates another tab should outrank Safe
                          // Share, which is the app's signature feature.
                          //
                          // But with the inbox clear, that ordering spends the best
                          // part of the screen on a one-line "all filed" and buries
                          // the only content Home has behind four tool rows. So the
                          // reward for being organised was a blank page. When
                          // nothing needs you, Recent leads instead — the page
                          // reorders around whether there is work, which is the
                          // one thing that actually changes about it.
                          //
                          // 26 rather than 30: one section break, not two — and
                          // this was two `SizedBox(16)` back to back, which is
                          // where the hole between the inbox and Tools came from.
                          // One number, in one place, so the next person to tune it
                          // can see what they are tuning.
                          SizedBox(height: 26.h),
                          if (isClear) ...[
                            _recentSection(context, all, isPending: isPending),
                            SizedBox(height: 34.h),
                          ],
                          HomeEnter(
                            parent: _entrance,
                            index: 4,
                            child: HomeGutter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  HomeSectionTitle(
                                    hasLibrary
                                        ? context.l10n.homeToolsTitle
                                        : context.l10n.homeToolsTitleEmpty,
                                  ),
                                  SizedBox(height: 4.h),
                                  HomeToolList(
                                    hasLibrary: hasLibrary,
                                    onOpenLibraryForIntent:
                                        widget.onOpenLibraryForIntent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isClear) ...[
                            SizedBox(height: 34.h),
                            _recentSection(context, all, isPending: isPending),
                          ],
                          SizedBox(height: 130.h),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The search field, held at the top once the greeting has scrolled past it.
///
/// **A pinned header is the only thing on this page that does not move**, and
/// that is what makes everything else look like it does. A page where every
/// pixel travels together has no near and no far; one bar that stops, with the
/// content sliding under it, has both.
///
/// It is not decoration either. Search is the fastest route to anything in the
/// library and it was reachable only from the very top of Home — scroll down to
/// the tools and it was gone, so the answer to "where was that screenshot" was
/// *scroll back up first*.
///
/// The delegate carries the two colours rather than reading them from its own
/// context. A `SliverPersistentHeaderDelegate` is compared to its predecessor
/// through [shouldRebuild], and comparing colours is what makes the header
/// repaint the moment the theme flips — a delegate that read the palette inside
/// `build` would go on drawing the old canvas behind the field until something
/// else forced it.
class _SearchHeader extends SliverPersistentHeaderDelegate {
  final Animation<double> entrance;
  final Color background;
  final Color hairline;

  /// The field plus the air under it, resolved against the system text scale.
  ///
  /// **A persistent header declares its height before its child is measured**,
  /// and if the child then comes out *shorter* Flutter throws outright —
  /// `layoutExtent exceeds paintExtent`, which is what the first version of
  /// this did. So the child is stretched to exactly this number rather than
  /// left to size itself, and any slack is background, which is the canvas
  /// colour and therefore invisible.
  ///
  /// It has to be computed rather than a constant because the field's height is
  /// padding plus one line of body text: at a large accessibility text scale a
  /// fixed header would clip the very control it exists to keep on screen.
  /// Clamped at 1.6 — past that the search bar would be eating half the page,
  /// and one line of hint text is allowed to ellipsize before that happens.
  final double extent;

  const _SearchHeader({
    required this.entrance,
    required this.background,
    required this.hairline,
    required this.extent,
  });

  static double resolveExtent(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    return 66.h * scale.clamp(1.0, 1.6);
  }

  /// Pinned, not collapsing: a search box that shrinks as you scroll is a
  /// smaller target for the exact gesture it exists to serve.
  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Opaque only once something is actually behind it. At the top of the page
    // the header sits on the canvas and painting the canvas again changes
    // nothing; the moment content starts passing underneath it has to hide it,
    // and the hairline says where the page now begins.
    final double lift = (shrinkOffset / extent).clamp(0.0, 1.0);
    final double sealed = overlapsContent ? 1.0 : lift;

    return HomeEnter(
      parent: entrance,
      index: 1,
      child: Container(
        height: extent,
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: background.withValues(alpha: sealed),
          border: Border(
            bottom: BorderSide(
              color: hairline.withValues(alpha: sealed),
              width: 0.5,
            ),
          ),
        ),
        child: const HomeGutter(child: HomeSearchField()),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchHeader old) =>
      old.entrance != entrance ||
      old.background != background ||
      old.hairline != hairline ||
      old.extent != extent;
}

class _HeroWash extends StatelessWidget {
  const _HeroWash();

  @override
  Widget build(BuildContext context) {
    // **Light mode only, and this is a measurement rather than a preference.**
    //
    // On near-black the wash banded — visible concentric rings around the
    // greeting, which is what an 8-bit gradient looks like when it is asked to
    // ramp too little colour across too many pixels.
    //
    // The arithmetic, because "pick a different colour" is the intuitive fix
    // and it cannot work. The accent over the dark canvas at 7.5% moves each
    // channel by roughly ten steps out of 255, and it spreads them over about
    // five hundred pixels: one step every fifty pixels, which is far past
    // where an edge becomes visible. Every hue gives the same answer — the
    // banding is set by how *far* the ramp travels, not by where it starts.
    // Getting it smooth would need either ~35% alpha, which is a slab, or
    // dithering, which needs a shader for a decoration nobody asked to be
    // expensive.
    //
    // Light mode has the same arithmetic and does not have the problem,
    // because the eye discriminates far less finely at high luminance than at
    // low — the same ten steps that stripe a near-black page are invisible on
    // paper. It is the reason soft gradients are everywhere on white
    // interfaces and almost nowhere on dark ones.
    //
    // So dark mode gets nothing here, and that is the better answer anyway:
    // the darkest thing on screen is what the screenshots are cut out
    // against, and this file has already argued twice that lifting it toward
    // grey reads as haze rather than as light.
    if (context.colors.isDark) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox(
        height: 400.h,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // **Radial, because the previous linear one had an edge.**
            //
            // A vertical fade across the full width ends on a straight
            // horizontal line, and no alpha low enough to hide that line is
            // high enough to be worth drawing. On near-black it was the worse
            // of the two failures: a flat veil lifting every pixel at the top
            // of the page toward grey is the same "fog" the nav bar was got
            // wrong with three times — a translucent layer *lighter* than what
            // it covers does not read as light falling on the page, it reads
            // as haze in front of it.
            //
            // A radial has no edge anywhere. Centred just above the top of the
            // screen and wider than the screen is tall, it reads as one soft
            // source behind the greeting, and the corners stay exactly canvas
            // — which is what makes it look like light rather than like a
            // rectangle somebody tinted.
            gradient: RadialGradient(
              center: const Alignment(0, -0.85),
              radius: 1.2,
              // Tinting a bright canvas with a *dark* accent takes a lot
              // before anything registers at all: 9% was invisible, which was
              // the complaint that produced these values.
              // **Down from 0.18 / 0.07.** Those values were solved against a
              // page whose top third also carried an accent-bordered card, an
              // accent label, an accent arrow and a solid accent badge — and
              // the wash was the quietest of the five, so it read as fine. With
              // the other four spent down to one arrow, the same wash is now
              // the loudest blue on the screen rather than the faintest, and at
              // full strength it tints the search field sitting in it.
              //
              // A wash is meant to be the thing nobody can point at.
              colors: [
                context.colors.primary.withValues(alpha: 0.12),
                context.colors.primary.withValues(alpha: 0.045),
                context.colors.primary.withValues(alpha: 0),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        ),
      ),
    );
  }
}
