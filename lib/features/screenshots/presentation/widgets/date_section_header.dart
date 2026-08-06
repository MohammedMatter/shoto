import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/utils/date_sections.dart';

/// The sticky heading over a run of screenshots from the same stretch of time.
///
/// Opaque rather than translucent on purpose: it is pinned, so tiles scroll
/// underneath it, and a blurred or tinted heading over photographs turns into
/// an unreadable smear the moment a light screenshot passes behind it.
class DateSectionHeader extends StatelessWidget {
  final DateSection section;

  /// Kept in step with [SectionedIdGrid.headerExtent] at the call site — a
  /// pinned header has to declare its height before it is laid out, so the
  /// number cannot be discovered from the widget.
  static double get extent => 38.h;

  const DateSectionHeader({super.key, required this.section});

  String _label(BuildContext context) => switch (section.kind) {
    DateSectionKind.today => context.l10n.dateToday,
    DateSectionKind.yesterday => context.l10n.dateYesterday,
    DateSectionKind.thisWeek => context.l10n.dateThisWeek,
    DateSectionKind.thisMonth => context.l10n.dateThisMonth,
    // Formatted rather than a translated string per month: `intl` already
    // carries every month name for every locale the app ships, and the year
    // is dropped inside the current one because "March 2026" in March 2026
    // is three words where one would do.
    DateSectionKind.month => DateFormat(
      section.month!.year == DateTime.now().year ? 'MMMM' : 'MMMM yyyy',
      Localizations.localeOf(context).toString(),
    ).format(section.month!),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.background,
      alignment: AlignmentDirectional.centerStart,
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        _label(context),
        style: context.text.bodySmall.asMedium.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
