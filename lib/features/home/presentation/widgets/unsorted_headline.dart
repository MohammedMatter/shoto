import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';

/// **There is no loading branch here any more, and there must never be one
/// again.**
///
/// This widget used to take an `isLoading` flag whose entire behaviour was
/// `return const SizedBox.shrink()`, and Home routed both of its transient
/// states into it. The result was that closing the app and reopening it drew a
/// hole where the main block goes, in a page laid out as though the library
/// were empty, until the gallery read finished and everything jumped into
/// place.
///
/// Pending is now somebody else's job — `HomeInbox.preview` draws the real
/// counts from the local tables, and `HomeInboxSkeleton` holds the space in the
/// frames before even those are known. What is left here is one thing: the
/// invitation shown to a library that genuinely has nothing in it.
class UnsortedHeadline extends StatelessWidget {
  final int unsortedCount;
  final bool hasLibrary;
  final ValueChanged<LibraryFilter> onTap;
  final VoidCallback onImport;

  const UnsortedHeadline({
    super.key,
    required this.unsortedCount,
    required this.hasLibrary,
    required this.onTap,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final bool needsAttention = hasLibrary && unsortedCount > 0;

    if (!needsAttention) {
      final String headline = !hasLibrary
          ? context.l10n.homeInboxEmpty
          : context.l10n.homeInboxClear;

      final String detail = !hasLibrary
          ? context.l10n.homeInboxEmptySubtitle
          : context.l10n.homeInboxClearSubtitle;

      return PressableScale(
        scale: 0.99,
        onTap: hasLibrary ? () => onTap(LibraryFilter.all) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(headline, style: context.text.headlineMedium),
            SizedBox(height: 5.h),
            Text(
              detail,
              style: context.text.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
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
      onTap: () => onTap(LibraryFilter.unsorted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Count(unsortedCount, style: context.text.displayHero),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeInboxCountSubtitle,
                  style: context.text.bodyLarge.asMedium.copyWith(
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 2,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.arrow_forward_rounded,
                color: context.colors.marker,
                size: 19.sp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final int value;
  final TextStyle style;

  const _Count(this.value, {required this.style});

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return Text('$value', style: style);

    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 420),
      curve: AppMotion.standard,
      tween: IntTween(begin: 0, end: value),
      builder: (context, current, _) => Text('$current', style: style),
    );
  }
}
