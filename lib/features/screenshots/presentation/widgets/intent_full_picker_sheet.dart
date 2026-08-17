import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/services/haptics.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/glass_layer.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/features/screenshots/presentation/widgets/custom_intent_editor_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/intent_visuals.dart';

/// What the full picker decided.
///
/// A wrapper around a nullable rather than the nullable itself, so that
/// "dismissed" and "chose nothing in particular" stay distinguishable all the
/// way back to the caller. They are opposite instructions — leave it alone
/// versus clear it — and a bare `IntentRef?` says the same thing for both.
class IntentPickerResult {
  final IntentRef? intent;
  const IntentPickerResult(this.intent);
}

/// Every verb this account can use, plus the way to write another.
///
/// The compact row in front of this shows five; this shows all of them. It is
/// deliberately a plain list of the same verbs rather than a search field or a
/// grouped picker — at this size, looking is faster than typing, and a search
/// field would make the vocabulary feel bigger than it is.
///
/// **Laid out on an aligned grid rather than flowed as chips.** It was a
/// [Wrap] of pills sized to their own labels, which meant fifteen rectangles
/// of nine different widths in rows of two and three, with a ragged right edge
/// and a gutter that changed on every line. Nothing in that picture is wrong
/// on its own and there is no column for the eye to run down, so finding "Pay"
/// means reading all fifteen — every time, on a sheet people open several
/// times a day.
///
/// A grid costs one thing and buys two. It costs the tidy hug of a pill around
/// a short word. It buys a shape that can be *scanned* — even columns, even
/// rows, every cell the same — and it buys the longest word in any language a
/// place to go, because the label sits under its glyph with two lines to use
/// rather than pushing a pill wider than the screen. German is what settles
/// that argument: "Herunterladen" in a row of self-sized chips is a pill
/// nearly half the sheet wide.
///
/// The column count comes from what fits rather than from a phone size — see
/// [_IntentGrid], which is what keeps this honest on a small screen, a fold
/// and at 130% system text.
Future<IntentPickerResult?> showIntentFullPickerSheet(
  BuildContext context, {
  required IntentRef? selected,
}) {
  return showAppSheet<IntentPickerResult>(
    context: context,
    isScrollControlled: true,
    // Tall enough to be in the same bracket as the editor it leads to, and
    // they open back to back — a slower entrance here would be the first half
    // of the same gesture running at a different speed.
    enterDuration: AppMotion.normal,
    builder: (BuildContext sheetContext) =>
        _IntentFullPickerContent(selected: selected),
  );
}

/// The built-in verbs, **commonest first**, for reading rather than for
/// storing.
///
/// `ScreenshotIntent.values` is declaration order, and declaration order
/// belongs to the database — the enum is persisted, so it can never be
/// rearranged to suit a screen. This is the screen's own order, which is what
/// lets the grid put the verbs somebody reaches for every week in the first
/// row and the specialists at the bottom, without touching a stored value.
///
/// The order is by how often the verb is *wanted*, not by category: a
/// screenshot is usually something to buy, something to pay, something to read
/// later or somebody to answer. Cook, compare and fix are real and rare, and
/// they belong exactly where a rare thing belongs — present, findable, last.
///
/// It is a fixed list rather than a live "most used" sort on purpose. A grid
/// that rearranges itself between one opening and the next destroys the only
/// thing a grid is better at than a list: the verb you want being where it was
/// last time. Muscle memory beats a marginally better first row.
const List<ScreenshotIntent> _byHowOftenUsed = <ScreenshotIntent>[
  ScreenshotIntent.buy,
  ScreenshotIntent.pay,
  ScreenshotIntent.read,
  ScreenshotIntent.reply,
  ScreenshotIntent.book,
  ScreenshotIntent.visit,
  ScreenshotIntent.watch,
  ScreenshotIntent.send,
  ScreenshotIntent.download,
  ScreenshotIntent.listen,
  ScreenshotIntent.apply,
  ScreenshotIntent.tryIt,
  ScreenshotIntent.cook,
  ScreenshotIntent.compare,
  ScreenshotIntent.fix,
];

