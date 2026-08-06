import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_intake_row.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/fake_gallery.dart';
import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The rules that decide whether the Library's inbox row says anything.
///
/// Both of them exist because the version of this that lived on Home had
/// neither, and the result was a card on the first screen of every launch
/// that could only be silenced by answering the whole queue. Neither rule is
/// visible in a screenshot, and both are the kind of thing a later change
/// breaks without noticing — a threshold quietly lowered to 1, a snooze that
/// stores a time instead of a count and so expires on its own.
class _FakeScreenshotRepository implements ScreenshotRepository {
  _FakeScreenshotRepository(this.count);

  final int count;

  @override
  Future<List<AssetEntity>> getNewCaptures({DateTime? since}) async =>
      List<AssetEntity>.generate(count, FakeGallery.asset);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppPreferences preferences;

  /// [fresh] wipes the stored preferences as well. Left off, the same
  /// [AppPreferences] survives — which is the only way to test that a snooze
  /// outlives the row that set it.
  Future<void> pumpRow(
    WidgetTester tester, {
    required int waiting,
    bool fresh = true,
    String mount = 'first',
  }) async {
    await loadTestFonts();
    if (fresh) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await sl.reset();
      preferences = AppPreferences();
      await preferences.load();
      await preferences.setTriageEnabled(true);
      sl.registerSingleton<AppPreferences>(preferences);
    } else {
      sl.unregister<GetNewCapturesUseCase>();
    }
    sl.registerSingleton<GetNewCapturesUseCase>(
      GetNewCapturesUseCase(_FakeScreenshotRepository(waiting), preferences),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.dark),
          home: Scaffold(body: LibraryIntakeRow(key: ValueKey<String>(mount))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Installed once, outside a test body on purpose. FakeGallery rasterises
  // its stand-in thumbnails through the engine, and that never completes
  // inside `testWidgets` — the fake clock in there does not drive the raster
  // thread, so awaiting it hangs the whole file.
  //
  // LibraryIntakeRow subscribes to gallery changes on mount, which reaches
  // the photo_manager channel; without the handler that is a
  // MissingPluginException.
  setUpAll(() async => FakeGallery.install());
  tearDownAll(FakeGallery.uninstall);

  tearDown(() async => sl.reset());

  testWidgets('says nothing below the threshold', (WidgetTester tester) async {
    await pumpRow(tester, waiting: LibraryIntakeRow.minimum - 1);
    expect(find.byIcon(Icons.inbox_rounded), findsNothing);
  });

  testWidgets('appears at the threshold', (WidgetTester tester) async {
    await pumpRow(tester, waiting: LibraryIntakeRow.minimum);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('goes quiet when put down, and stays quiet at the same count', (
    WidgetTester tester,
  ) async {
    await pumpRow(tester, waiting: 11);
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.inbox_rounded), findsNothing);
    expect(preferences.triageSnoozedAt, 11);
  });

  testWidgets('stays quiet at the same count after a remount', (
    WidgetTester tester,
  ) async {
    await pumpRow(tester, waiting: 11);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Eleven again is the same eleven — the whole reason the snooze stores a
    // count rather than a moment. A time-based snooze would expire on its own
    // and put the row back with nothing new behind it.
    await pumpRow(tester, waiting: 11, fresh: false, mount: 'second');
    expect(find.byIcon(Icons.inbox_rounded), findsNothing);
  });

  testWidgets('comes back once there is genuinely more', (
    WidgetTester tester,
  ) async {
    await pumpRow(tester, waiting: 20);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.inbox_rounded), findsNothing);

    // A new mount, which is what re-entering the tab or relaunching gives
    // you. The count is read once per mount by design — see the row — so a
    // snooze holds for the rest of the session no matter what arrives.
    await pumpRow(tester, waiting: 32, fresh: false, mount: 'second');
    expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
  });

  testWidgets('library inbox row — dark', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpRow(tester, waiting: 11);
    await expectLater(
      find.byType(LibraryIntakeRow),
      matchesGoldenFile('goldens/library_intake_row.png'),
    );
  });
}
