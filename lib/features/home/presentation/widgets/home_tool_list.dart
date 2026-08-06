import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/features/duplicates/presentation/pages/duplicates_page.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/widgets/import_screenshots_action.dart';

class HomeToolList extends StatelessWidget {
  final ValueChanged<LibraryIntent> onOpenLibraryForIntent;
  final bool hasLibrary;

  const HomeToolList({
    super.key,
    required this.onOpenLibraryForIntent,
    required this.hasLibrary,
  });

  VoidCallback _orImportFirst(BuildContext context, VoidCallback whenReady) {
    if (hasLibrary) return whenReady;
    return () =>
        importScreenshots(context, bloc: context.read<ScreenshotsBloc>());
  }

  @override
  Widget build(BuildContext context) {
    final List<_Tool> tools = [
      if (hasLibrary)
        _Tool(
          icon: Icons.add_photo_alternate_outlined,
          tint: context.colors.marker,
          title: context.l10n.importTitle,
          subtitle: context.l10n.homeToolImportSubtitle,
          onTap: () =>
              importScreenshots(context, bloc: context.read<ScreenshotsBloc>()),
        ),
      _Tool(
        icon: Icons.shield_moon_rounded,
        tint: context.colors.secondary,
        title: context.l10n.homeToolSafeShare,
        subtitle: context.l10n.homeToolSafeShareSubtitle,
        onTap: _orImportFirst(
          context,
          () => onOpenLibraryForIntent(LibraryIntent.protect),
        ),
      ),
      _Tool(
        icon: Icons.content_copy_rounded,
        tint: context.colors.error,
        title: context.l10n.homeToolDuplicates,
        subtitle: context.l10n.homeToolDuplicatesSubtitle,
        onTap: _orImportFirst(context, () async {
          if (!await ensurePremium(context)) return;
          if (!context.mounted) return;
          await Navigator.of(
            context,
          ).push(FadeSlidePageRoute(builder: (_) => const DuplicatesPage()));
        }),
      ),
      _Tool(
        icon: Icons.photo_size_select_large_rounded,
        tint: context.colors.success,
        title: context.l10n.homeToolStitch,
        subtitle: context.l10n.homeToolStitchSubtitle,
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
            Divider(height: 1, thickness: 1, color: context.colors.border),
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
                  Text(tool.title, style: context.text.titleSmall),
                  SizedBox(height: 2.h),
                  Text(
                    tool.subtitle,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textDisabled,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