class _IntentFullPickerContent extends StatefulWidget {
  final IntentRef? selected;

  const _IntentFullPickerContent({required this.selected});

  @override
  State<_IntentFullPickerContent> createState() =>
      _IntentFullPickerContentState();
}

class _IntentFullPickerContentState extends State<_IntentFullPickerContent> {
  final IntentCatalog _catalog = sl<IntentCatalog>();

  @override
  void initState() {
    super.initState();
    _catalog.load();
  }

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      sigma: AppBlur.tallSheet,
      child: SafeArea(
        child: ConstrainedBox(
          // Capped so the sheet never becomes a full-screen page. It is a list
          // of short words; taking the whole screen for it would make choosing
          // one feel like navigating somewhere.
          //
          // **Back down to 0.75 now the grid has replaced the flowed chips.**
          // It went up to 0.85 because fifteen self-sized pills could not be
          // read without scrolling to them; four tidy rows can, so the sheet
          // no longer needs the extra tenth of the screen — and every pixel it
          // gives back is a pixel of glass the phone stops re-blurring.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  context.l10n.intentPrompt,
                  style: context.text.headlineMedium,
                ),
                SizedBox(height: 20.h),
                _SectionLabel(context.l10n.intentSectionCommon),
                SizedBox(height: 12.h),
                _IntentGrid(
                  children: <Widget>[
                    for (final ScreenshotIntent intent in _byHowOftenUsed)
                      _IntentCell(
                        icon: intent.icon,
                        label: intent.label(context),
                        isSelected: widget.selected == BuiltInIntent(intent),
                        onTap: () => _choose(BuiltInIntent(intent)),
                      ),
                  ],
                ),
                SizedBox(height: 24.h),
                _SectionLabel(context.l10n.intentSectionYours),
                SizedBox(height: 12.h),
                // **Only this half listens to the catalog.** The fifteen verbs
                // Shoto ships cannot change while the sheet is open, and
                // rebuilding them when the table finishes reading — which
                // lands during the entrance — was rebuilding twenty cells to
                // arrive at exactly the same twenty cells.
                ListenableBuilder(
                  listenable: _catalog,
                  builder: (BuildContext context, Widget? child) {
                    final List<CustomIntent> mine = _catalog.customIntents;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _IntentGrid(
                          children: <Widget>[
                            for (final CustomIntent intent in mine)
                              _IntentCell(
                                icon: intent.icon,
                                // The field, not the extension: a custom
                                // intent's label is already the user's own
                                // words and has no translation to look up.
                                label: intent.label,
                                isSelected: widget.selected == intent,
                                onTap: () => _choose(intent),
                                // Editing a verb you wrote belongs on the verb
                                // itself, not on a settings screen somewhere
                                // else — this is the only place it is ever
                                // looked at.
                                onLongPress: () => _editCustom(intent),
                              ),
                            // Last, and in the grid rather than under it. As a
                            // full-width button below the row it was a second
                            // kind of control for what is the same act as the
                            // cells beside it — choosing the verb this
                            // screenshot gets. An empty outline in the next
                            // free slot says *there is room here for yours*
                            // with no words at all, which is what the outline
                            // was always for.
                            _IntentCell(
                              icon: Icons.add_rounded,
                              label: context.l10n.intentNewAction,
                              isSelected: false,
                              outlined: true,
                              onTap: _createCustom,
                            ),
                          ],
                        ),
                        // Only while there is nothing of their own to look at.
                        // Once somebody has written a verb, the sentence is
                        // explaining a thing they have already done.
                        if (mine.isEmpty) ...<Widget>[
                          SizedBox(height: 12.h),
                          Text(
                            context.l10n.intentYoursEmpty,
                            style: context.text.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                // The rule was drawn to separate this from the grid, and the
                // row is now a bordered control that separates itself. Two
                // devices doing one job is how a sheet ends up looking busy.
                SizedBox(height: 20.h),
                // Always offered, even when nothing is set. "Not for
                // anything" is a real answer to the question and not only
                // an undo — a screenshot can be worth keeping and owe you
                // nothing.
                _ClearRow(onTap: () => _finish(const IntentPickerResult(null))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _choose(IntentRef intent) {
    Haptics.confirm();
    // Tapping what is already set clears it, exactly as it does in the compact
    // row. The two pickers must not disagree about what a second tap means.
    _finish(IntentPickerResult(widget.selected == intent ? null : intent));
  }

  void _finish(IntentPickerResult result) {
    Navigator.of(context).pop(result);
  }

  Future<void> _createCustom() async {
    final CustomIntent? created = await showCustomIntentEditorSheet(context);
    if (created == null || !mounted) return;
    // Straight onto the screenshot. Somebody who just wrote "return it" wrote
    // it *about* the picture in front of them, and making them tap the chip
    // they have only now created is a step that exists for the code's benefit.
    _finish(IntentPickerResult(created));
  }

  Future<void> _editCustom(CustomIntent intent) async {
    await showCustomIntentEditorSheet(context, existing: intent);
    // The sheet writes through the catalog, which notifies; nothing to do here
    // but stay open on a list that has already updated itself.
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.text.bodySmall.asMedium.copyWith(
      color: context.colors.textSecondary,
      letterSpacing: 0.6,
    ),
  );
}

/// Lays its children out in four equal columns.
///
/// A [Wrap] of fixed-width cells rather than a [GridView], for the reason the
/// sheet is a [SingleChildScrollView] in the first place: this content is
/// short and must size itself: a grid view wants to be a scrollable of its own
/// and would have to be told a height it does not know.
///
/// Four is the number of short verbs that fit a 360pt phone with room for the
/// longest label in the longest language underneath each one. It is not
/// responsive on purpose — the column count changing between two phones would
/// change which verb sits where, and the whole value of a grid is that the
/// verb you reached for last time is where you left it.
class _IntentGrid extends StatelessWidget {
  final List<Widget> children;

  /// The sheet's own horizontal padding, which is the only thing between this
  /// grid and the width of the screen.
  static const double _sheetInset = 20;

  /// The narrowest a cell may be before a column is dropped.
  ///
  /// Set by the *label* rather than by the tile: this is what a two-line,
  /// centred "Herunterladen" needs at the base text size. Below it the grid
  /// stops being scannable and becomes a column of stubs.
  ///
  /// Seventy and not seventy-eight, and the difference is a whole column. An
  /// ordinary 360pt phone leaves 320pt for the grid; at 78 plus an 8pt gutter
  /// that divides into three, which is how this shipped for one build — wide
  /// tiles, five rows, and the user's own verbs pushed off the bottom of the
  /// screen. At 70 it divides into four with room to spare.
  static const double _minCell = 70;

  /// Never more than this, however wide the screen. A tablet has room for nine
  /// columns and should not use it — fifteen short words spread across a wide
  /// pane is a search rather than a glance.
  static const int _maxColumns = 6;

  const _IntentGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final double gap = 8.w;

    // **Measured from the screen rather than from a [LayoutBuilder]**, and
    // that is a performance decision rather than a stylistic one. A
    // `LayoutBuilder` moves its children's *build* into the layout phase, so
    // all twenty cells — twenty gesture detectors, twenty decorated boxes and
    // twenty pieces of wrapping, centred text — are constructed while the tree
    // is being measured, and again on any relayout. A bottom sheet is always
    // exactly as wide as the screen and this grid is always inset by the
    // sheet's own padding, so there is nothing here that needs measuring.
    final double width = MediaQuery.sizeOf(context).width - (_sheetInset * 2).w;

    // **Responsive by fit rather than by breakpoint.** A list of named phone
    // widths goes stale the week after it is written and says nothing about a
    // fold or a tablet. Asking how many labels actually fit answers all of
    // them the same way: four columns on an ordinary phone, three on a small
    // one, more only where there is genuinely room.
    //
    // **The text scale has to be in the sum, not just the screen width.**
    // ScreenUtil's `.w` scales with the *display*, so on its own it is blind
    // to the one setting that actually decides whether a word fits — somebody
    // running the system at 130% gets labels a third larger in a cell that
    // never moved, and "Herunterladen" spills out of it. Widening the minimum
    // by the same factor drops a column instead, which is the honest response
    // to bigger text.
    final double textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final double minCell = _minCell.w * textScale.clamp(1, 1.6);
    final int columns = (width / (minCell + gap)).floor().clamp(3, _maxColumns);
    final double cell = (width - gap * (columns - 1)) / columns;

    return Wrap(
      spacing: gap,
      runSpacing: 4.h,
      children: <Widget>[
        for (final Widget child in children)
          SizedBox(width: cell, child: child),
      ],
    );
  }
}

/// One verb: its glyph in a rounded square, its word underneath.
///
/// **The glyph gets a shape of its own, and that is what makes the grid
/// readable.** Laid out as bare icons over labels, twenty cells read as a wall
/// of grey marks; giving each glyph a filled tile gives the grid a rhythm of
/// identical shapes, so the eye lands on positions rather than re-reading
/// words. It is also where the selected state can live loudly — a filled tile
/// in the accent is unmistakable at arm's length, where a tinted pill among
/// twenty pills is not.
///
/// No [AnimatedContainer], deliberately. Selecting one closes the sheet in the
/// same gesture, so every implicit animation here would be twenty controllers
/// ticking for a transition **nobody ever sees**. The press itself is what
/// wants feedback, and [PressableScale] — the app's own idiom, already used by
/// everything else on this sheet — is what gives it.
class _IntentCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// An empty outline instead of a filled tile: the slot to write your own
  /// verb into, which is a place rather than a verb.
  final bool outlined;

  const _IntentCell({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color glyph = isSelected
        ? context.colors.onPrimary
        : context.colors.textSecondary;

    return PressableScale(
      scale: 0.92,
      onTap: onTap,
      // Handed over whole rather than wrapped in a haptic of its own:
      // [PressableScale] already fires one on long press, and the chip this
      // replaced only called it by hand because an [InkWell] fires none.
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  height: 52.w,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: outlined
                        ? Colors.transparent
                        : isSelected
                        ? context.colors.primary
                        : context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16.r),
                    border: outlined
                        ? Border.all(color: context.colors.border, width: 1.4)
                        : null,
                  ),
                  child: Icon(icon, size: 21.sp, color: glyph),
                ),
                // **A tick as well as the fill, and it is not decoration.**
                //
                // A tile in the accent reads as *chosen* only to somebody who
                // can see the other fourteen to compare it against — which
                // rules out the two people who most need to know: anyone who
                // has scrolled the selected one to the edge of the screen, and
                // anyone who cannot reliably separate the accent from the
                // surface. A tick means one thing on its own.
                if (isSelected)
                  Positioned(
                    top: -3.h,
                    right: -3.w,
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 16.sp,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 7.h),
            Text(
              label,
              textAlign: TextAlign.center,
              // Two lines, because this is where the long words go. A cell
              // that ellipsised "Herunterladen" would be a grid that works in
              // English and lies in German.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(
                height: 1.15,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearRow extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // **A real control rather than a grey line.**
    //
    // "Not for anything" is one of the three things this sheet is for — a
    // screenshot can be worth keeping and owe you nothing — and it was drawn
    // as secondary text under a divider, which is how an app says *this is the
    // small print*. It now looks like what it is: a full-width choice with a
    // border of its own and a label at reading weight, sitting apart from the
    // grid because it answers the question rather than filling it in.
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: context.colors.surfaceVariant.withValues(alpha: 0.6),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.not_interested_rounded,
              size: 18.sp,
              color: context.colors.textSecondary,
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                context.l10n.intentClear,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium.asMedium.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
