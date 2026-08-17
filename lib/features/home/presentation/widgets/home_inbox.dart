import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/skeleton.dart';
import 'package:shoto/features/home/presentation/widgets/home_section_title.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// Everything that is waiting on you, in one place and one visual language.
///
/// **This block used to be two blocks, and that was the problem.** An unsorted
/// *card* sat above a "Waiting on you" row of *chips*: two different shapes,
/// two different densities, two headings — for one idea. Both answered the same
/// question, "what needs me?", so a reader had to learn two vocabularies to
/// read one answer, and the page paid twice for the heading and the margins.
///
/// The fix for that was to put both inside a single bordered card, as rows
/// divided by hairlines. **That fix was wrong, and the way it was wrong is
/// worth recording**, because it only shows up in the state most users are
/// actually in.
///
/// The card was designed around the unsorted row: a display-sized numeral, a
/// strip of thumbnails, an accent arrow. That row carries the whole thing, and
/// the accent-tinted border it was given is earned by exactly that weight. But
/// unsorted is the *transient* state — it empties as soon as somebody files
/// their screenshots, which is the behaviour the app exists to produce. What is
/// left then is two thin rows of grey text inside a large, round,
/// accent-bordered box with a line through the middle of it: a frame with an
/// announcement's emphasis and a footnote's content. On a phone it reads as an
/// empty table somebody forgot to fill in.
///
/// So the container belongs to the unsorted pile rather than to the section:
///
/// * **Unsorted keeps the card**, because it is a pile of unknown pictures and
///   the pictures are the only honest way to show it. A number is an
///   abstraction of the work; the thumbnails are the work.
/// * **The intents are their own strip** of small tiles — a verb, a count, and
///   the teal that `IntentVisuals` has always said is the colour of an intent
///   and which this block was somehow drawing entirely in grey.
/// * **A heading, like every other section on Home.** Tools has one and Recent
///   has one; this had none, which is half of why it read as an unfinished
///   fragment rather than as a part of the page.
///
/// It is still true that nothing empty is drawn: an intent nobody has used
/// never appears, and with everything cleared the whole block collapses to a
/// single quiet line with no heading over it. A hub should get shorter when
/// there is less to do.
class HomeInbox extends StatelessWidget {
  /// The pile itself. Empty in a [HomeInbox.preview], where the count is known
  /// but the pictures are still being read out of the gallery.
  final List<ScreenshotEntity> unsorted;

  /// How many screenshots are waiting under each intent the user set.
  final Map<IntentRef, int> waiting;

  /// How many are unsorted, when that is known without [unsorted] being
  /// available — see [HomeInbox.preview]. Null everywhere else, where the list
  /// is the count.
  final int? unsortedCount;

  /// Reminders the user has set, soonest first, including ones whose moment
  /// has passed. Empty in a [HomeInbox.preview].
  final List<ScreenshotEntity> reminders;

  final ValueChanged<LibraryFilter> onOpenLibrary;
  final void Function(IntentRef intent) onOpenIntent;
  final VoidCallback onOpenReminders;

  const HomeInbox({
    super.key,
    required this.unsorted,
    required this.waiting,
    required this.reminders,
    required this.onOpenLibrary,
    required this.onOpenIntent,
    required this.onOpenReminders,
  }) : unsortedCount = null;

  /// The same block, drawn from counts alone while the gallery is still being
  /// enumerated.
  ///
  /// **This is the fix for what a cold start used to look like.** Home's first
  /// frame drew nothing here at all, so the app opened in "empty library" shape
  /// — no search bar, no recents, tools worded for a new install — and then
  /// rearranged itself when the read landed a second or two later. What that
  /// reads as is not slowness, it is the page changing its mind in front of
  /// you.
  ///
  /// It draws the real numbers because they are real: the unsorted count and
  /// the waiting verbs come out of the local tables, which answer immediately
  /// and are the same rows the finished read joins against — see
  /// `LibrarySummary`. Only the thumbnails are missing, because only they are
  /// actually in the gallery, and they arrive as pictures replacing grey tiles
  /// of exactly their size.
  ///
  /// Nothing here is tappable. Every destination this block leads to wants the
  /// library it does not have yet, and a card that answers a tap by doing
  /// nothing is worse than one that visibly is not ready.
  const HomeInbox.preview({
    super.key,
    required int count,
    required this.waiting,
  }) : unsortedCount = count,
       unsorted = const <ScreenshotEntity>[],
       // Not in the summary: reminders are a join against the library, and
       // this constructor exists precisely for the frames before that has
       // landed. Drawing a count here would mean drawing it wrong.
       reminders = const <ScreenshotEntity>[],
       onOpenLibrary = _ignoreFilter,
       onOpenIntent = _ignoreIntent,
       onOpenReminders = _ignore;

