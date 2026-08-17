import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_tint.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/settings/presentation/widgets/appearance_card.dart';

/// Reports whether the accent was actually taken.
///
/// **A `ValueChanged` cannot express this and the sheet needs it.** Choosing a
/// tint can raise a paywall, and a paywall can be declined — so "the user
/// tapped plum" and "the app is now plum" are different facts. The card on the
/// page never has to care, because its ring is driven by the controller and
/// simply does not move when nothing changed. The sheet is a route of its own
/// with its own state, so without an answer it would light the ring on a
/// colour the user just refused to pay for.
typedef TintSelected = Future<bool> Function(AppTint tint);

/// The six accents on the page, and the way to the other ten.
///
/// Drawn in the same [AppearanceCard] as every other group on that page — see
/// `appearance_card.dart` for why this page carries containers where Settings
/// deliberately does not.
class TintSection extends StatelessWidget {
  final AppTint value;
  final TintSelected onSelect;

  const TintSection({super.key, required this.value, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return AppearanceCard(
      // The grid and its overflow row are one control, not two rows — the
      // hairline between them is drawn here so it lands under the grid rather
      // than between every child of it.
      divided: false,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 14.h),
          child: _SwatchGrid(
            tints: AppTint.front,
            columns: 3,
            value: value,
            // Fire and forget: this grid's ring comes from the controller one
            // rebuild later, so a declined paywall leaves it exactly where it
            // was without anyone having to undo anything.
            onTap: (AppTint tint) => onSelect(tint),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 16.w),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.colors.border,
          ),
        ),
        // **Named for what is behind it, not for what it does.** "More
        // colours" is a promise about the next screen; "Custom" or "Other"
        // would be a promise about a colour wheel this deliberately does not
        // offer — every accent here is solved, and a free-form picker would be
        // the one door back to the raw hexes the whole system exists to avoid.
        _MoreRow(
          value: value,
          onSelect: onSelect,
          // Lit when the accent in force is not one of the six above, so the
          // row states where the answer is rather than leaving a page with no
          // selection visible anywhere on it.
          trailingTint: AppTint.front.contains(value) ? null : value,
        ),
      ],
    );
  }
}

/// A grid of swatches, shared by the card and the sheet.
///
/// One implementation across both because they are the same control at two
/// widths — three across on the page, four in the sheet. Two copies is how the
/// selected ring ends up two different thicknesses in two places.
class _SwatchGrid extends StatelessWidget {
  final List<AppTint> tints;
  final int columns;
  final AppTint value;
  final ValueChanged<AppTint> onTap;

  const _SwatchGrid({
    required this.tints,
    required this.columns,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      // The page or the sheet is the scrollable; this is a fixed block inside
      // it. Its own physics would trap a drag started on a swatch.
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 10.w,
      // A wide, short cell: the swatch is a rounded rectangle rather than a
      // circle, so it reads as a *sample of a surface* — which is what an
      // accent is — instead of as a dot, which reads as a status light.
      childAspectRatio: columns == 3 ? 1.15 : 1.05,
      children: <Widget>[
        for (final AppTint tint in tints)
          _Swatch(
            tint: tint,
            isSelected: tint == value,
            onTap: () => onTap(tint),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final AppTint tint;
  final bool isSelected;
  final VoidCallback onTap;

  const _Swatch({
    required this.tint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = tint.accent(isDark: context.colors.isDark);

    return PressableScale(
      scale: 0.94,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.normal),
              curve: AppMotion.standard,
              width: double.infinity,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                // **The ring sits on the swatch, not around it.**
                //
                // Drawn inside the shape's own bounds so selecting never
                // changes a cell's size and never reflows the grid — and in
                // `onPrimary` rather than in the accent, because a ring in the
                // same colour as the fill it surrounds is invisible. That is
                // also the second place this system pays for itself: one
                // foreground token is legible on all sixteen.
                border: Border.all(
                  color: isSelected
                      ? context.colors.onPrimary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: isSelected ? 1 : 0.4,
                duration: AppMotion.duration(context, AppMotion.press),
                curve: AppMotion.standard,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1 : 0,
                  duration: AppMotion.duration(context, AppMotion.press),
                  curve: AppMotion.standard,
                  child: Icon(
                    Icons.check_rounded,
                    size: 18.sp,
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            tint.label(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.caption
                .weight(
                  isSelected ? AppTypography.semiBold : AppTypography.regular,
                )
                .copyWith(
                  color: isSelected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  final AppTint value;
  final TintSelected onSelect;

  /// Drawn as a small swatch at the end of the row when the accent in force
  /// lives behind this row rather than in the grid above it.
  final AppTint? trailingTint;

  const _MoreRow({
    required this.value,
    required this.onSelect,
    this.trailingTint,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      feedback: PressFeedback.highlight,
      onTap: () => showTintSheet(context, value: value, onSelect: onSelect),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.appearanceMoreColors,
                style: context.text.bodyLarge,
              ),
            ),
            if (trailingTint case final AppTint tint) ...[
              Container(
                width: 20.w,
                height: 20.w,
                decoration: BoxDecoration(
                  color: tint.accent(isDark: context.colors.isDark),
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(width: 10.w),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// All twelve, four across.
///
/// **It applies on tap and closes on Done, which are two different things.**
/// The tap recolours the app immediately — the sheet covers only part of the
/// screen, so the change is visible behind it while the grid is still open,
/// and that is the whole reason this is a sheet rather than a pushed page.
/// Done dismisses; there is nothing to confirm and nothing to cancel, because
/// every tap has already been honoured.
Future<void> showTintSheet(
  BuildContext context, {
  required AppTint value,
  required TintSelected onSelect,
}) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => SheetSurface(
      child: SafeArea(
        top: false,
        child: _TintSheetBody(
          initial: value,
          onSelect: onSelect,
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    ),
  );
}

/// Stateful only so the ring follows the finger.
///
/// The controller behind [onChanged] is the source of truth and the app is
/// already repainting from it — but this sheet is raised over a page that
/// rebuilds *underneath* it, and a `ModalBottomSheet` is a route of its own
/// with its own element tree. Without local state the swatch just tapped would
/// keep its old ring until the sheet was closed and reopened.
class _TintSheetBody extends StatefulWidget {
  final AppTint initial;
  final TintSelected onSelect;
  final VoidCallback onDone;

  const _TintSheetBody({
    required this.initial,
    required this.onSelect,
    required this.onDone,
  });

  @override
  State<_TintSheetBody> createState() => _TintSheetBodyState();
}

class _TintSheetBodyState extends State<_TintSheetBody> {
  late AppTint _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 6.h, 12.w, 6.h),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.appearanceSelectTint,
                  style: context.text.titleLarge,
                ),
              ),
              // A text button rather than an ✕, because this sheet has no
              // cancel: every choice made inside it is already in force, so
              // the only honest word for the way out is the one that means
              // "finished".
              PressableScale(
                scale: 0.94,
                onTap: widget.onDone,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  child: Text(
                    context.l10n.commonDone,
                    style: context.text.bodyLarge.asMedium.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
            child: _SwatchGrid(
              tints: AppTint.all,
              columns: 4,
              value: _value,
              // **The ring moves only once the accent has actually changed.**
              //
              // Setting it first and correcting later would be the obvious
              // thing to write and would lie for as long as the paywall is up:
              // the sheet would be showing a chosen colour behind a screen
              // asking to be paid for it.
              onTap: (AppTint tint) async {
                if (!await widget.onSelect(tint)) return;
                if (mounted) setState(() => _value = tint);
              },
            ),
          ),
        ),
      ],
    );
  }
}
