import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_motion.dart';

import 'package:shoto/core/widgets/sheet_surface.dart';

/// What the user meant by sharing a picture *into* Shoto.
enum SharedImageChoice {
  /// Cover what is private and send it on. The picture never enters the
  /// library.
  protect,

  /// Keep it, and file it.
  save,
}

/// Asks which of the two, once, on the way in.
///
/// **The share sheet used to answer this on the user's behalf, and answered it
/// wrong.** Every picture handed to Shoto was imported into the library and
/// followed by "which folder?" — filing, which is the one thing every other
/// gallery app on the phone already does. The single moment this product
/// exists for arrives here: somebody is looking at a screenshot they want to
/// send and can't, because their account number is in it. That person was
/// being offered an archive.
///
/// Covering was reachable, but only from inside: open the app, find the
/// library, pick the screenshot, open its actions, choose Safe Share. Four
/// taps into a tool nobody knew was there, for the reason they installed it.
///
/// Two answers, no default. It does not guess from the picture, because
/// guessing here is how the wrong one becomes the quiet one.
Future<SharedImageChoice?> showSharedImageChoiceSheet(BuildContext context) {
  return showAppSheet<SharedImageChoice>(
    context: context,
    builder: (sheetContext) => SheetSurface(child: sharedImageChoiceContent()),
  );
}

/// The sheet's body without the sheet.
///
/// Exposed so the offer can be tested at all: [SheetSurface] animates
/// continuously, so `pumpAndSettle` never returns on it and awaiting the
/// route's pop future deadlocks — the trap the golden tests already document
/// for the scanning state. The thing worth asserting is which answers are
/// offered and in what order, and none of that lives in the surface.
Widget sharedImageChoiceContent() => _Content();

class _Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.shareChoiceTitle,
            style: context.text.titleLarge,
          ),
          SizedBox(height: 14.h),

          // Covering leads, because it is the reason this sheet exists and
          // the reason the app does. Filing is what the phone already offers
          // everywhere else. Asserted as a position in
          // `shared_image_choice_test.dart`, not left to this comment.
          _Option(
            icon: Icons.shield_moon_rounded,
            tint: context.colors.secondary,
            title: context.l10n.shareChoiceProtect,
            subtitle: context.l10n.shareChoiceProtectHint,
            onTap: () =>
                Navigator.of(context).pop(SharedImageChoice.protect),
          ),
          SizedBox(height: 10.h),
          _Option(
            icon: Icons.add_photo_alternate_outlined,
            tint: context.colors.marker,
            title: context.l10n.shareChoiceSave,
            subtitle: context.l10n.shareChoiceSaveHint,
            onTap: () => Navigator.of(context).pop(SharedImageChoice.save),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.99,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: tint, size: 19.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: context.text.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
