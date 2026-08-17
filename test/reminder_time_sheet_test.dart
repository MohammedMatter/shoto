import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/widgets/wheel_picker.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_time_sheet.dart';

import 'support/test_theme.dart';

/// The picker that replaced a date dialog followed by a clock face.
///
/// The promise being pinned here is the one the old flow could not make: **the
/// sheet cannot hand back a moment that was already gone when it was chosen.**
/// Both pickers before it accepted a past time happily and left the app to
/// refuse it afterwards with a message, which is the user doing the work and
/// then being told off for it.
///
/// [showReminderTimeSheet] takes its clock as an argument rather than reaching
/// for `DateTime.now`, which is what makes every one of these a fixed-clock
/// test instead of one that behaves differently depending on the hour the
/// suite happens to run at — and what lets the last one move time forward
/// underneath a sheet that is already open.
void main() {
  setUpAll(() {
    // Every tap goes through `PressableScale`, which asks `Haptics` whether
    // the user wants a buzz — and that reads the preference out of the
    // service locator.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  testWidgets('opens on today, five minutes ahead', (
    WidgetTester tester,
  ) async {
    DateTime? picked;
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 14, 30),
      onResult: (DateTime? at) => picked = at,
    );

    // The day the strip landed on, spelled out under the title.
    expect(find.text('Monday, May 4, 2026'), findsOneWidget);
    // 14:35, on a twelve-hour wheel: the hour reads 2 and the period is PM.
    expect(find.text('35'), findsWidgets);

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 5, 4, 14, 35));
  });

  testWidgets('tapping a day moves the answer to it', (
    WidgetTester tester,
  ) async {
    DateTime? picked;
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 14, 30),
      onResult: (DateTime? at) => picked = at,
    );

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, May 5, 2026'), findsOneWidget);

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    // The time is kept: moving the day is not a reason to lose the hour
    // somebody already chose.
    expect(picked, DateTime(2026, 5, 5, 14, 35));
  });

  // The heart of it. Tomorrow allows any hour, so the wheel can be dragged
  // back to the morning — and then the day is moved to today, where that
  // morning is gone. Nothing warns and nothing is refused: the choice is
  // pulled up to the earliest minute there is.
  testWidgets('a choice that becomes impossible is corrected, not refused', (
    WidgetTester tester,
  ) async {
    DateTime? picked;
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 14, 30),
      onResult: (DateTime? at) => picked = at,
    );

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();

    // Downward on a wheel is backward in time. Four rows of it from 2 PM lands
    // in the morning, which tomorrow permits and today does not.
    await tester.drag(
      find.byType(WheelPicker).first,
      Offset(0, WheelPicker.itemExtent * 4),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(
      picked!.isBefore(DateTime(2026, 5, 4, 14, 31)),
      isFalse,
      reason: 'the sheet returned a moment already gone: $picked',
    );
    expect(picked, DateTime(2026, 5, 4, 14, 31));
  });

  // The correction animates the wheels, and `animateToItem` asserts on the
  // zero duration `AppMotion.duration` hands back when animation is switched
  // off — so before this was guarded, the accessible path was the one that
  // crashed.
  testWidgets('and corrected with animations switched off too', (
    WidgetTester tester,
  ) async {
    DateTime? picked;
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 14, 30),
      onResult: (DateTime? at) => picked = at,
      reduceMotion: true,
    );

    await tester.tap(find.text('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(WheelPicker).first,
      Offset(0, WheelPicker.itemExtent * 4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 5, 4, 14, 31));
  });

  // A sheet left open through a conversation is a sheet whose own answer has
  // quietly expired. The clock is moved two hours on *while it is up*, which
  // is the one thing a single fixed moment cannot express — and the reason
  // this widget takes a function rather than a `DateTime`.
  testWidgets('a stale sheet refuses, explains, and re-floors itself', (
    WidgetTester tester,
  ) async {
    DateTime moment = DateTime(2026, 5, 4, 14, 30);
    DateTime? picked;
    bool returned = false;

    await _pumpSheet(
      tester,
      clock: () => moment,
      onResult: (DateTime? at) {
        picked = at;
        returned = true;
      },
    );

    // Two hours pass with the sheet open on 14:35.
    moment = DateTime(2026, 5, 4, 16, 30);

    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    expect(returned, isFalse, reason: 'it handed back a moment already gone');
    // Said on the sheet itself. A snack bar here renders into the page's
    // Scaffold, underneath the panel covering the bottom of the screen.
    expect(
      find.text('That time has already passed — pick a later one.'),
      findsOneWidget,
    );

    // And the second press is the one that works, because the sheet has moved
    // itself onto the new floor rather than leaving the user to find it.
    await tester.tap(find.text('Set reminder'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(picked, DateTime(2026, 5, 4, 16, 31));
  });

  testWidgets('late at night, today is not offered at all', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 23, 59, 30),
      onResult: (DateTime? _) {},
    );

    // The only minute today still owns is spent, so the strip starts with
    // tomorrow — and the first chip must not be *called* today, which is the
    // bug a label keyed on index would have.
    expect(find.text('Today'), findsNothing);
    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Tuesday, May 5, 2026'), findsOneWidget);
  });

  testWidgets('dismissing it sets nothing', (WidgetTester tester) async {
    DateTime? picked;
    bool returned = false;
    await _pumpSheet(
      tester,
      clock: () => DateTime(2026, 5, 4, 14, 30),
      onResult: (DateTime? at) {
        picked = at;
        returned = true;
      },
    );

    // The scrim, which is everything above the sheet.
    await tester.tapAt(const Offset(180, 40));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(picked, isNull);
  });
}

/// Puts the sheet on screen and reports what it returns.
Future<void> _pumpSheet(
  WidgetTester tester, {
  required DateTime Function() clock,
  required ValueChanged<DateTime?> onResult,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

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
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async =>
                      onResult(await showReminderTimeSheet(context, clock: clock)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
