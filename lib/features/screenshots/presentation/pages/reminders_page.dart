import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// `TextDirection` is hidden because `intl` exports one of its own and the
// rail painter needs Flutter's — see [_Rail.centreOf].
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/photo_viewer_route.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/reminder_schedule.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/empty_state.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/screenshot_detail_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_wording.dart';

/// Everything the user asked to be brought back to, drawn as a schedule.
///
/// **The feature had nowhere to be looked at.** A reminder was invisible unless
/// you long-pressed the exact screenshot it was set on, so the app could not
/// answer "what have I asked to be reminded about?" — and finding one meant
/// remembering which picture it was, which is the thing the reminder was
/// supposed to remember for you.
///
/// **Missed ones lead, and that is the reason this screen matters most.** A
/// notification clears itself when it fires. Without a list, the single moment
/// the app asked for attention was also the only one it would ever get: miss it
/// and the reminder was gone with nothing left behind. Here it stays, in the
/// alert colour, until it is dealt with.
///
/// ## What the third pass changed, and why the second one was not enough
///
/// The second pass got the *information* right — bands instead of one "Coming
/// up" heading, a relative time instead of today's date, a way back to the
/// picker, an undoable clear. Everything below is about the fact that a screen
/// can be entirely correct and still look like a placeholder, which is what
/// this one looked like on a phone with two reminders on it:
///
/// 1. **The row was mostly empty.** A 58pt square thumbnail, a chip, and then
///    a third of the width of the phone spent on nothing before the ✕. The
///    thumbnail was square on a screen whose every subject is a *portrait*
///    capture, so the one element that answers "which screenshot is this"
///    was cropped to the shape that answers it worst. It is now a portrait
///    tile, and the space beside it carries what the app actually knows about
///    the picture — see [_ReminderRow].
/// 2. **Two rows and then two thirds of a black screen.** The list ended by
///    stopping. There is now a summary above it ([_Overview]) and a closing
///    line under it, which is the shape the intent screen already had and
///    this one did not.
/// 3. **The bands were headings, not structure.** Four words down the left
///    edge, each one scrolling away the moment you passed it — so halfway
///    down the list nothing on screen said which band you were reading. The
///    headings are pinned now, and every reminder hangs off a continuous
///    spine ([_RailPainter]) that runs from the first band to the last. A
///    schedule is a thing with an axis; a list of cards is not.
/// 4. **Every answer cost a precise tap.** Rescheduling meant hitting a chip,
///    clearing meant hitting a 19pt glyph. Both are now also a swipe — the
///    gesture Mail, Gmail and every task app has trained into the same
///    rows — with the buttons kept exactly where they were, because a gesture
///    nobody can see is not an affordance.
///
/// **What did not change is the vocabulary.** The bands, the relative
/// wording, the reuse of the reminder sheet and [removeRemindersWithUndo] are
/// all the second pass's decisions and all still correct; the reasoning for
/// each is kept where it was rather than restated here.
class RemindersPage extends StatefulWidget {
  /// The page's only source of time.
  ///
  /// A function rather than a moment, because it is read once per frame and
  /// the answers have to keep changing — see [_RemindersPageState._tick]. It
  /// is here at all so a test can stand the clock somewhere definite: half of
  /// what this screen says is a comparison against *now*, and a test that has
  /// to run at the right time of day to mean anything is a test that gets a
  /// `return` at the top of it instead. The reminder picker takes the same
  /// parameter for the same reason.
  final DateTime Function() clock;

  const RemindersPage({super.key, this.clock = DateTime.now});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  /// Rebuilds the list so what it says about the clock stays true.
  ///
  /// **Stateful for one reason, and the relative labels are it.** Every other
  /// screen in this app is a function of the library, which arrives through the
  /// bloc; this one is also a function of *now*. A row reading "in 5 min" is
  /// a claim that expires, and left alone it would still be saying it a
  /// quarter of an hour later — on the screen whose entire purpose is that a
  /// moment does not slip past unnoticed.
  ///
  /// It moves rows between bands as well as rewording them, because
  /// [reminderBandFor] is read in `build` from the same clock: a reminder that
  /// comes due while somebody is looking at this page crosses into *Missed* by
  /// itself, which is exactly what the band is for.
  ///
  /// Thirty seconds is the coarsest tick that can still keep a label counted in
  /// whole minutes honest — at a minute, "in 5 min" and "in 4 min" would each
  /// be up to a minute stale, which is the whole error being fixed. The work
  /// per tick is a `setState` over a list of a handful of rows.
  Timer? _tick;

  /// When this list was first put on screen, for [EntranceStagger].
  ///
  /// Stamped once rather than read per row: the stagger is a property of the
  /// *list arriving*, and a row built later — by the tick, by a reload, by an
  /// undo — has to appear instantly or the screen looks like it is
  /// re-loading every thirty seconds.
  final DateTime _since = DateTime.now();

  /// Reminders that have been cleared here and whose absence the library has
  /// not caught up with yet.
  ///
  /// **A clear used to be a request with no visible answer.** Every route out
  /// of this screen — the ✕, the band's *Clear all*, and now a swipe — writes
  /// through [removeRemindersWithUndo], which persists the change and then
  /// asks the bloc to re-read the library. That read is a round trip to the
  /// photo store, so for a few hundred milliseconds the row the user just
  /// removed was still sitting there, unchanged, as though the tap had missed.
  /// On a swipe it is worse than unresponsive: the card slides back under the
  /// finger and then disappears on its own a moment later, which reads as the
  /// gesture having failed and something else having gone wrong.
  ///
  /// So the row leaves at the moment it is asked to, and the library catching
  /// up is what makes it permanent rather than what makes it visible.
  ///
  /// **It empties itself, which is what makes an undo work.** An id is dropped
  /// the moment the library stops reporting a reminder for it — see [build] —
  /// so the sequence is: hidden while still present, forgotten once genuinely
  /// gone, and therefore *shown again* if [removeRemindersWithUndo] puts it
  /// back. Nothing here has to know that an undo happened.
  final Set<String> _clearing = <String>{};

