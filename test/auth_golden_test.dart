import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';
import 'package:shoto/features/auth/presentation/pages/auth_page.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The first screen anybody sees, rendered so it can be *looked at*.
///
/// [AuthBody] exists precisely so this file can reach it: the page itself
/// wants a service locator and a bloc, and neither has anything to say about
/// whether the screen makes a person want to continue. Same split, and the
/// same reason, as `debugSubscriptionCardStates`.
///
/// Both providers are forced on for most of these. On a Windows machine
/// `Platform.isIOS` is false, so the one-button layout is what would be
/// photographed by default — and the two-button layout is the one that has to
/// survive a short screen, which is the case worth checking.
///
/// **Both counts are photographed, because they are different compositions and
/// not one composition with a row missing.** Apple is offered on Apple's
/// platforms only, so the majority of installs see a single button — and the
/// emphasis rule in [SocialSignInButton] moves the filled slab onto it when it
/// is alone. A screen whose one committed shape appears only in the layout
/// nobody photographed is exactly the kind of thing that ships wrong.
void main() {
  Future<void> open(
    WidgetTester tester, {
    required Brightness brightness,
    AuthMethod? loading,
    Size size = const Size(1080, 2100),
    double textScale = 1,
    String locale = 'en',
    bool apple = true,

    /// False when the frame holds a spinner. `pumpAndSettle` waits for the
    /// tree to stop changing and a [CircularProgressIndicator] never does —
    /// the same trap `library_filter_row_golden_test` documents.
    bool settle = true,
  }) async {
    await loadTestFonts();

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: AuthBody(
                loading: loading,
                onGoogle: () {},
                onApple: () {},
                showApple: apple,
              ),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      // Past the end of the page's 760ms entrance, so what is photographed is
      // the screen at rest with a spinner in it rather than the screen halfway
      // through arriving.
      await tester.pump(const Duration(milliseconds: 900));
    }
  }

  testWidgets('sign in — light', (WidgetTester tester) async {
    await open(tester, brightness: Brightness.light);
    await expectLater(
      find.byType(AuthBody),
      matchesGoldenFile('goldens/auth_light.png'),
    );
  });

  testWidgets('sign in — dark', (WidgetTester tester) async {
    await open(tester, brightness: Brightness.dark);
    await expectLater(
      find.byType(AuthBody),
      matchesGoldenFile('goldens/auth_dark.png'),
    );
  });

  /// What Android sees: Google alone, and therefore Google as the slab.
  testWidgets('sign in — one provider', (WidgetTester tester) async {
    await open(tester, brightness: Brightness.light, apple: false);
    await expectLater(
      find.byType(AuthBody),
      matchesGoldenFile('goldens/auth_one_provider.png'),
    );
  });

  testWidgets('sign in — signing in', (WidgetTester tester) async {
    await open(
      tester,
      brightness: Brightness.light,
      loading: AuthMethod.google,
      settle: false,
    );
    await expectLater(
      find.byType(AuthBody),
      matchesGoldenFile('goldens/auth_loading.png'),
    );
  });

  /// **The case the old layout could not survive.** It spaced itself with
  /// `Spacer(flex: 3)` and `Spacer(flex: 4)`, which is fine on a tall phone
  /// and overflows on a small one at large system text — two buttons, a
  /// paragraph and a legal line with nowhere to go. A short screen at 130%
  /// type is the honest test of that, in German, where every string is
  /// longest.
  testWidgets('sign in — small screen, large text, German', (
    WidgetTester tester,
  ) async {
    await open(
      tester,
      brightness: Brightness.light,
      size: const Size(1080, 1560),
      textScale: 1.3,
      locale: 'de',
    );
    await expectLater(
      find.byType(AuthBody),
      matchesGoldenFile('goldens/auth_small_german.png'),
    );
  });
}
