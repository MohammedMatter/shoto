import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/safe_share/presentation/pages/safe_share_page.dart';
import 'package:shoto/features/screenshots/presentation/widgets/shared_image_choice_sheet.dart';
import 'package:shoto/l10n/app_localizations.dart';

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
  Future<void> render(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.light),
          home: Scaffold(body: sharedImageChoiceContent()),
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
