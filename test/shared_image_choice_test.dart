import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/sheet_surface.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/shared_image_choice_sheet.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// **What the share sheet is allowed to assume the user meant.**
///
/// A picture handed to Shoto from another app used to be imported into the
/// gallery and the library on arrival, and only then was anything asked — so
/// the person who shared a screenshot in order to cover an account number had
/// already gained a library item they never chose, and was offered a folder
/// for it. The one moment this product exists for was answered with filing.
///
/// The offer now comes first, and the answer decides whether anything is kept.
void main() {
  setUp(() {
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    // Tapping an option fires a haptic, and the haptic reads this at call
    // time — unregistered, it throws out of the gesture handler and the tap
    // does nothing at all, which reads as the option not being wired up.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// Renders the sheet's contents inline.
  ///
  /// Deliberately not `showSharedImageChoiceSheet` plus a tap: the sheet's
  /// surface animates continuously, so `pumpAndSettle` never returns and
  /// awaiting the route's pop future deadlocks the test — the same trap the
  /// golden tests document for the scanning state. What is worth asserting
  /// here is the offer itself, not that `Navigator.pop` returns its argument.
  Future<void> render(
    WidgetTester tester, {
    String locale = 'en',
    Brightness brightness = Brightness.light,
    ValueChanged<SharedImageChoice>? onChoice,
  }) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(brightness),
          home: Scaffold(
            // Pinned to the top and keyed so the golden below frames the
            // sheet rather than the page it is standing on. A shot that is
            // four fifths empty background fails for changes to the
            // background, and hides changes to the two centimetres that
            // matter.
            body: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const ValueKey<String>('sheet'),
                child: SheetSurface(
                  child: sharedImageChoiceContent(
                    onChoice: onChoice ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('both answers are offered', (tester) async {
    await render(tester);
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.shareChoiceProtect), findsOneWidget);
    expect(find.text(l10n.shareChoiceSave), findsOneWidget);
  });

  testWidgets('covering is the one offered first', (tester) async {
    // The claim, asserted as a position rather than as a comment. Filing is
    // what every gallery on the phone already does; covering is the reason
    // this app was installed, and it should not be the second thing read.
    await render(tester);
    final AppLocalizations l10n = await english();

    final double protect = tester.getTopLeft(
      find.text(l10n.shareChoiceProtect),
    ).dy;
    final double save = tester.getTopLeft(find.text(l10n.shareChoiceSave)).dy;

    expect(protect, lessThan(save));
  });

  testWidgets('the offer says the covered one is not kept', (tester) async {
    // Because that is the part the user cannot verify afterwards, and the
    // part the old behaviour got wrong silently.
    await render(tester);
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.shareChoiceProtectHint), findsOneWidget);
    expect(l10n.shareChoiceProtectHint.toLowerCase(), contains('not saved'));
  });

  testWidgets('each answer reports itself', (tester) async {
    // Testable at all only since the offer started reporting through a
    // callback instead of popping a route. It was worth making testable: the
    // two rows are built from the same widget with the same shape, and the
    // failure this catches — both of them wired to `save`, or the pair
    // swapped — is invisible on screen and sends a card number to whoever the
    // user picked next.
    final List<SharedImageChoice> answers = [];
    await render(tester, onChoice: answers.add);
    final AppLocalizations l10n = await english();

    await tester.tap(find.text(l10n.shareChoiceProtect));
    await tester.tap(find.text(l10n.shareChoiceSave));

    expect(answers, [SharedImageChoice.protect, SharedImageChoice.save]);
  });

  test('covering is offered for one picture and no other count', () {
    // The rule both share paths now read, asserted once. Safe Share reviews a
    // single capture and marks its findings on that image; an offer spanning
    // four would have to act on one of them and let the user send the rest
    // believing all four were checked.
    expect(coveringOffered(1), isTrue);
    expect(coveringOffered(0), isFalse);
    expect(coveringOffered(2), isFalse);
    expect(coveringOffered(30), isFalse);
  });

  test('a picture Shoto handed out is not offered covering again', () {
    // Covering ends at the system share sheet and Shoto is one of the choices
    // there, so the covered copy can come straight back in. Asking whether to
    // cover it is asking a question the previous screen already answered.
    expect(coveringOffered(1, fromShotoItself: true), isFalse);
  });

  testWidgets('share choice sheet — german', (tester) async {
    // **German because it is the longest.** Both option titles wrap there and
    // the sheet stands 335dp against Spanish's 298 — so a layout that holds
    // here holds in the other six.
    //
    // Measuring overflow programmatically, which is what this file did first,
    // catches text escaping its box and nothing else. It cannot see a subtitle
    // colliding with an icon, or spacing that reads as two unrelated blocks.
    // The paywall is the argument for having this at all: five strings there
    // described a deleted feature for months, in seven languages, behind a
    // green suite — because that screen has no golden and the onboarding
    // slide, which does, failed the moment its copy changed.
    await loadTestFonts();
    await render(tester, locale: 'de', brightness: Brightness.dark);

    await expectLater(
      find.byKey(const ValueKey<String>('sheet')),
      matchesGoldenFile('goldens/share_choice_german.png'),
    );
  });

  test('the covering path is not backed by a library item', () {
    // The promise, asserted structurally. `SafeSharePage.incoming` carries a
    // file and no entity, so there is nothing for it to have imported — the
    // import in `ShareIntentListener` lives on the save path only.
    //
    // Said the other way round: if this ever gains a screenshot, somebody has
    // put the shared picture into the library in order to open this screen,
    // and "nothing joins your library until you say so" has stopped being
    // true on the path where it matters most.
    final SafeSharePage page = SafeSharePage.incoming(
      incoming: File('/tmp/whatever.png'),
    );
    expect(page.screenshot, isNull);
    expect(page.incoming, isNotNull);
  });
}