  /// Whether the swipe legend is still owed to this user.
  ///
  /// Read once, when the page opens, rather than watched. The only thing that
  /// can change the answer is a swipe on this very screen, and that path calls
  /// [_learnSwipe] directly — subscribing to the preference as well would be a
  /// second route to the same `setState` and a listener to remember to remove.
  late bool _teaching = !sl<AppPreferences>().hasSwipedReminder;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (Timer _) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenshotsBloc, ScreenshotsState>(
      builder: (BuildContext context, ScreenshotsState state) {
        // An unread library is not an empty one — same reasoning as IntentPage.
        final Widget? blocked = LibraryUnavailable.maybeOf(state);
        final ScreenshotsLoadedState? loaded = state is ScreenshotsLoadedState
            ? state
            : null;
        final List<ScreenshotEntity> reported =
            loaded?.reminders ?? const <ScreenshotEntity>[];

        // See [_clearing]: an id survives only while the library still claims
        // a reminder for it. Mutated in `build` deliberately and safely — it
        // feeds nothing but the filter on the next line, and a `setState` here
        // would be a rebuild asking for a rebuild.
        if (_clearing.isNotEmpty) {
          final Set<String> live = <String>{
            for (final ScreenshotEntity item in reported) item.id,
          };
          _clearing.removeWhere((String id) => !live.contains(id));
        }
        final List<ScreenshotEntity> all = _clearing.isEmpty
            ? reported
            : <ScreenshotEntity>[
                for (final ScreenshotEntity item in reported)
                  if (!_clearing.contains(item.id)) item,
              ];

        // **Banded here rather than on the state, and read fresh every build.**
        //
        // Which side of "now" a reminder falls on is a fact about the clock,
        // not about the library — computed here it is as old as this frame
        // instead of as old as the last load. The bloc hands them over
        // soonest-first, which is exactly the order the bands want, so nothing
        // is sorted again.
        //
        // **One read, handed down.** The rows used to call `DateTime.now()`
        // again for themselves, which gave one frame two clocks a few
        // microseconds apart. Almost always harmless and not always: a
        // reminder falling due between the two reads is grouped under *Today*
        // by the first and worded by the second as though it had already gone.
        // The relative labels made that visible — "1 min ago", under "Today" —
        // where a bare clock time had hidden it.
        final DateTime now = widget.clock();
        final List<ReminderRun<ScreenshotEntity>> runs =
            groupBySchedule<ScreenshotEntity>(
              all,
              dueAt: (ScreenshotEntity item) => item.remindAt!,
              now: now,
            );

        return Scaffold(
          backgroundColor: context.colors.background,
          // **A compact bar, because this is a pushed page.**
          //
          // The large collapsing title belongs to the two root tabs — Library
          // and Home own their screens. `IntentPage` is this screen's exact
          // sibling: reached in one tap from the same block on Home, holding
          // the same kind of list, and it uses a plain `AppBar` with the title
          // beside the back arrow. Giving this one a third header shape would
          // be drift dressed up as polish.
          appBar: AppBar(
            backgroundColor: context.colors.background,
            elevation: 0,
            iconTheme: IconThemeData(color: context.colors.textPrimary),
            title: Text(
              context.l10n.remindersTitle,
              style: context.text.titleLarge,
            ),
          ),
          body: blocked != null
              ? SafeArea(child: blocked)
              : CustomScrollView(
                  slivers: <Widget>[
                    if (all.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: context.l10n.remindersNoneTitle,
                          message: context.l10n.remindersNoneBody,
                        ),
                      )
                    else ...<Widget>[
                      SliverToBoxAdapter(
                        child: _Overview(reminders: all, now: now),
                      ),
                      // Under the summary rather than over it: the first thing
                      // this page owes anybody is what is in it, and an
                      // instruction above that is a tutorial standing in front
                      // of the content. It still sits directly above the first
                      // row, which is the thing it is about.
                      if (_teaching)
                        SliverToBoxAdapter(
                          child: _SwipeLegend(onDismiss: _learnSwipe),
                        ),
                      ..._bands(context, runs, now),
                      SliverToBoxAdapter(child: _ListEnd(count: all.length)),
                    ],
                    // Clears the floating tab bar. The list is the only thing
                    // on this page that scrolls, so the allowance has to be
                    // inside it.
                    SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                  ],
                ),
        );
      },
    );
  }

  /// One pinned heading and one run of rows per band, threaded onto one spine.
  ///
  /// **The headings stack, and that is the arrangement that was chosen.**
  /// Pinned headers that are not wrapped in a `SliverMainAxisGroup` pin
  /// against the leading edge of the *viewport* rather than of their own
  /// section, so scrolling into *Later* leaves *Missed*, *Today* and
  /// *Tomorrow* held one under the other at the top of the phone.
  ///
  /// It was grouped for one revision, which pushed each heading out as the
  /// next arrived, and the stack was preferred and put back. It reads as an
  /// index of the bands you have gone past — with the spine running down
  /// through all of them, which is the one thing the pushed-out version
  /// could not show — and the cost is bounded, because there are only ever
  /// five bands and the deepest possible stack is five headings.
  ///
  /// The indices matter twice and for different reasons. [at] counts every row
  /// on the page so the entrance staggers as **one** cascade rather than
  /// restarting under each heading — four bands each animating their first
  /// three rows reads as four separate lists loading. The first-and-last flags
  /// are what cap the spine: it starts at the first band's node and stops at
  /// the last row's, instead of running off both ends of the content.
  List<Widget> _bands(
    BuildContext context,
    List<ReminderRun<ScreenshotEntity>> runs,
    DateTime now,
  ) {
    final List<Widget> slivers = <Widget>[];
    int at = 0;

    for (int r = 0; r < runs.length; r++) {
      final ReminderRun<ScreenshotEntity> run = runs[r];
      final bool lastRun = r == runs.length - 1;

      final int start = at;
      at += run.items.length;

      // Flat siblings rather than a `SliverMainAxisGroup`, which is what
      // makes the headings accumulate — see this method's own doc.
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _BandHeaderDelegate(
            // Keyed so a heading that is pinned while the one behind it
            // arrives swaps identity outright rather than morphing its text
            // and its pulse into the next band's.
            child: KeyedSubtree(
              key: ValueKey<ReminderBand>(run.band),
              child: _BandHeading(
                band: run.band,
                count: run.items.length,
                items: run.items,
                first: r == 0,
                onClear: _clear,
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList.builder(
          itemCount: run.items.length,
          itemBuilder: (BuildContext context, int i) => EntranceStagger(
            index: start + i,
            since: _since,
            child: _ReminderRow(
              key: ValueKey<String>(run.items[i].id),
              item: run.items[i],
              band: run.band,
              now: now,
              last: lastRun && i == run.items.length - 1,
              onClear: _clear,
              onSwiped: _learnSwipe,
              // The first row on the page, and only while the lesson is owed.
              // One demonstration is a demonstration; eight at once is the
              // list shaking.
              nudge: _teaching && start + i == 0,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  /// Takes reminders off, and offers them back — the one route for all three
  /// controls that can do it.
  ///
  /// The hiding is [_clearing]'s business and the rest is
  /// [removeRemindersWithUndo]'s; this exists so the ✕, the swipe and the
  /// band's *Clear all* cannot drift apart, which is the failure the shared
  /// helper was written to prevent one level down.
  /// Records that the swipe has been understood, and retires the legend.
  ///
  /// Called from both directions and from the legend's own close button,
  /// because all three mean the same thing: this person does not need to be
  /// told again. The write is fire-and-forget — losing it costs one more
  /// sighting of a card that is already cheap, and awaiting it would put a
  /// disk round trip in the middle of a gesture.
  void _learnSwipe() {
    if (!_teaching) return;
    setState(() => _teaching = false);
    sl<AppPreferences>().markReminderSwiped();
  }

  Future<void> _clear(List<ScreenshotEntity> items) async {
    if (items.isEmpty) return;

    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    setState(() {
      for (final ScreenshotEntity item in items) {
        _clearing.add(item.id);
      }
    });

    await removeRemindersWithUndo(context, <({String assetId, DateTime was})>[
      for (final ScreenshotEntity item in items)
        (assetId: item.id, was: item.remindAt!),
    ], onChanged: () => bloc.add(LoadScreenshotsEvent()));
  }
}

// ---------------------------------------------------------------- the spine

/// The measurements of the timeline running down the leading edge.
///
/// **Gathered rather than inlined because three widgets have to agree about
/// them exactly.** The heading, the rows and the closing line each paint their
/// own piece of one continuous line: they are separate slivers, so nothing
/// draws the spine as a whole and a hairline that is 1.5 wide in one of them
/// and 2 in another is a visible seam at every junction.
abstract class _Rail {
  _Rail._();

  /// The column the line and its nodes live in, before the card starts.
  ///
  /// Wide enough to hold the largest node with air around it, narrow enough
  /// that it reads as a margin rather than as a first column of content.
  static double get gutter => 28.w;

  /// A hairline, and deliberately not a rule.
  ///
  /// The spine's job is to say *these belong to one sequence*; it is not a
  /// piece of content. At 2 and above it started reading as a border on the
  /// page, which is what a divider does and this is not one.
  static const double line = 1.5;

  /// The disc — solid or open — marking one reminder.
  static double get node => 8.w;

  /// How thick an open node's ring is.
  ///
  /// A third of the node. Thinner and a hollow ring stops reading as the same
  /// object as a filled one and starts reading as a smaller, fainter dot,
  /// which is the distinction this is meant to avoid making.
  static double get stroke => node / 3;

  /// The gap punched around a node so the line does not run through it.
  ///
  /// Painted in the page's own background rather than left as a break in the
  /// stroke, because the pinned heading slides *over* the rows: a break would
  /// have to be in the right place in two slivers at once, and a disc that
  /// covers what is behind it is in the right place by construction.
  static double get halo => 3.w;

  /// Where the spine sits horizontally, given the writing direction.
  ///
  /// The rail is laid out by a `Row`, which already mirrors itself in Arabic;
  /// the painter works in raw canvas coordinates and does not, so the one
  /// place the direction has to be applied by hand is here.
  static double centreOf(Size size, TextDirection direction) =>
      direction == TextDirection.rtl ? size.width - gutter / 2 : gutter / 2;
}

/// One segment of the spine: a vertical hairline and, usually, a node on it.
///
/// **Painted per element rather than once behind the list**, because a
/// `CustomScrollView` has no single canvas the whole spine could be drawn on —
/// each band is its own sliver and each row is its own box. Every segment is
/// therefore exactly as tall as the thing it belongs to *including its bottom
/// gap*, which is what makes the joins invisible: the line leaves the bottom
/// edge of one row at the same x it enters the top of the next.
class _RailPainter extends CustomPainter {
  /// The tint of this band, carried by the node alone.
  ///
  /// **The line stays neutral in every band and that is the point of it.** A
  /// spine that changed colour four times down one screen would be four
  /// spines; colouring only the nodes lets *missed* stay the one thing on the
  /// page wearing the alert colour, which is the whole reason the band exists.
  final Color tint;

  final Color lineColor;

  /// What the halo is painted in — the page behind the spine.
  final Color background;

  /// Where the node sits, or null for a segment that is only line.
  final double? nodeAt;

  /// Whether the line runs to the top and bottom edges of this segment.
  ///
  /// False at the two ends of the whole list, where the line stops at the
  /// node instead of running off into the summary above or the closing line
  /// below. A spine with two cut ends reads as a fragment of something longer;
  /// one that starts and stops on a node reads as complete.
  final bool openTop;
  final bool openBottom;

  /// Whether the node is a solid disc rather than an open ring.
  ///
  /// **The half of "missed" that is not a colour, and the reason the colour is
  /// allowed to be red.** A hue against two greys is a clear enough ladder for
  /// most people and no ladder at all for the one in twelve men who cannot
  /// separate those hues — nor in a screenshot somebody has desaturated, nor
  /// on a phone whose accent has been set to the same red. Solid against
  /// hollow is a difference in *shape*, which survives all three, and it is
  /// the vocabulary a timeline already has: a filled node is a point that has
  /// happened, an open one is a point still ahead.
  ///
  /// See [_bandTint] for the revision this arrived in and why it outlived the
  /// colour change that brought it.
  final bool filled;

  /// How far through a breath the missed band's node is, 0 to 1.
  ///
  /// Zero for every other band and whenever the reader has asked for less
  /// motion — see [_BandHeading].
  final double pulse;

  final TextDirection direction;

  const _RailPainter({
    required this.tint,
    required this.lineColor,
    required this.background,
    required this.nodeAt,
    required this.openTop,
    required this.openBottom,
    required this.direction,
    this.filled = false,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double x = _Rail.centreOf(size, direction);
    final double y = nodeAt ?? size.height / 2;

    canvas.drawLine(
      Offset(x, openTop ? 0 : y),
      Offset(x, openBottom ? size.height : y),
      Paint()
        ..color = lineColor
        ..strokeWidth = _Rail.line,
    );

    if (nodeAt == null) return;

    // The breath, outside the halo so the node itself never changes size —
    // a marker that grows and shrinks is a marker whose position is hard to
    // read, and the position is what a timeline is for.
    if (pulse > 0) {
      canvas.drawCircle(
        Offset(x, y),
        _Rail.node / 2 + _Rail.halo + _Rail.node * pulse,
        Paint()..color = tint.withValues(alpha: 0.22 * (1 - pulse)),
      );
    }

    canvas.drawCircle(
      Offset(x, y),
      _Rail.node / 2 + _Rail.halo,
      Paint()..color = background,
    );

    if (filled) {
      canvas.drawCircle(Offset(x, y), _Rail.node / 2, Paint()..color = tint);
      return;
    }

    // Struck on the mid-line of the stroke, so an open node has exactly the
    // outer diameter of a solid one: the two read as the same object in two
    // states rather than as two sizes of dot.
    canvas.drawCircle(
      Offset(x, y),
      (_Rail.node - _Rail.stroke) / 2,
      Paint()
        ..color = tint
        ..style = PaintingStyle.stroke
        ..strokeWidth = _Rail.stroke,
    );
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.filled != filled ||
      old.tint != tint ||
      old.lineColor != lineColor ||
      old.background != background ||
      old.nodeAt != nodeAt ||
      old.openTop != openTop ||
      old.openBottom != openBottom ||
      old.pulse != pulse ||
      old.direction != direction;
}

/// The tint a band's nodes are drawn in.
///
/// Three values for five bands, because the question the colour answers is not
/// "which band" but "how much does this want from you": one needs you, one is
/// today, and the rest are the calendar.
///
/// ## Missed is red, and it was amber for one revision
///
/// The objection that produced the amber was real and is worth keeping
/// written down, because it will come back the next time somebody touches
/// this: **Shoto lets the accent be chosen**, and on a phone set to a warm
/// tint the app's ordinary voice sits a shade away from [AppPalette.alert].
/// Nothing on the band stood out, because everything already looked like it.
///
/// Amber was the principled answer — `app_colors.dart` hands the hues out by
/// meaning, and "needs attention, nothing lost" is amber's own definition
/// while red is reserved for the destructive. It was tried on a real phone in
/// both modes and it lost on how it looked: gold reads as a caution label
/// rather than as *you missed this*, and in light mode `#89670F` comes out
/// olive.
///
/// **What makes going back to red safe is that the colour is no longer the
/// only signal.** The amber revision also introduced two hue-free ones, and
/// those stayed: see [_RailPainter.filled], where a missed node is a solid
/// disc and every other node is an open ring, and the half-pixel of extra
/// border weight on a missed card. Desaturate this screen, or set the accent
/// to the same red, and a missed row is still the one with a filled marker
/// and an edge. Colour is now the loudest of three signals rather than the
/// only one, which is the state it should have been in from the start.
///
/// The two calendar steps stay on the neutral ramp — `#9E9E9E` against
/// `#727272` in dark — because a band that wants nothing should not be
/// wearing a colour at all. Neither can be reached by a tint: `AppPalette`
/// applies the user's choice to `marker` and `primaryVariant` only.
Color _bandTint(BuildContext context, ReminderBand band) => switch (band) {
  ReminderBand.missed => context.colors.error,
  ReminderBand.today => context.colors.textSecondary,
  _ => context.colors.textDisabled,
};

/// Whether a band's nodes are drawn solid.
///
/// True for exactly one band, which is what makes it a signal. See
/// [_RailPainter.filled].
bool _bandFilled(ReminderBand band) => band == ReminderBand.missed;

// -------------------------------------------------------------- the summary

/// What the whole list adds up to, before any of it is read.
///
/// **The screen used to open on a heading.** Two rows under the word *Missed*
/// and then the rest of the phone in black — no answer to "is this bad", no
/// answer to "when does the next one land", and nothing to look at while
/// deciding whether to deal with any of it now. `IntentPage` puts a summary at
/// the top of its scroll for the same reason and this follows it exactly,
/// including the segmented meter: the counts here are small, and a continuous
/// bar expressing "two of five" can only ever be empty, half or full.
///
/// **It says what Home says, in an instrument Home has not got.** The row that
/// opens this page already reads "2 missed reminders · Next tomorrow, 9:00 AM",
/// and repeating the sentence at the top of the screen it opened would be a
/// summary of a summary. What it adds is the *shape* of the list — how much of
/// it is a problem, at a glance, without counting rows — and, inside the hour,
/// a countdown that keeps moving while it is being looked at.
///
/// Scrolls away with the content rather than pinning: it is an overview of the
/// list, and an overview that follows you down the list is a thing in the way.
class _Overview extends StatelessWidget {
  final List<ScreenshotEntity> reminders;
  final DateTime now;

  const _Overview({required this.reminders, required this.now});

  /// Past this the meter stops being countable and becomes a texture.
  ///
  /// The same threshold, for the same reason, as the intent screen's progress:
  /// twelve segments across a phone are still objects, forty are a dashed
  /// line. Above it the meter falls back to a proportional track.
  static const int _maxSegments = 12;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    final int missed = reminders
        .where((ScreenshotEntity s) => !s.remindAt!.isAfter(now))
        .length;
    final ScreenshotEntity? next = reminders
        .where((ScreenshotEntity s) => s.remindAt!.isAfter(now))
        .firstOrNull;

    // Alert only when something was actually missed — the rule the Home row
    // states at length. A reminder that is merely coming up is not a problem,
    // and colouring it like one is how the alert colour stops meaning alert.
    final bool alerting = missed > 0;
    // The alert colour when something needs you, the app's own accent when
    // nothing does — and the two can never be on screen together, because
    // `alerting` is exactly the condition that decides between them.
    final Color tint = alerting ? colors.error : colors.primary;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 4.h),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: alerting ? tint.withValues(alpha: 0.28) : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                // A tinted disc rather than a bare glyph. This is the one
                // block on the page that is not a reminder, and the badge is
                // what stops it reading as an unusually wide first row.
                Container(
                  width: 32.w,
                  height: 32.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alerting
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 17.sp,
                    color: tint,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        alerting
                            ? context.l10n.remindersMissedTitle(missed)
                            : context.l10n.remindersCount(reminders.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium.asMedium.copyWith(
                          color: alerting ? tint : colors.textPrimary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      // **Said whenever there is one, missed or not.** The
                      // condition is "is anything still coming", not "is
                      // everything fine". With every reminder missed there is
                      // genuinely nothing next, and the block goes back to one
                      // line rather than reserving space for a sentence it has
                      // no answer for.
                      if (next != null) ...<Widget>[
                        SizedBox(height: 3.h),
                        Text(
                          nextReminderLine(context, next.remindAt!, now: now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            SizedBox(
              height: 5.h,
              child: reminders.length <= _maxSegments
                  ? _segments(context)
                  : _track(context, missed),
            ),
          ],
        ),
      ),
    );
  }

  /// One block per reminder, each one in its own band's colour.
  ///
  /// **Read left to right in the order the list is in, so the meter is a map
  /// of the page under it** rather than a statistic about it: the run of red at
  /// the start is the run of red rows below, and it is drawn in the colours
  /// those rows' nodes are drawn in — [_bandTint], the same function the spine
  /// uses, so the two cannot disagree about what a colour means.
  ///
  /// **Banded rather than missed-versus-rest, because of the state this screen
  /// is in most of the time.** With nothing missed, a bar of identical blocks
  /// is a count the sentence above it has already given — decoration, on a
  /// page that has no other. Coloured by band it still says something the
  /// words do not: one due today and three next week is a different week from
  /// four due today, and that is legible here without reading a single row.
  Widget _segments(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < reminders.length; i++) ...<Widget>[
          if (i > 0) SizedBox(width: 4.w),
          Expanded(
            // `Container` rather than `DecoratedBox`, which is not a
            // cosmetic preference: a childless `DecoratedBox` takes the
            // *smallest* size its constraints allow, and the constraint down
            // this axis is loose, so the whole meter collapsed to nothing and
            // left the summary card with a third of itself empty.
            child: Container(
              decoration: BoxDecoration(
                color: _segmentTint(context, reminders[i]),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// [_bandTint], held back on every band but the one that matters.
  ///
  /// **Area, not hue.** A node is eight pixels across and a segment is forty
  /// by five — the same grey that reads as a quiet marker on the spine covers
  /// roughly eight times as much of the summary card, and at full strength
  /// seven neutral blocks visibly outweighed the single amber one they were
  /// supposed to be the background for. The meter's whole sentence is "this
  /// much of it needs you", and it was being read the other way round.
  ///
  /// Held back rather than recoloured, so the meter and the spine still name
  /// the bands with the same three values.
  Color _segmentTint(BuildContext context, ScreenshotEntity item) {
    final ReminderBand band = reminderBandFor(item.remindAt!, now: now);
    final Color tint = _bandTint(context, band);
    return band == ReminderBand.missed ? tint : tint.withValues(alpha: 0.5);
  }

  /// The proportional fallback, for a list too long to count in blocks.
  Widget _track(BuildContext context, int missed) {
    final AppPalette colors = context.colors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ColoredBox(
              color: colors.textDisabled.withValues(alpha: 0.5),
            ),
          ),
          FractionallySizedBox(
            widthFactor: (missed / reminders.length).clamp(0.0, 1.0),
            alignment: AlignmentDirectional.centerStart,
            child: ColoredBox(color: colors.error),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- the heading

/// Holds a band heading at the top of the viewport while its rows go past.
///
/// **Pinned because the band is the answer, not the decoration.** Every row on
/// this page says a time, and what that time *means* — overdue, later today,
/// some Thursday — is carried entirely by the heading above it. Unpinned, that
/// heading is gone after two rows and the reader is left doing the arithmetic
/// the bands were added to spare them. The library grid pins its date headings
/// for the same reason and through the same delegate shape.
class _BandHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _BandHeaderDelegate({required this.child});

  /// Declared rather than measured — a pinned header has to state its height
  /// before it is laid out, so the number lives here and the heading is built
  /// to fit it.
  ///
  /// It is the *whole* gap between one band's last card and the next band's
  /// first, since the heading carries no margins of its own: at 46 that gap
  /// was three times what the cards inside a band are apart, which made each
  /// band look like a separate list rather than a stretch of one.
  static double get extent => 36.h;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_BandHeaderDelegate old) => old.child != child;
}

/// One band's heading: a node on the spine, the word, and how many are under
/// it.
///
/// **The count is on the heading rather than on the rows**, which is what let
/// the rows drop their second line back to something useful. "Missed · 3" says
/// everything the three repetitions of the word "Missed" underneath it used to.
///
/// Opaque, because it is pinned and cards slide underneath it. The spine is
/// painted *over* that background rather than left to show through, so the one
/// line running down the page is not interrupted four times by its own
/// headings.
class _BandHeading extends StatefulWidget {
  final ReminderBand band;
  final int count;

  /// The reminders under this heading, so the band can be emptied at once.
  final List<ScreenshotEntity> items;

  /// Whether this is the topmost band, where the spine begins.
  final bool first;

  final Future<void> Function(List<ScreenshotEntity>) onClear;

  const _BandHeading({
    required this.band,
    required this.count,
    required this.items,
    required this.first,
    required this.onClear,
  });

  @override
  State<_BandHeading> createState() => _BandHeadingState();
}

class _BandHeadingState extends State<_BandHeading>
    with SingleTickerProviderStateMixin {
  /// The missed band's breath.
  ///
  /// **One pulsing thing on the page, and it is the heading rather than the
  /// rows.** A node breathing on every missed row is four animations running
  /// forever on a list somebody is trying to read, and it repeats an alarm the
  /// reader has already taken in — the movement stops being a signal by the
  /// second row. On the heading it says the one thing worth repeating, which
  /// is *this band is still not dealt with*, and it stays visible while the
  /// rows scroll past underneath because the heading is pinned.
  ///
  /// **Slow and low, on purpose.** Two seconds a cycle with the halo never
  /// exceeding a fifth of an alpha: at the speeds the rest of the app moves at
  /// — a 160ms press, a 220ms entrance — anything quicker here would read as a
  /// notification arriving over and over. It is a state, not an event.
  ///
  /// It never runs for any other band, and never when the reader has asked the
  /// system for less motion: a repeating animation is the first thing that
  /// setting exists to stop.
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  bool get _alert => widget.band == ReminderBand.missed;

  /// Whether the breath should be running at all.
  ///
  /// **The reduced-motion check has to stop the clock, not just the paint.**
  /// Leaving the controller repeating and drawing nothing would still rebuild
  /// this heading sixty times a second forever — invisible, and the reason a
  /// widget test on this page could never settle.
  bool get _breathing => _alert && !AppMotion.reduced(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(_BandHeading old) {
    super.didUpdateWidget(old);
    // A band can change identity under a pinned header without the element
    // being rebuilt from scratch — see the `KeyedSubtree` at the call site for
    // the case where it cannot. This is the cheap half of the same guarantee.
    _syncBreath();
  }

  void _syncBreath() {
    if (_breathing && !_breath.isAnimating) {
      _breath.repeat();
    } else if (!_breathing && _breath.isAnimating) {
      _breath
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color tint = _alert ? colors.error : colors.textSecondary;

    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 0),
        child: AnimatedBuilder(
          animation: _breath,
          builder: (BuildContext context, Widget? child) => CustomPaint(
            painter: _RailPainter(
              tint: _bandTint(context, widget.band),
              filled: _bandFilled(widget.band),
              lineColor: colors.border,
              background: colors.background,
              // On the word, because the word is what it marks. The label is
              // centred in the header by the `Row` below, so the node reads as
              // belonging to the heading rather than to the gap under it.
              nodeAt: _BandHeaderDelegate.extent / 2,
              openTop: !widget.first,
              openBottom: true,
              // Eased rather than linear so the ping leaves quickly and
              // settles, which is what a ripple does; a linear ring expands at
              // a constant rate and reads as a loading spinner.
              pulse: _breathing
                  ? AppMotion.standard.transform(_breath.value)
                  : 0,
              direction: Directionality.of(context),
            ),
            child: child,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(width: _Rail.gutter),
              Text(
                _label(context),
                style: context.text.bodySmall.asMedium.copyWith(color: tint),
              ),
              // **Only once there is more than one.** A "1" beside a heading
              // with a single row under it is a number nobody needed: the row
              // is right there, and counting to one is not a service. It earns
              // its place the moment the band is long enough that the answer is
              // not already on screen.
              if (widget.count > 1) ...<Widget>[
                SizedBox(width: 7.w),
                Text(
                  '${widget.count}',
                  style: context.text.caption.copyWith(
                    color: colors.textDisabled,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
              // **Only on the band that accumulates, and only once it has.**
              //
              // Missed reminders are the one kind that pile up: they stay until
              // something removes them, which is the point of the band, and four
              // of them dealt with is four separate taps on four separate ✕s.
              // Nothing else here needs it — an upcoming reminder has not
              // happened yet, and "clear everything I am waiting for" is not a
              // thing anybody means to do in one tap.
              //
              // Withheld at one, where it would be a second way to do exactly
              // what the ✕ beside it already does.
              if (_alert && widget.count > 1) ...<Widget>[
                const Spacer(),
                _ClearBandButton(items: widget.items, onClear: widget.onClear),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context) => switch (widget.band) {
    ReminderBand.missed => context.l10n.remindersMissed,
    // Reused from the dated headings the library already draws, rather than
    // translated a second time: "Today" is the same word about the same day.
    ReminderBand.today => context.l10n.dateToday,
    ReminderBand.tomorrow => context.l10n.dateTomorrow,
    ReminderBand.thisWeek => context.l10n.remindersThisWeek,
    ReminderBand.later => context.l10n.remindersLater,
  };
}

/// Empties the missed band in one tap.
///
/// **A word, not a glyph, and this is the case that earns one.** The row's ✕ is
/// read instantly because it sits on the thing it removes; a control that
/// removes *several* things has no such anchor, and a bin or a broom on a
/// heading is a guess about scope — everything on screen, everything in the
/// band, everything ever? The word says which.
///
/// Quiet on purpose: no fill, no border, the label at caption weight in the
/// alert colour it belongs to. It sits on a heading, not in the content, and a
/// filled button there would outweigh every reminder underneath it.
class _ClearBandButton extends StatelessWidget {
  final List<ScreenshotEntity> items;
  final Future<void> Function(List<ScreenshotEntity>) onClear;

  const _ClearBandButton({required this.items, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.94,
      onTap: () => onClear(items),
      child: Padding(
        // Carries the target out to a thumb's width without the words growing.
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 5.h),
        child: Text(
          context.l10n.remindersClearMissed,
          style: context.text.caption.asMedium.copyWith(
            color: context.colors.error,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ the row

/// One reminder: where it sits on the spine, the picture, when it is due, what
/// it was for, and three ways to deal with it.
///
/// **Tapping the row opens the screenshot**, because that is what the reminder
/// was asking you to do. The other two answers are *not now* (which reopens the
/// reminder sheet) and *never mind* (which clears it, and can be taken back),
/// and each of them is reachable twice: as a control on the card, and as a
/// swipe across it.
///
/// ## What the card carries, and why it was nearly empty before
///
/// The row's whole task is "which screenshot is this, and when did I want it".
/// It used to answer with a 58pt **square** thumbnail and a time, on a screen
/// where every subject is a portrait capture — so the picture was cropped to
/// the shape that identifies it worst, and the two thirds of the row beside it
/// held nothing at all.
///
/// Three things fixed that, and none of them is new information:
///
/// * **A portrait tile.** Taller than it is wide, top-aligned, because a
///   screenshot identifies itself in its first fifth — the status bar, the
///   app's header, the sender, the subject. `AssetThumbnailImage` had been
///   defaulting to exactly this crop already; the row was the thing forcing it
///   square.
/// * **The intent, when there is one** — the verb the user chose when they
///   saved it. It was already here and it is still the single most useful line
///   on the card.
/// * **When the picture was taken**, for the great majority of screenshots
///   that carry no intent at all. Under the old layout those rows had a time
///   and nothing else; this is the app's one remaining fact about them, and
///   "the one from Tuesday" is how people actually find a screenshot.
class _ReminderRow extends StatelessWidget {
  final ScreenshotEntity item;
  final ReminderBand band;

  /// The moment the whole frame is measured against — the same one the bands
  /// were cut with, so a row can never word itself out of the band it is in.
  final DateTime now;

  /// Whether this is the final row on the page, where the spine stops.
  final bool last;

  final Future<void> Function(List<ScreenshotEntity>) onClear;

  /// Told once, the first time this row is dragged either way — see
  /// [_RemindersPageState._learnSwipe].
  final VoidCallback onSwiped;

  /// Whether this row performs the swipe once, to show what it does.
  ///
  /// True for the first row on the page and only while the lesson is still
  /// owed — see [_SwipeNudge].
  final bool nudge;

  const _ReminderRow({
    super.key,
    required this.item,
    required this.band,
    required this.now,
    required this.last,
    required this.onClear,
    required this.onSwiped,
    required this.nudge,
  });

  bool get _isMissed => band == ReminderBand.missed;

  /// The picture's tile. Portrait, because its subject is.
  ///
  /// **Three to four, and the height is the number that was tuned.** It went
  /// out at 78 and that was measurably too tall: the words beside it come to
  /// about 58 logical pixels, so the card was carrying twenty pixels of slack
  /// it had no use for, on the screen whose complaint was that it looked
  /// empty. Shortened until the two columns are close to the same height, the
  /// whitespace goes back to being padding.
  ///
  /// It is not shortened further, and the picture is why. Every row on this
  /// page asks "which screenshot is this", and the crop is already only the
  /// top fifth of a tall capture — below about 66 the app header and the
  /// sender's name in it stop being legible, which is the whole reason the
  /// tile is here.
  static double get _thumbWidth => 58.w;
  static double get _thumbHeight => 68.h;

  /// The air under one card, and therefore the length of spine between two
  /// nodes.
  static double get _gap => 12.h;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final DateTime at = item.remindAt!;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 0),
      child: CustomPaint(
        painter: _RailPainter(
          tint: _bandTint(context, band),
          filled: _bandFilled(band),
          lineColor: colors.border,
          background: colors.background,
          // Centred on the card rather than on the whole slot, so the node
          // lines up with the thing it marks and not with the gap under it.
          nodeAt: (_thumbHeight + 20.w) / 2,
          openTop: true,
          openBottom: !last,
          direction: Directionality.of(context),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: _gap),
          child: Row(
            children: <Widget>[
              SizedBox(width: _Rail.gutter),
              Expanded(
                child: ClipRRect(
                  // Clips the swipe backgrounds to the card's own shape. A
                  // square-cornered colour appearing behind a rounded card is
                  // the detail that makes a swipe look bolted on.
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  // Inside the clip, so the surface the demonstration uncovers
                  // is cut to the card's own corners exactly as the real one
                  // is. Outside the `Dismissible`, because it moves the whole
                  // swipeable rather than competing with it for the drag.
                  child: _SwipeNudge(
                    active: nudge,
                    child: _Swipeable(
                      id: item.id,
                      onReschedule: () => _reschedule(context),
                      onClear: () => onClear(<ScreenshotEntity>[item]),
                      onSwiped: onSwiped,
                      child: _Card(
                        item: item,
                        isMissed: _isMissed,
                        when: _when(context, at),
                        thumbWidth: _thumbWidth,
                        thumbHeight: _thumbHeight,
                        onOpen: () => _open(context),
                        onReschedule: () => _reschedule(context),
                        onClear: () => onClear(<ScreenshotEntity>[item]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// When it is due, in the terms that matter at that distance.
  ///
  /// **The heading carries the day, so the row does not repeat it.** Under
  /// *Today* and *Tomorrow* the date is already known and only the clock time
  /// is news; further out the row has to say which day it means. Each format
  /// below is the shortest that is still unambiguous where it is used.
  ///
  /// ## Near the present, a distance rather than a clock
  ///
  /// Two rows were failing at that, and in opposite directions.
  ///
  /// **Under *Missed*, every row printed today's date.** "Tue, Aug 18, 11:17
  /// AM", read on Tuesday the 18th — the loudest element of the row, spent
  /// restating the day it is being read on. Worse, a clock time is the one
  /// thing a missed reminder cannot use: nobody can act at 11:17 AM, it has
  /// gone. What that band is actually asked is *how long has this been sitting
  /// there*, and "3 h ago" answers it where the timestamp made the reader
  /// subtract.
  ///
  /// **Under *Today*, "2:23 PM" and "9:17 PM" are the same kind of thing** —
  /// but one of them is six minutes away and the other is seven hours away,
  /// and this is the screen whose entire reason for existing is that a moment
  /// can slip past unnoticed. Inside the hour the row says "in 6 min", which
  /// is the sentence that decides whether to deal with it now.
  ///
  /// **The two are not symmetrical, and the asymmetry is the point.** A time
  /// still to come is something to plan around — "9:17 PM" tells you it is
  /// after dinner, where "in 7 h" does not — so the future goes back to the
  /// clock as soon as it is far enough away to plan around, at an hour. A time
  /// already gone can be planned around by nobody, so the past stays relative
  /// until the date itself becomes the handle, at a day.
  ///
  /// Formatted through `intl` and `MaterialLocalizations` rather than by hand,
  /// so a 24-hour phone gets 19:00 and a 12-hour one gets 7:00 PM, and the
  /// weekday is the reader's own word for it. The relative forms reuse the
  /// `timeAgo*` family the capture-alerts tile already ships in every language.
  String _when(BuildContext context, DateTime at) {
    final MaterialLocalizations l = MaterialLocalizations.of(context);
    final String clock = l.formatTimeOfDay(TimeOfDay.fromDateTime(at));
    final String locale = Localizations.localeOf(context).toString();

    return switch (band) {
      ReminderBand.missed => _sinceItPassed(context, now.difference(at)),
      ReminderBand.today => _untilItIsDue(context, at.difference(now)) ?? clock,
      ReminderBand.tomorrow => clock,
      // "Thursday, 9:00 AM" — the weekday alone is unambiguous inside a week
      // and reads far faster than a date does.
      ReminderBand.thisWeek => '${DateFormat.EEEE(locale).format(at)}, $clock',
      ReminderBand.later => '${l.formatMediumDate(at)}, $clock',
    };
  }

  /// How long ago a missed reminder went by.
  ///
  /// The ladder runs minutes, hours, then the date — at a day the exact moment
  /// stops being derivable from "N days ago" and starts being the only handle
  /// on it, which is also the point at which this row is the last place the app
  /// still says it: the reminder sheet only prints a moment that is still
  /// *pending*, and a missed one is not.
  ///
  /// Clamped at one minute rather than saying "0 min ago", which is a number no
  /// clock ever shows and reads as a bug.
  String _sinceItPassed(BuildContext context, Duration gone) {
    if (gone.inHours < 1) {
      return context.l10n.timeAgoMinutes(
        gone.inMinutes < 1 ? 1 : gone.inMinutes,
      );
    }
    if (gone.inDays < 1) return context.l10n.timeAgoHours(gone.inHours);

    final MaterialLocalizations l = MaterialLocalizations.of(context);
    final DateTime at = now.subtract(gone);
    return '${l.formatMediumDate(at)}, '
        '${l.formatTimeOfDay(TimeOfDay.fromDateTime(at))}';
  }

  /// How long until a reminder due later today, or null past the hour.
  ///
  /// Null rather than a string for the far case, so the caller falls back to
  /// the clock instead of this function having to know what the clock looks
  /// like. Beyond an hour the clock is the better answer — see [_when].
  String? _untilItIsDue(BuildContext context, Duration left) {
    if (left.inHours >= 1) return null;
    return context.l10n.remindersInMinutes(
      left.inMinutes < 1 ? 1 : left.inMinutes,
    );
  }

  /// Reopens the sheet that set this reminder in the first place.
  ///
  /// **The same sheet, deliberately.** A bespoke "snooze by an hour" control
  /// here would be a second set of offers to keep in agreement with the first,
  /// and it would be the worse set: the reminder sheet already drops presets
  /// whose words have stopped being true at this hour, already refuses a moment
  /// in the past twice over, and already carries the full picker behind them.
  Future<void> _reschedule(BuildContext context) {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    return showReminderSheet(
      context,
      item,
      onChanged: () => bloc.add(LoadScreenshotsEvent()),
    );
  }

  void _open(BuildContext context) {
    final ScreenshotsBloc bloc = context.read<ScreenshotsBloc>();
    final ScreenshotsState state = bloc.state;
    if (state is! ScreenshotsLoadedState) return;

    final int at = state.screenshots.indexWhere(
      (ScreenshotEntity s) => s.id == item.id,
    );
    if (at < 0) return;

    Navigator.of(context).push(
      PhotoViewerRoute(
        builder: (_) => BlocProvider<ScreenshotsBloc>.value(
          value: bloc,
          child: ScreenshotDetailPage(
            screenshots: state.screenshots,
            initialIndex: at,
          ),
        ),
      ),
    );
  }
}

/// The card itself, without the spine or the gesture around it.
///
/// Split out from [_ReminderRow] because it is the thing the swipe moves: it
/// has to be one widget that can be translated sideways while the rail behind
/// it stays exactly where it is.
class _Card extends StatelessWidget {
  final ScreenshotEntity item;
  final bool isMissed;
  final String when;
  final double thumbWidth;
  final double thumbHeight;
  final VoidCallback onOpen;
  final VoidCallback onReschedule;
  final VoidCallback onClear;

  const _Card({
    required this.item,
    required this.isMissed,
    required this.when,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.onOpen,
    required this.onReschedule,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final IntentRef? intent = item.intent?.ref;

    return PressableScale(
      feedback: PressFeedback.highlight,
      semanticLabel: '${context.l10n.remindersTitle}, $when',
      onTap: onOpen,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          // **A tint and a weight, not just a border.** A missed reminder
          // used to be a normal card with a coloured outline, which at a
          // glance is a normal card. Blended into the surface rather than laid
          // over it as a translucent fill, so the thumbnail inside keeps its
          // own colours.
          color: isMissed
              ? Color.alphaBlend(
                  colors.error.withValues(alpha: 0.07),
                  colors.surface,
                )
              : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isMissed
                ? colors.error.withValues(alpha: 0.42)
                : colors.border,
            // Half a pixel heavier, which is not decoration: it is the third
            // hue-free signal on this card, after the solid node beside it and
            // the fill behind it. Desaturate this screen and a missed row is
            // still the one with an edge.
            width: isMissed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: thumbWidth,
                height: thumbHeight,
                child: AssetThumbnailImage(asset: item.asset),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              // **Held together and centred, after one revision spread it
              // against the tile's full height instead.** The argument for
              // spreading was that centring two short lines beside a tall
              // picture leaves an unattributable band of nothing above and
              // below them. It does — and pinning them to the tile's edges
              // moves all of that nothing into the *middle*, between the two
              // lines that belong together, which is far worse: a moment and
              // the caption under it stop reading as one block and start
              // reading as two things that failed to load between.
              //
              // Centred, the same slack sits outside the group where it reads
              // as the card's padding. What actually fixed the emptiness was
              // taking it out — [_ReminderRow._thumbHeight] came down until
              // the picture and the words are close to the same height.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _DueChip(
                    label: when,
                    isMissed: isMissed,
                    onTap: onReschedule,
                  ),
                  if (intent != null) ...<Widget>[
                    SizedBox(height: 7.h),
                    _DetailLine(
                      icon: intent.icon,
                      tint: intent.tint(context),
                      label: intent.label(context),
                    ),
                  ],
                  SizedBox(height: 7.h),
                  _DetailLine(
                    icon: Icons.image_outlined,
                    tint: colors.textDisabled,
                    label: _captured(context),
                  ),
                ],
              ),
            ),
            // **The destructive one stays a bare glyph, and stays last.**
            //
            // Only one of the two actions on this card should look like a
            // button. Giving both the same weight would put "remove" in front
            // of a thumb at the same volume as "keep it, later" — and the whole
            // reason this screen exists is that a reminder is something the
            // user did not want to lose.
            _RowAction(
              icon: Icons.close_rounded,
              tooltip: context.l10n.remindersClearOne,
              onTap: onClear,
            ),
          ],
        ),
      ),
    );
  }

  /// When the screenshot was taken, which is what the app knows about a
  /// picture nobody gave a verb to.
  ///
  /// **Not another due time, and the glyph is what guarantees it.** Two dates
  /// on one card is exactly the confusion this line could have caused; a small
  /// picture icon in front of it says which of the two is about the *image*
  /// before the words are read. The intent line above uses the same
  /// construction for the same reason.
  ///
  /// Dropped to the date alone rather than a date and a time. The reminder is
  /// the thing with a clock on this card; the capture only has to be specific
  /// enough to be recognised, and "Aug 18" does that where "Aug 18, 2:15 PM"
  /// competes with the line above it.
  String _captured(BuildContext context) => MaterialLocalizations.of(
    context,
  ).formatMediumDate(item.asset.createDateTime);
}

/// The moment this reminder is due — and the control that changes it.
///
/// **The row already showed the time; it just did not look like it could be
/// touched.** Two attempts got there the long way round. A bare clock glyph
/// beside the time read as a *label for* the time rather than a button, and a
/// filled "Change the time" button under it fixed the ambiguity by shouting:
/// six identical verbs down a list, each one heavier than the value it
/// belonged to, turning a list into a form. A label repeated on every row has
/// stopped being information by the second row.
///
/// So the value becomes the control. A figure sitting in a bordered box with an
/// edit glyph on it is read as *editable* everywhere it appears — it is what
/// every date field in every booking form looks like — and it needs no verb,
/// no second line and no extra height to say so. Tapping the time changes the
/// time, which is the shortest possible distance between what somebody wants
/// and where they have to press.
///
/// **It is set at body weight rather than caption**, which is the one change
/// the redesign made to it. The card now carries three lines, and the due
/// moment has to be the one the eye lands on first — it is the only line that
/// answers the question the reader came to this screen with.
///
/// Missed reminders carry the alert colour through the whole chip rather than
/// on the text alone: this is the row somebody has come to deal with, and the
/// thing they will press is the one that should be findable.
class _DueChip extends StatelessWidget {
  final String label;
  final bool isMissed;
  final VoidCallback onTap;

  const _DueChip({
    required this.label,
    required this.isMissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color tint = isMissed
        ? context.colors.error
        : context.colors.textPrimary;

    return PressableScale(
      scale: 0.97,
      // Says what the box is *for*, which the glyph alone cannot: a screen
      // reader hears the moment and then what pressing it does.
      semanticLabel: '$label, ${context.l10n.remindersReschedule}',
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(10.w, 5.h, 12.w, 5.h),
        decoration: BoxDecoration(
          color: isMissed
              ? context.colors.error.withValues(alpha: 0.12)
              : context.colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isMissed
                ? context.colors.error.withValues(alpha: 0.45)
                : context.colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.edit_calendar_rounded, size: 14.sp, color: tint),
            SizedBox(width: 7.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium.asMedium.copyWith(color: tint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glyph and a few words about the screenshot, under the due time.
///
/// One shape for both of the card's supporting lines — what the picture was
/// saved *for*, and when it was taken. They are the same kind of statement at
/// the same weight, and drawing them the same way is what keeps the card to
/// two visual levels instead of four.
///
/// Drawn as glyph and words at caption weight rather than as filled chips: the
/// card already carries a thumbnail, a chip and a button, and two more boxed
/// elements would turn it into a control panel.
class _DetailLine extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;

  const _DetailLine({
    required this.icon,
    required this.tint,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13.sp, color: tint),
        SizedBox(width: 5.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// One of the card's trailing buttons.
///
/// A `PressableScale` rather than an `IconButton`, for the reason the quick
/// actions sheet gives: Material's ripple starts on *release*, and the half of
/// a press that decides whether a control feels alive is the half before that.
/// It also nests correctly — an `IconButton` inside the card's own tap target
/// swallowed the press feedback of the card it sits on.
class _RowAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: PressableScale(
        scale: 0.9,
        semanticLabel: tooltip,
        onTap: onTap,
        child: Padding(
          // Padding rather than a fixed box: this is what carries the target
          // out to the 44 logical pixels a finger needs, without the icon
          // itself growing.
          padding: EdgeInsets.all(9.w),
          child: Icon(icon, size: 19.sp, color: context.colors.textSecondary),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- the swipe

/// The two answers a reminder has, reachable without aiming at anything.
///
/// **Added because both controls on this card are small targets on a list of
/// small targets.** Clearing meant hitting a 19pt glyph and rescheduling meant
/// hitting a chip; the row is otherwise the width of the phone and did nothing
/// with it. A drag across the card is the gesture every mail and task app has
/// spent a decade teaching, and it is the only one on this page that can be
/// made without looking.
///
/// **The buttons stay exactly where they were**, which is the half of this
/// that is easy to get wrong. A gesture is invisible: it is faster for the
/// person who knows it and does not exist for the person who does not, so it
/// can only ever be the second way to do something. Nothing here is reachable
/// by swipe alone.
///
/// ## The two directions are not symmetrical, and neither is what they do
///
/// Dragging **towards the end** — left, in English — clears, and completes:
/// the card leaves under the finger, which is the answer, and the undo is on
/// screen a moment later. Dragging **towards the start** opens the reminder
/// sheet and the card snaps back, because the card is not going anywhere until
/// a new time has been chosen and a sheet appearing over a hole in the list is
/// a promise about what happened that has not been kept yet.
///
/// Both are `confirmDismiss` rather than `onDismissed` for the same structural
/// reason: the list is owned by the bloc, not by these widgets. A `Dismissible`
/// that completes has to be removed from the tree by the next build or the
/// framework throws, and "the next build" here is a round trip to the photo
/// store. So this never lets a dismissal complete — the row leaves because
/// [_RemindersPageState._clearing] hides it at the moment of the gesture, which
/// is also what makes a reschedule that changes the band look like a move
/// rather than a disappearance.
class _Swipeable extends StatelessWidget {
  final String id;
  final Future<void> Function() onReschedule;
  final Future<void> Function() onClear;

  /// Fired once the drag has crossed the threshold, whichever way it went.
  ///
  /// On the *action*, not on the touch: a finger that starts to drag and
  /// thinks better of it has not learnt anything, and retiring the legend for
  /// it would take the instruction away from somebody mid-way through reading
  /// it.
  final VoidCallback onSwiped;

  final Widget child;

  const _Swipeable({
    required this.id,
    required this.onReschedule,
    required this.onClear,
    required this.onSwiped,
    required this.child,
  });

  /// How far across the card has to travel before the gesture counts.
  ///
  /// **A third rather than Flutter's 40%,** which is a long way to drag a
  /// 100pt-tall card with a thumb, and this is the screen where the action is
  /// undoable anyway. Not lower: at a quarter, a horizontal wobble during a
  /// vertical scroll starts clearing reminders.
  static const double _threshold = 0.33;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<String>('reminder-swipe-$id'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const <DismissDirection, double>{
        DismissDirection.startToEnd: _threshold,
        DismissDirection.endToStart: _threshold,
      },
      // Under the app's own press duration. The card is following a finger
      // that has already left, and the only thing left to watch is it
      // finishing the movement the user made.
      movementDuration: AppMotion.press,
      background: _SwipeAction.reschedule(context),
      secondaryBackground: _SwipeAction.clear(context),
      confirmDismiss: (DismissDirection direction) async {
        onSwiped();
        if (direction == DismissDirection.startToEnd) {
          // A light tap: the sheet arriving is the real feedback, and a heavy
          // buzz in front of it would be announcing a change that has not been
          // made yet.
          Haptics.tap();
          await onReschedule();
          return false;
        }
        Haptics.confirm();
        await onClear();
        return false;
      },
      child: child,
    );
  }
}

/// What shows behind a card being dragged aside.
///
/// Glyph *and* word, because a swipe is a gesture people commit to gradually:
/// the icon is what they see at twenty pixels of travel and the word is what
/// confirms it before they let go. An icon alone leaves "which of the two
/// directions was the destructive one" to be found out by trying it.
///
/// Tinted at a tenth rather than filled solid. This is a surface being
/// revealed under a card, not a button — a flat block of alert red the width of
/// the phone is louder than anything else this app draws, for an action that is
/// undoable and about to be undone by a third of the people who see it.
class _SwipeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final AlignmentDirectional alignment;

  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.alignment,
  });

  /// The surface behind a card being dragged towards the end of the line.
  ///
  /// **[AppPalette.secondary], which the palette defines as "informational,
  /// non-destructive: moving a file".** Rescheduling is precisely that, and
  /// unlike the accent it cannot be changed by a tint — so the two surfaces a
  /// swipe can reveal are guaranteed to stay a pair the user can tell apart,
  /// whatever colour they have set the app to.
  ///
  /// Named rather than written out at each call site because there are now
  /// two: the gesture reveals it, and [_SwipeNudge] demonstrates it. Two
  /// hand-written copies is how the lesson and the thing being taught stop
  /// matching.
  static _SwipeAction reschedule(BuildContext context) => _SwipeAction(
    icon: Icons.edit_calendar_rounded,
    label: context.l10n.remindersReschedule,
    tint: context.colors.secondary,
    alignment: AlignmentDirectional.centerStart,
  );

  /// The surface behind a card being dragged towards the start of the line.
  static _SwipeAction clear(BuildContext context) => _SwipeAction(
    icon: Icons.close_rounded,
    label: context.l10n.remindersClearOne,
    tint: context.colors.error,
    alignment: AlignmentDirectional.centerEnd,
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color.alphaBlend(
        tint.withValues(alpha: 0.12),
        context.colors.surface,
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18.sp, color: tint),
              SizedBox(width: 8.w),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.asMedium.copyWith(color: tint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The first row showing you what a swipe does, once, by doing it.
///
/// **The legend above says which way does what; this says what it feels
/// like.** Words can name a gesture and cannot demonstrate one — reading
/// "swipe to clear" and understanding that the card slides under your thumb
/// and a red surface comes out from behind it are two different pieces of
/// knowledge, and only the second one survives to the moment somebody actually
/// tries it. So the top row performs the gesture: out towards the end, hold
/// long enough for the label behind it to be read, back; then the other way.
///
/// **It is the real surfaces, not a picture of them.** The two panels revealed
/// here are the same [_SwipeAction] widgets `_Swipeable` reveals under a
/// finger, built from the same two constructors — so the demonstration cannot
/// drift from the thing it is demonstrating, and what the user sees during the
/// lesson is exactly what they will see during the gesture.
///
/// ## The rules it plays by
///
/// **It never blocks a real gesture.** A pointer landing anywhere on the row
/// stops the animation dead and drops the offset to zero on the same frame, so
/// a finger that arrives mid-demonstration takes over from a card that is
/// exactly where it looks like it is. An instructive animation that has to
/// finish before you may touch it is a modal dialog wearing a disguise.
///
/// **It plays only while the lesson is owed** — the same
/// `AppPreferences.hasSwipedReminder` that governs the legend, so the first
/// swipe or the legend's close button retires both at once — and only on the
/// first row, because the point is made once. Never at all when the reader has
/// asked the system for less motion: this is the *most* decorative thing on
/// the screen, and the one an accessibility setting most clearly means.
///
/// ## Why it runs long
///
/// Roughly two and a half seconds, against an app whose longest transition is
/// 280ms. The rule those are held to is about *response* — motion the user
/// caused, where every extra frame is latency they can feel. This is the other
/// kind: explanatory motion, seen once, which has to be slow enough to be
/// followed and to leave the revealed label on screen long enough to read. A
/// 200ms flick of the card would satisfy the rule and teach nothing.
class _SwipeNudge extends StatefulWidget {
  /// Whether this row is the one that demonstrates, and still owes the lesson.
  final bool active;

  final Widget child;

  const _SwipeNudge({required this.active, required this.child});

  /// How far across the card travels, as a fraction of its own width.
  ///
  /// Half, which is more than the third that would dismiss it and is the right
  /// number anyway: the panel behind carries a glyph and a word, and at a
  /// third of a phone's width "Change the time" is still cut off. Nothing is
  /// dismissed by this — no gesture is being simulated, only a translation —
  /// so the threshold is not the constraint. Legibility is.
  static const double _reach = 0.5;

  /// The counter-move before each reach, as a fraction of the card's width.
  ///
  /// Ten pixels on a phone. Enough to be felt as a gathering, far too small
  /// to be read as the card going the other way — past about 6% it stops
  /// looking like anticipation and starts looking like a stutter.
  static const double _windUp = 0.035;

  @override
  State<_SwipeNudge> createState() => _SwipeNudgeState();
}

class _SwipeNudgeState extends State<_SwipeNudge>
    with SingleTickerProviderStateMixin {
  /// The whole demonstration, in one timeline.
  ///
  /// Weights are milliseconds, so the sequence reads as the choreography it
  /// is. Each direction is the same four beats:
  ///
  /// 1. **A wind-up.** Three and a half percent of the card's width the
  ///    *wrong* way, over 140ms. It is ten pixels, and it is the single change
  ///    that makes this look designed rather than driven: nothing with weight
  ///    starts moving from perfectly still, and an object that gathers itself
  ///    before it goes is read as having some. Without it the card simply
  ///    appears to be already moving, which is what made the first version
  ///    feel hurried.
  /// 2. **The reach**, on [AppMotion.drawer] — the iOS sheet curve: a gentle
  ///    entry, a fast middle, a very long tail. That is the curve for
  ///    something being *pulled*, which is what is being demonstrated. The
  ///    app's default ease-out is for something answering a tap, and it was
  ///    making the card look flicked rather than dragged.
  /// 3. **The hold**, long enough to read the words that have appeared.
  /// 4. **The release**, on `easeOutBack`, which carries the card a little
  ///    past home and lets it settle. This is the beat that sells the rest: a
  ///    card that stops dead on zero was *placed* there, and one that swings
  ///    through and comes back was *let go of*.
  ///
  /// **Roughly four and a half seconds, against two and a half before.** The
  /// first version was correct and felt rushed — every beat landed before the
  /// eye had finished the one before it. Explanatory motion is allowed to take
  /// the time it needs; what it is not allowed to do is stand in the way, and
  /// it does not — see [_takeOver].
  static final Animatable<double> _path = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      // Let the list finish arriving, and the eye finish landing on it.
      TweenSequenceItem<double>(tween: ConstantTween<double>(0), weight: 500),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: -_SwipeNudge._windUp,
        ).chain(CurveTween(curve: AppMotion.standard)),
        weight: 140,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: -_SwipeNudge._windUp,
          end: _SwipeNudge._reach,
        ).chain(CurveTween(curve: AppMotion.drawer)),
        weight: 560,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(_SwipeNudge._reach),
        weight: 560,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _SwipeNudge._reach,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 520,
      ),
      // A breath between the two statements, so they read as two things said
      // rather than as one long wobble.
      TweenSequenceItem<double>(tween: ConstantTween<double>(0), weight: 300),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: _SwipeNudge._windUp,
        ).chain(CurveTween(curve: AppMotion.standard)),
        weight: 140,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _SwipeNudge._windUp,
          end: -_SwipeNudge._reach,
        ).chain(CurveTween(curve: AppMotion.drawer)),
        weight: 560,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(-_SwipeNudge._reach),
        weight: 560,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: -_SwipeNudge._reach,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 520,
      ),
    ],
  );

  /// Which panel belongs to the beat currently playing: 1 for the end of the
  /// line, -1 for the start.
  ///
  /// **Read from the timeline rather than from the sign of the offset**, and
  /// the wind-up and the settle are both the reason. Each of them puts the
  /// card a few pixels the *opposite* side of home while still belonging to
  /// its own direction, so picking the panel by `dx > 0` would flash the wrong
  /// colour twice per leg — at the two moments the eye is most likely to be
  /// watching. The weights mirror [_path] exactly.
  static final Animatable<double> _side = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 2280),
      TweenSequenceItem<double>(tween: ConstantTween<double>(-1), weight: 2080),
    ],
  );

  /// **Built in [initState], not lazily, and that distinction is a crash.**
  ///
  /// As a `late final` initialiser this is created the first time something
  /// reads it — and on every row that is *not* demonstrating, the first read
  /// is `dispose`. Constructing an `AnimationController` calls `createTicker`,
  /// which looks up `TickerMode` through the element; doing that from
  /// `dispose` means looking up an ancestor of a widget that has already been
  /// deactivated, which throws. The failure lands nowhere near the cause: the
  /// exception aborts the dispose walk, `_RemindersPageState.dispose` never
  /// runs, its thirty-second timer is never cancelled, and the test framework
  /// reports a pending timer.
  late final AnimationController _controller;
  late final Animation<double> _travel;
  late final Animation<double> _facing;

  /// Set the moment a finger lands, and never unset.
  ///
  /// One demonstration per visit, and a person who has started touching the
  /// row does not need the rest of it.
  bool _interrupted = false;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // The sum of the weights in [_path]. Stated rather than derived,
      // because `TweenSequence` normalises them away — and a duration that
      // has drifted from the choreography stretches or crushes every beat
      // in it at once.
      duration: const Duration(milliseconds: 4360),
    );
    _travel = _controller.drive(_path);
    _facing = _controller.drive(_side);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.active || AppMotion.reduced(context)) return;
    _started = true;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _takeOver(PointerDownEvent _) {
    if (_interrupted || !_controller.isAnimating) return;
    _controller.stop();
    setState(() => _interrupted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return Listener(
      onPointerDown: _takeOver,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double dx = _interrupted ? 0 : _travel.value;
          if (dx == 0) return child!;

          // Which of the two surfaces is being uncovered — taken from [_side],
          // for the reason given there. It is a direction along the *line*, so
          // it still has to be read against the writing direction before it
          // means a side of the screen: heading for the end is rightwards in
          // English and leftwards in Arabic.
          final bool rtl = Directionality.of(context) == TextDirection.rtl;
          final bool towardsEnd = rtl ? _facing.value < 0 : _facing.value > 0;

          return Stack(
            children: <Widget>[
              // Full-bleed rather than clipped to the uncovered strip, which
              // `Dismissible` bothers with and this does not need to: the card
              // in front is opaque, so the only part of this that can be seen
              // is the part the card has moved off — which is the strip.
              Positioned.fill(
                child: towardsEnd
                    ? _SwipeAction.reschedule(context)
                    : _SwipeAction.clear(context),
              ),
              FractionalTranslation(translation: Offset(dx, 0), child: child),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

// --------------------------------------------------------------- the legend

/// What a swipe does, in words, until somebody has swiped.
///
/// **A gesture nobody can see is not a feature.** The two fastest answers on
/// this screen are a drag across a row, and before this they were reachable
/// only by already knowing they were there. Mail apps get away with that
/// because a decade of mail apps taught the gesture; a screenshot organiser
/// has no such inheritance, and "they will discover it" is the sentence under
/// every feature nobody uses.
///
/// So it is stated. Not as a tooltip, not as a one-frame animation somebody
/// blinks through — as a small card at the top of the list saying which way
/// does what, in **the exact two colours and the exact two glyphs the swipe
/// itself reveals**. Reading it and then swiping produces the surface it just
/// described, which is what turns a label into a lesson.
///
/// **It leaves when it stops being needed.** The card is drawn while
/// `AppPreferences.hasSwipedReminder` is false and never again after the first
/// swipe in either direction — so it costs a new user one glance and an
/// experienced one nothing. Dismissing it by hand counts as knowing: somebody
/// who closes an instruction is telling you they have read it.
///
/// The arrows drift, gently, only while the card is on screen. A static arrow
/// says *that direction*; a moving one says *drag*, which is the half of the
/// instruction a picture makes better than a word. Two seconds a cycle, four
/// pixels of travel, and nothing at all when the reader has asked the system
/// for less motion.
class _SwipeLegend extends StatefulWidget {
  final VoidCallback onDismiss;

  const _SwipeLegend({required this.onDismiss});

  @override
  State<_SwipeLegend> createState() => _SwipeLegendState();
}

class _SwipeLegendState extends State<_SwipeLegend>
    with SingleTickerProviderStateMixin {
  /// Built eagerly for the reason spelled out at [_SwipeNudgeState._controller]:
  /// with reduced motion on, nothing here ever touches this before `dispose`,
  /// and a controller first constructed there throws on the ticker lookup.
  late final AnimationController _drift;

  bool _running = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool wanted = !AppMotion.reduced(context);
    if (wanted == _running) return;
    _running = wanted;
    if (wanted) {
      _drift.repeat(reverse: true);
    } else {
      _drift
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 10.h, 20.w, 2.h),
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(14.w, 10.h, 8.w, 12.h),
        decoration: BoxDecoration(
          // A dashed border would be the obvious way to say "temporary" and
          // would be the only dashed border in the app. A flat panel one step
          // off the page says the same thing by weight instead, which is how
          // every other quiet surface here is separated.
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.swipe_rounded,
                  size: 15.sp,
                  color: colors.textSecondary,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    context.l10n.remindersSwipeHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall.asMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                // **Closing it is an answer, so it is recorded as one.** The
                // alternative — a card that can only be retired by performing
                // the gesture — holds an instruction in front of somebody who
                // has already read it until they do as they are told.
                _RowAction(
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onTap: widget.onDismiss,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            _LegendLine(
              drift: _drift,
              // Towards the end of the line — right in English, left in a
              // right-to-left locale — which is the direction
              // `DismissDirection.startToEnd` means and the way the row
              // actually travels.
              towardsEnd: true,
              icon: Icons.edit_calendar_rounded,
              label: context.l10n.remindersReschedule,
              tint: colors.secondary,
            ),
            SizedBox(height: 7.h),
            _LegendLine(
              drift: _drift,
              towardsEnd: false,
              icon: Icons.close_rounded,
              label: context.l10n.remindersClearOne,
              tint: colors.error,
            ),
          ],
        ),
      ),
    );
  }
}

/// One direction, one glyph, one word — the same three the swipe reveals.
class _LegendLine extends StatelessWidget {
  final Animation<double> drift;
  final bool towardsEnd;
  final IconData icon;
  final String label;
  final Color tint;

  const _LegendLine({
    required this.drift,
    required this.towardsEnd,
    required this.icon,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    // Which way the finger goes on *this* phone. `startToEnd` is rightwards in
    // English and leftwards in Arabic, so the arrow is chosen from the writing
    // direction rather than drawn once and hoped for.
    final bool pointsRight = towardsEnd != rtl;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 22.w,
          child: AnimatedBuilder(
            animation: drift,
            builder: (BuildContext context, Widget? child) =>
                Transform.translate(
                  // Four pixels, in the direction the row would go. Enough to
                  // read as movement at a glance, small enough that it never
                  // competes with the list underneath.
                  offset: Offset((pointsRight ? 1 : -1) * 4 * drift.value, 0),
                  child: child,
                ),
            child: Icon(
              pointsRight
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              size: 15.sp,
              color: tint,
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Icon(icon, size: 14.sp, color: tint),
        SizedBox(width: 7.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall.copyWith(color: tint),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- the foot

/// Where the list stops.
///
/// **A short list used to end by running out.** Two reminders on a tall phone
/// were two cards and then two thirds of black, which reads as content that
/// failed to load rather than as a list that has finished — the exact failure
/// the intent screen's closing line was written for, on the screen that shows
/// it worst because a reminders list is *supposed* to be short.
///
/// It restates the count on purpose. The summary at the top of the page said
/// it before anything was read; this says it after everything has been, which
/// is where "was that all of them?" is actually asked.
class _ListEnd extends StatelessWidget {
  final int count;

  const _ListEnd({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 6.h, 20.w, 0),
      child: Row(
        children: <Widget>[
          // Keeps the closing line on the same axis as everything above it, so
          // the spine's last node reads as the end of the sequence rather than
          // as a row that was cut off.
          SizedBox(width: _Rail.gutter),
          Expanded(
            child: Text(
              context.l10n.remindersCount(count),
              style: context.text.caption.copyWith(
                color: context.colors.textDisabled,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