  static void _ignoreFilter(LibraryFilter _) {}
  static void _ignoreIntent(IntentRef _) {}
  static void _ignore() {}

  bool get _isPreview => unsortedCount != null;

  int get _unsorted => unsortedCount ?? unsorted.length;

  bool get _isClear => _unsorted == 0 && waiting.isEmpty && reminders.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (_isClear) return const _AllFiled();

    final bool hasUnsorted = _unsorted > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        HomeSectionTitle(context.l10n.homeNeedsYou),
        SizedBox(height: 10.h),
        if (hasUnsorted)
          _UnsortedCard(
            unsorted: unsorted,
            count: _unsorted,
            isPreview: _isPreview,
            onTap: _isPreview
                ? null
                : () => onOpenLibrary(LibraryFilter.unsorted),
          ),
        // **Above the verbs, because it is the only thing here with a
        // deadline.** The unsorted card and the intent tags are both work that
        // will still be waiting tomorrow; a reminder had a moment, and once
        // that moment passes the notification has already cleared itself. So
        // it sits where a missed one cannot be scrolled past.
        if (hasUnsorted && reminders.isNotEmpty) SizedBox(height: 12.h),
        if (reminders.isNotEmpty)
          _RemindersRow(reminders: reminders, onTap: onOpenReminders),
        if ((hasUnsorted || reminders.isNotEmpty) && waiting.isNotEmpty)
          SizedBox(height: 12.h),
        if (waiting.isNotEmpty)
          _IntentTags(
            waiting: waiting,
            onOpenIntent: _isPreview ? null : onOpenIntent,
          ),
      ],
    );
  }
}

/// `3 reminders · 1 missed`, or `2 reminders · Next Tue, 9:00 AM`.
///
/// **A count alone would not have been worth a row.** What makes this useful is
/// the second half: either the app is telling you something already came and
/// went — the case the whole reminders feature is here to stop being silent —
/// or it is telling you when to expect the next one, which is the question
/// somebody who set it actually has.
class _RemindersRow extends StatelessWidget {
  final List<ScreenshotEntity> reminders;
  final VoidCallback onTap;

