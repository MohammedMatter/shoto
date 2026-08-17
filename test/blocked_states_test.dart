import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/pages/intent_page.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// **An unread library is not an empty one.**
///
/// Every screen reading [ScreenshotsState] has four cases and gets one of them
/// for free — *loaded* is its own job. The other three were being folded away,
/// each screen differently, and the fold is invisible in review because `is!`
/// reads like a guard rather than like four branches collapsing into one.
///
/// Home folded them into *loading* and drew a spinner forever behind a refused
/// permission. `IntentPage` folded them into *empty*, and an empty waiting list
/// there is not blank — it is a green tick and "you're all done". A screen that
/// had never been allowed to read the gallery was congratulating the user for
/// clearing it.
///
/// So the assertions here are in two halves, and the second is the one that
/// matters: the blocked states must explain themselves, **and** the success
/// state must not be borrowed to do it.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const IntentRef intent = BuiltInIntent(ScreenshotIntent.buy);

  setUp(() {
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
  });

  Future<void> render(WidgetTester tester, ScreenshotsState state) async {
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
          home: BlocProvider<ScreenshotsBloc>(
            create: (_) => _StubScreenshotsBloc(state),
            child: const IntentPage(intent: intent),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  testWidgets('a refused permission is not a finished list', (tester) async {
    await render(tester, ScreenshotsPermissionDeniedState());
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.permissionNeededTitle), findsOneWidget);
    expect(find.text(l10n.permissionOpenSettings), findsOneWidget);

    // The half that would have caught the original bug. Everything above
    // could pass while the tick was still on screen underneath.
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('partial access says so rather than looking tidy', (
    tester,
  ) async {
    // "Select photos…" hides the Screenshots album entirely, so the honest
    // answer is not an empty list — it is that the app cannot see the album.
    await render(
      tester,
      ScreenshotsPermissionDeniedState(isPartialAccess: true),
    );
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.permissionPartialTitle), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('a failed read offers a retry, not congratulations', (
    tester,
  ) async {
    await render(
      tester,
      ScreenshotsErrorState(AppMessage.loadScreenshots),
    );
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.commonSomethingWentWrong), findsOneWidget);
    expect(find.text(l10n.commonRetry), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('still reading is not finished reading', (tester) async {
    await render(tester, ScreenshotsLoadingState());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('the tick belongs to a list that was actually read', (
    tester,
  ) async {
    // The other side of the contract: with the library loaded and nothing
    // waiting, the celebration is earned and must still appear.
    await render(tester, ScreenshotsLoadedState(screenshots: const []));

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
