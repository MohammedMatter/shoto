import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/pro_badge.dart';

class HomeGreeting extends StatelessWidget {
  /// The clock this widget reads, overridable from a test and nowhere else.
  ///
  /// This is the only nondeterministic thing on Home, and it is enough to make
  /// a golden that asserts unusable: the same screen says "Good morning",
  /// "Good afternoon" or "Good evening" depending on the hour the suite is
  /// run, so a committed baseline would go red twice a day for no reason.
  ///
  /// A static rather than a constructor argument, because [HomeGreeting] is
  /// built by [HomePage] — threading a parameter down would put a test-only
  /// field on the page's public API to solve a problem that lives here.
  @visibleForTesting
  static DateTime Function()? debugClock;

  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final int hour = (debugClock?.call() ?? DateTime.now()).hour;
    final String greeting = hour < 12
        ? context.l10n.homeGreetingMorning
        : hour < 18
        ? context.l10n.homeGreetingAfternoon
        : context.l10n.homeGreetingEvening;

    // **First name only, and only if there is one.**
    //
    // "Good afternoon" is a screen. "Good afternoon, Mohammed" is the app
    // talking to the person holding it, and it costs one word — the single
    // cheapest warmth available on a page that is otherwise all counters.
    //
    // First name rather than the full one because the display name that comes
    // back from Google is whatever the account has, which is regularly three
    // words long and would wrap the headline onto two lines to say nothing
    // extra.
    //
    // Read through `isRegistered` rather than `sl<AuthRepository>()` directly,
    // because this widget renders in a golden test that registers four
    // services and no auth. A greeting is not worth a crash, and "no name" is
    // a real state anyway — it is what a user with no display name gets.
    // **A display name is untrusted input.** It is whatever the Google or
    // Apple account has in it, which is regularly three words, occasionally a
    // company, and can be any length at all — this headline has no business
    // trusting it to be "Mohammed".
    //
    // Three guards, in order. Split on *any* run of whitespace (a name pasted
    // with a double space would otherwise yield an empty first token); take
    // only the first word; and refuse anything past 24 characters outright,
    // falling back to the plain greeting. Past that length it is not a first
    // name, and shrinking it to fit would just put six-point type on the
    // largest line of the page.
    //
    // Between those bounds the name is *scaled*, never ellipsised — see the
    // `FittedBox` below. Cutting somebody's name in half reads as a bug about
    // them personally, which is the one thing a greeting must not do.
    final String? rawName = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUser?.name?.trim()
        : null;
    final String? firstWord = (rawName == null || rawName.isEmpty)
        ? null
        : rawName.split(RegExp(r'\s+')).first;
    final String? name = (firstWord != null && firstWord.length <= 24)
        ? firstWord
        : null;
    // Formatted through the app's own locale rather than the device's, which
    // are allowed to disagree here: Shoto has its own language picker, and a
    // date in a language the rest of the screen is not written in is the kind
    // of detail that reads as a bug even when nobody can say why.
    final Locale locale = Localizations.localeOf(context);
    final DateTime now = debugClock?.call() ?? DateTime.now();
    final String date = DateFormat.yMMMMd(locale.toLanguageTag()).format(now);
    final String weekday = DateFormat.EEEE(locale.toLanguageTag()).format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Centred, and the greeting is now the headline rather than a label
        // above the product's own name.
        //
        // The name was the largest thing on Home, which is a poster rather
        // than a screen — somebody who has opened the app already knows what
        // it is called, and the mark in the corner says so anyway. Giving the
        // top of the page to the greeting spends that space on the one line
        // that is actually different every time it is read.
        // **Two lines on purpose, rather than one that wraps.**
        //
        // "Good afternoon, Mohammed" on one headline line does not fit a
        // 360dp phone, so it broke after the comma and left the Pro badge
        // floating beside a two-line block with nothing to align to. A wrap is
        // the layout giving up; a stack is the layout deciding.
        //
        // It also ranks the two halves correctly. The greeting is the same
        // every afternoon and the name is the part that makes the screen
        // somebody's, so the name takes the headline and the greeting becomes
        // the label above it — the shape this page already used for
        // `Good afternoon / Shoto`, with the person in the slot the product
        // name used to occupy.
        if (name != null && name.isNotEmpty) ...[
          Text(
            greeting,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: 2.h),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              // `scaleDown` shrinks a long name to fit and leaves a short one
              // at full size — it never enlarges. So "Mo" and "Abdurrahman"
              // both render whole, one at the headline size and one a few
              // points under it, and neither arrives with a full stop where
              // the rest of somebody's name should be.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  (name == null || name.isEmpty) ? greeting : name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  softWrap: false,
                  style: context.text.headlineLarge.copyWith(
                    color: context.colors.textPrimary,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            const ProBadgeIfSubscribed(),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          '$date · $weekday',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