  const _RemindersRow({required this.reminders, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final DateTime now = DateTime.now();
    final int missed = reminders
        .where((ScreenshotEntity s) => !s.remindAt!.isAfter(now))
        .length;
    final ScreenshotEntity? next = reminders
        .where((ScreenshotEntity s) => s.remindAt!.isAfter(now))
        .firstOrNull;

    // Alert only when something was actually missed. A reminder that is simply
    // coming up is not a problem, and colouring it like one would spend the
    // alert colour on the ordinary case — after which it stops meaning alert.
    final bool alerting = missed > 0;
    final Color tint = alerting ? colors.error : colors.primary;

    final String detail = alerting
        ? context.l10n.remindersMissedCount(missed)
        : context.l10n.remindersNextAt(
            MaterialLocalizations.of(
              context,
            ).formatTimeOfDay(TimeOfDay.fromDateTime(next!.remindAt!)),
          );

    return PressableScale(
      feedback: PressFeedback.highlight,
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 12.w, 12.h),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: alerting ? tint.withValues(alpha: 0.35) : colors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              alerting
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              size: 19.sp,
              color: tint,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                context.l10n.remindersCount(reminders.length),
                style: context.text.bodyMedium,
              ),
            ),
            Text(
              detail,
              style: context.text.caption.copyWith(
                color: alerting ? tint : colors.textSecondary,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: colors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

/// The inbox before anything at all is known about the library.
///
/// **A narrower case than it looks.** Once the local summary is in — which is
/// one indexed sqlite read — Home draws [HomeInbox.preview] with the user's
/// real numbers instead. This covers only the frames before even that has
/// answered, and the rare library whose summary read failed outright.
///
/// So it claims nothing. No count, no verbs, no "all filed" — every one of
/// those is a statement about a library nobody has looked at yet, and the last
/// one is the worst of them, because congratulating somebody on an empty inbox
/// that then fills up is the same "changing its mind" this whole change exists
/// to stop. What it does instead is hold the space: the card's exact height, so
/// whatever lands next lands without moving the page.
class HomeInboxSkeleton extends StatelessWidget {
  const HomeInboxSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The heading's own line, at the width a short section title runs to.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(width: 84.w, height: 13.h),
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 15.h, 14.w, 15.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Stands in for the display-sized numeral, which is what
                    // sets this row's height in the real card.
                    SkeletonBox(width: 34.w, height: 34.h),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SkeletonBox(width: 72.w, height: 12.h),
                          SizedBox(height: 8.h),
                          SkeletonBox(width: 128.w, height: 10.h),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    SkeletonBox(
                      width: 38.w,
                      height: 38.w,
                      radius: AppRadius.pill,
                    ),
                  ],
                ),
                SizedBox(height: 13.h),
                SizedBox(
                  height: _UnsortedCard._tileHeight.h,
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < 4; i++) ...[
                        if (i > 0) SizedBox(width: _UnsortedCard._gap.w),
                        const _PendingTile(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The unsorted pile, as a card.
///
/// The one place on Home that keeps the accent border, and it keeps it because
/// it is the one thing here with something at stake: a pile that only grows
/// until somebody deals with it.
class _UnsortedCard extends StatelessWidget {
  final List<ScreenshotEntity> unsorted;

  /// The number on the card. Not `unsorted.length`, because in a preview the
  /// count is known and the pictures are not.
  final int count;

  /// Whether the thumbnails are still on their way. Drives the placeholder
  /// tiles and, with [onTap] null, the card being inert.
  final bool isPreview;

  final VoidCallback? onTap;

  /// The tile geometry the thumbnail row measures itself against.
  ///
  /// Down from 44×58. At that size the tiles were legible enough to invite
  /// reading, which is the wrong job for them — they are a glance at *how much
  /// and roughly what*, and the row that answers that should not compete with
  /// the numeral above it. Smaller also fits one more before the overflow chip
  /// takes over.
  static const double _tileWidth = 36;
  static const double _tileHeight = 48;
  static const double _gap = 6;

  const _UnsortedCard({
    required this.unsorted,
    required this.count,
    required this.isPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final BorderRadius shape = BorderRadius.circular(AppRadius.lg);

    return GlassRim(
      borderRadius: shape,
      falloff: 34,
      child: Container(
        decoration: BoxDecoration(
          // **A plain surface, not the accent wash it started as.**
          //
          // `surfaceSelected` is the accent at 10% over the surface — and in
          // light mode the page behind this card is *also* carrying a wash of
          // the accent, because the hero gradient sits right here. Two washes
          // of one hue at similar strengths do not stack into a card, they
          // cancel into a slightly bluer rectangle: on the device the hero
          // barely separated from the page it was supposed to be raised off.
          //
          // An opaque surface separates from whatever is behind it, tinted or
          // not, which is the property a card needs. The emphasis moves to the
          // three places that cost no area — the accent label, the accent
          // arrow chip and the tinted border.
          color: colors.surface,
          borderRadius: shape,
          // **The plain hairline, not the accent one.**
          //
          // The accent was doing four separate jobs inside one card — the
          // border, the "Unsorted" label, the arrow's disc and the arrow itself
          // — on a page whose background is *also* carrying a wash of it. Five
          // instances of one desaturated navy in the top third of the screen is
          // what makes it read cold and tired rather than calm: no single one
          // is wrong, and together they are a blue screen.
          //
          // So the accent is spent once, on the arrow, which is the only thing
          // here that is actually an action. Everything else goes back to the
          // vocabulary the rest of the app uses for a raised white card.
          border: Border.all(color: colors.border),
        ),
        child: PressableScale(
          scale: 0.99,
          feedback: PressFeedback.highlight,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 15.h, 14.w, 15.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // The numeral leads, on the leading edge, where the eye
                    // starts.
                    //
                    // **And it reacts when it changes**, which is the one place
                    // on Home worth spending the delight budget on. The entire
                    // promise of this card is that the number goes down as you
                    // work; filing happens in another tab, so the payoff lands
                    // on a screen the user comes *back* to — and without this it
                    // lands silently, as a different digit that was always
                    // there. `ValuePop` does not fire on first build, so
                    // arriving on Home is still.
                    //
                    // A gentler peak than the favourite heart's 1.15: this is
                    // display-sized type, and the same proportional overshoot on
                    // a 28sp numeral reads as a lurch rather than as a reaction.
                    ValuePop(
                      value: count,
                      peak: 1.09,
                      child: Text(
                        '$count',
                        style: context.text.displayLarge.copyWith(
                          color: colors.textPrimary,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ink, not accent. It is the card's title — the
                          // sentence under it is what explains it and the arrow
                          // is what opens it. A heading painted in the accent
                          // reads as a link, which invites the eye to a word
                          // that does nothing on its own.
                          Text(
                            context.l10n.libraryFilterUnsorted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.button.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            context.l10n.homeInboxCountSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      width: 38.w,
                      height: 38.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary.withValues(alpha: 0.16),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18.sp,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 13.h),
                SizedBox(
                  height: _tileHeight.h,
                  // **How many fit is measured, not assumed.**
                  //
                  // This was a hardcoded five "with room for the overflow
                  // chip", and it overflowed by 11 pixels the first time a
                  // library had more than five unsorted in it — five tiles
                  // *plus* the chip is six slots. The count has to come from
                  // the width, which depends on the gutter, the card padding
                  // and the device.
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final double slot = _tileWidth.w + _gap.w;
                      final int fits = ((c.maxWidth + _gap.w) / slot).floor();
                      final int room = fits < 1 ? 1 : fits;

                      final bool needsMore = count > room;
                      final int tiles = needsMore ? room - 1 : count;
                      final int hidden = count - tiles;

                      // **The same arithmetic in both states, which is the
                      // whole point.** A preview lays out exactly as many
                      // slots as the finished card will, so the pictures
                      // arriving is a grey tile becoming a screenshot and
                      // never the row changing length underneath it.
                      final Widget row = Row(
                        children: [
                          for (int i = 0; i < tiles; i++) ...[
                            if (i > 0) SizedBox(width: _gap.w),
                            if (isPreview)
                              const _PendingTile()
                            else
                              _Tile(screenshot: unsorted[i]),
                          ],
                          if (needsMore && hidden > 0) ...[
                            if (tiles > 0) SizedBox(width: _gap.w),
                            _More(count: hidden),
                          ],
                        ],
                      );

                      return isPreview ? SkeletonPulse(child: row) : row;
                    },
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

/// The verbs the user set and has not finished, as a row of tags.
///
/// **This was a row of cards, and the cards were the mistake.** Each one held
/// two short facts — a verb and a usually-single-digit number — inside a
/// hundred-pixel white box with a border, which put three near-identical white
/// boxes down the same screen: the pile, then "To read", then "To book". The
/// number sat in one corner and the verb in the opposite one with nothing
/// between them, so a tile was mostly empty and the eye had to travel a
/// diagonal to read four characters.
///
/// A tag is the honest size for that content. It costs a third of the height,
/// it reads left to right in one movement — *glyph, verb, count* — and it stops
/// competing with the card above it, which is the only thing in this section
/// that has any bulk to justify.
///
/// **Tinted rather than outlined**, and that does two jobs. It marks these as a
/// different class of object from the white card above rather than a smaller
/// copy of it; and the tint is the teal `IntentVisuals` has always said is the
/// colour of an intent, on a screen whose blues were beginning to pile up.
///
/// A `Wrap` rather than a scroller: these are short, and somebody who has
/// invented eight verbs should see all eight stacked into two lines rather than
/// six of them hidden off the edge of a strip they have no reason to think
/// scrolls.
class _IntentTags extends StatelessWidget {
  final Map<IntentRef, int> waiting;

  /// Null in a preview, where the screens these open cannot be built yet.
  final void Function(IntentRef intent)? onOpenIntent;

  const _IntentTags({required this.waiting, required this.onOpenIntent});

  @override
  Widget build(BuildContext context) {
    final void Function(IntentRef intent)? open = onOpenIntent;

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: <Widget>[
        for (final MapEntry<IntentRef, int> entry in waiting.entries)
          _IntentTag(
            intent: entry.key,
            count: entry.value,
            onTap: open == null ? null : () => open(entry.key),
          ),
      ],
    );
  }
}

/// One verb the user set and has not finished: `To read · 2`.
class _IntentTag extends StatelessWidget {
  final IntentRef intent;
  final int count;
  final VoidCallback? onTap;

  const _IntentTag({
    required this.intent,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color tint = intent.tint(context);

    return PressableScale(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(12.w, 8.h, 14.w, 8.h),
        decoration: BoxDecoration(
          // A wash rather than a fill: at full strength this is a filled
          // control, and none of these is the primary action on the page.
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(intent.icon, size: 15.sp, color: tint),
            SizedBox(width: 8.w),
            // **The verb, not lowercased.** It was `.toLowerCase()`, which made
            // "to read" a fragment trailing off a number instead of the name of
            // a job. It is the label of this tag and the title of the screen it
            // opens, and those should be the same words.
            Text(
              intent.waitingTitle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium.asMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(width: 8.w),
            // In the tint rather than in ink, so the number reads as part of
            // the tag rather than as a second label sharing it.
            ValuePop(
              value: count,
              child: Text(
                '$count',
                style: context.text.bodyMedium.asSemiBold.copyWith(
                  color: tint,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final ScreenshotEntity screenshot;

  const _Tile({required this.screenshot});

  @override
  Widget build(BuildContext context) {
    // The clipped corner, on the one thing it is for: something Shoto is
    // holding. See `app_shapes.dart`.
    return ClippedCorner(
      radius: AppRadius.sm,
      cut: 9.r,
      child: SizedBox(
        width: _UnsortedCard._tileWidth.w,
        height: double.infinity,
        child: ColoredBox(
          color: context.colors.surfaceVariant,
          child: AssetThumbnailImage(asset: screenshot.asset),
        ),
      ),
    );
  }
}

/// A tile whose picture has not been read out of the gallery yet.
///
/// Same width, same height, same corner as [_Tile] — including the clip, so
/// the signature cut is there from the first frame rather than appearing when
/// the image does.
class _PendingTile extends StatelessWidget {
  const _PendingTile();

  @override
  Widget build(BuildContext context) {
    return ClippedCorner(
      radius: AppRadius.sm,
      cut: 9.r,
      child: SizedBox(
        width: _UnsortedCard._tileWidth.w,
        height: double.infinity,
        child: ColoredBox(color: context.colors.surfaceVariant),
      ),
    );
  }
}

class _More extends StatelessWidget {
  final int count;

  const _More({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _UnsortedCard._tileWidth.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '+$count',
        style: context.text.caption.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}

/// Nothing waiting: one line, no card, no zero.
class _AllFiled extends StatelessWidget {
  const _AllFiled();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;

    return Row(
      children: [
        Container(
          width: 34.w,
          height: 34.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.success.withValues(alpha: 0.16),
          ),
          child: Icon(Icons.check_rounded, size: 18.sp, color: colors.success),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.homeInboxClear,
                style: context.text.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                context.l10n.homeInboxClearSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
