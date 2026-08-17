import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';

/// Picks the app's language.
///
/// A sheet rather than the segmented pills used for theme and grid density:
/// six options with long names in six different scripts do not fit in a row,
/// and squeezing them there is how you end up with a picker nobody can read
/// the options of.
Future<void> showLanguageSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = sl<LocaleController>();

    // **Which row wears the tick when nothing has been chosen yet.**
    //
    // A fresh install has no preference stored, and the app runs in whatever
    // the phone asked for. With "Match my phone" gone from the list there is no
    // row standing for that state, so the tick goes on the language actually
    // being read — which is both true and the only answer that is any use to
    // somebody looking at the sheet.
    final AppLanguage current = controller.language ?? controller.effectiveLanguage;

    return SheetSurface(
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text(context.l10n.settingsLanguage, style: context.text.titleLarge),
            SizedBox(height: 6.h),

            // **"Match my phone" is gone**, and with it the divider that used
            // to fence it off from the real languages.
            //
            // It was a defensible option and it was the wrong first row. It is
            // the only entry in the list that does not name a language, so the
            // one thing somebody opening a language picker is looking for —
            // their language — was never the first thing on the screen. It also
            // could not be read: to know what "Match my phone" would give you,
            // you had to read a second line explaining which language that
            // currently meant, which is a row that exists to explain itself.
            //
            // Following the phone is still the state a fresh install is in.
            // Nothing forces a choice; the picker simply no longer offers
            // "whatever the system says" as if it were a language alongside
            // seven that are.
            for (final AppLanguage language in AppLanguage.values)
              _Row(
                // Its own name, in its own script. Somebody who needs Urdu is
                // looking for اردو, and cannot be expected to find it under a
                // row that says "Urdu" in a language they don't read.
                language: language,
                selected: language == current,
                onTap: () {
                  controller.setLanguage(language);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One language, on one line.
///
/// **This was a bordered card two lines tall, and eight of them made a sheet
/// most of a phone high.** Every row drew its own outline and its own fill, so
/// a list of seven peers arrived as seven objects with gaps between them — and
/// the endonym and the English name were stacked, which doubled the height of
/// the sheet to say two words that fit comfortably on one line beside each
/// other.
///
/// Now it is a row: the language's own name where the eye starts, its English
/// name at the far end in the quietest colour on the palette, and a tick when
/// it is the one in use. Hairlines between, no fills, nothing selected drawn as
/// a *box* — the tick is what says which, because that is what a tick is for.
/// The sheet is roughly half the height it was and every option is on screen at
/// once, which is the only thing a picker is really being asked to do.
class _Row extends StatelessWidget {
  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _Row({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      // A tint rather than a shrink: these are full-width rows in a scrollable,
      // and the sheet scrolls on a short phone. See [PressFeedback].
      feedback: PressFeedback.highlight,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.colors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language.endonym,
                style: context.text.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Dropped entirely when it would only repeat the endonym —
            // "English · English" is a row apologising for itself.
            if (language.englishName != language.endonym) ...<Widget>[
              SizedBox(width: 12.w),
              Text(
                language.englishName,
                style: context.text.caption.copyWith(
                  color: context.colors.textDisabled,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(width: 12.w),
            // A fixed box either way, so the names do not shift sideways by the
            // width of a tick as the selection moves down the list.
            SizedBox(
              width: 20.sp,
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: context.colors.primary,
                      size: 20.sp,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
