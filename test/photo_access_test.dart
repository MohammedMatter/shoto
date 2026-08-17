import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_event.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_unavailable.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// **Never asked is not the same as refused, and Android cannot tell them
/// apart.**
///
/// `PermissionState` reports *denied* for somebody who pressed No and for
/// somebody who has never seen the dialog, so the app remembers whether it
/// put the question. Getting that wrong is not cosmetic in either direction:
///
/// - Treating *unasked* as *refused* opens a fresh install on "go to your
///   phone's settings", for an app installed thirty seconds ago, with the
///   dialog it needs never having been shown.
/// - Treating *refused* as *unasked* offers a button that raises a dialog
///   Android will silently decline to show, so the button does nothing,
///   twice, forever.
///
/// The request itself moved out of the library load for the same reason the
/// distinction exists. Loading happens at launch, on tab select and behind a
/// retry, and while it asked, the system dialog appeared over somebody who
/// had just finished the introduction and done nothing else — spending the
/// one prompt Android grants at the moment they had least reason to accept.
class _StubBloc extends Cubit<ScreenshotsState> implements ScreenshotsBloc {
  _StubBloc(super.initialState);

  final List<ScreenshotsEvent> received = <ScreenshotsEvent>[];

  @override
  void add(ScreenshotsEvent event) => received.add(event);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late AppPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    preferences = AppPreferences();
    await preferences.load();
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    // PrimaryButton reads the haptics preference on tap.
    if (sl.isRegistered<AppPreferences>()) sl.unregister<AppPreferences>();
    sl.registerSingleton<AppPreferences>(preferences);
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  Future<_StubBloc> render(WidgetTester tester, ScreenshotsState state) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final _StubBloc bloc = _StubBloc(state);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.light),
          home: BlocProvider<ScreenshotsBloc>.value(
            value: bloc,
            child: Scaffold(body: LibraryUnavailable(state: state)),
          ),
        ),
      ),
    );
    await tester.pump();
    return bloc;
  }

  group('the app remembers whether it asked', () {
    test('a fresh install has not', () {
      expect(preferences.photoAccessAsked, isFalse);
    });

    test('the mark survives the answer, whichever it was', () async {
      // Recorded when the question is *put*, not when it is granted. Marking
      // it on success only would send somebody who refused back to the same
      // screen, offering the same button, which Android answers by doing
      // nothing at all.
      await preferences.markPhotoAccessAsked();
      expect(preferences.photoAccessAsked, isTrue);

      final AppPreferences reloaded = AppPreferences();
      await reloaded.load();
      expect(reloaded.photoAccessAsked, isTrue);
    });
  });

  group('the screen offered before the question is put', () {
    testWidgets('says what is being asked for, and offers the dialog', (
      WidgetTester tester,
    ) async {
      final _StubBloc bloc = await render(
        tester,
        ScreenshotsPermissionUnaskedState(),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.permissionAskTitle), findsOneWidget);
      expect(find.text(l10n.permissionAllow), findsOneWidget);

      // The half that matters. This is the first screen of a fresh install,
      // and sending that person to system settings is opening the app on an
      // instruction to go and repair it.
      expect(find.text(l10n.permissionOpenSettings), findsNothing);

      await tester.tap(find.text(l10n.permissionAllow));
      await tester.pump();
      expect(bloc.received.single, isA<RequestPhotoAccessEvent>());
    });

    testWidgets('a refusal gets settings, because the dialog will not return', (
      WidgetTester tester,
    ) async {
      await render(tester, ScreenshotsPermissionDeniedState());
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.permissionOpenSettings), findsOneWidget);
      // Offering the dialog here is a button that does nothing, every time.
      expect(find.text(l10n.permissionAllow), findsNothing);
    });

    testWidgets('partial access keeps its own wording', (
      WidgetTester tester,
    ) async {
      // "Select photos…" is an answer too, and a different one again: the
      // album exists but is invisible, so neither the dialog nor a plain
      // refusal describes it.
      await render(
        tester,
        ScreenshotsPermissionDeniedState(isPartialAccess: true),
      );
      final AppLocalizations l10n = await english();

      expect(find.text(l10n.permissionPartialTitle), findsOneWidget);
      expect(find.text(l10n.permissionAllow), findsNothing);
    });
  });

  group('nothing else raises the dialog', () {
    test('the requesting event is its own event', () {
      // Not a flag on LoadScreenshotsEvent. A load runs at launch, on tab
      // select and on retry; any of those carrying a prompt is how the dialog
      // reached somebody who had not asked for it.
      expect(RequestPhotoAccessEvent(), isA<ScreenshotsEvent>());
      expect(LoadScreenshotsEvent(), isNot(isA<RequestPhotoAccessEvent>()));
    });
  });

  group('a granted permission is still a granted permission', () {
    test('the loaded library draws nothing of its own', () {
      // maybeOf returns null exactly when there is a library to draw, and the
      // new state must not have widened that.
      expect(
        LibraryUnavailable.maybeOf(ScreenshotsLoadedState(screenshots: const [])),
        isNull,
      );
      expect(
        LibraryUnavailable.maybeOf(ScreenshotsPermissionUnaskedState()),
        isNotNull,
      );
    });
  });
}
