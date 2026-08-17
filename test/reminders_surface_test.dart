import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/home/presentation/widgets/home_inbox.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

import 'support/fake_gallery.dart';

/// Where a reminder can be *seen*.
///
/// The feature shipped able to fire and unable to be looked at: a reminder was
/// invisible unless you long-pressed the exact screenshot it was set on. These
/// pin the two halves of the fix — the state derives the list, and Home says
/// enough about it to be worth a tap.
ScreenshotEntity _shot(int id, {DateTime? remindAt}) => ScreenshotEntity(
  asset: FakeGallery.asset(id),
  isFavorite: false,
  folderId: null,
  remindAt: remindAt,
);

void main() {
  setUpAll(() async {
    await FakeGallery.install();
    // Tapping anything in this app goes through `PressableScale`, which asks
    // `Haptics` whether the user wants a buzz — and that reads the preference
    // out of the service locator.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  group('the derived list', () {
    test('holds only the screenshots that have one, soonest first', () {
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot(1, remindAt: DateTime(2030, 6, 3)),
          _shot(2),
          _shot(3, remindAt: DateTime(2030, 6, 1)),
          _shot(4, remindAt: DateTime(2030, 6, 2)),
        ],
      );

      expect(state.reminders.map((ScreenshotEntity s) => s.id), <String>[
        '3',
        '4',
        '1',
      ]);
    });

    test('keeps the ones whose moment has passed', () {
      // The reason this screen exists: a notification clears itself when it
      // fires, so dropping past reminders here would mean the one moment the
      // app asked for attention is the only one it ever gets.
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[
          _shot(1, remindAt: DateTime(2020, 1, 1)),
          _shot(2, remindAt: DateTime(2030, 1, 1)),
        ],
      );

      expect(state.reminders.length, 2);
      expect(state.reminders.first.id, '1');
    });

    test('is empty when nobody has set one', () {
      final ScreenshotsLoadedState state = ScreenshotsLoadedState(
        screenshots: <ScreenshotEntity>[_shot(1), _shot(2)],
      );
      expect(state.reminders, isEmpty);
    });
  });

  group('the row on Home', () {
    Widget wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    testWidgets('counts them, and says when the next one is due', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
              _shot(2, remindAt: DateTime.now().add(const Duration(days: 1))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );

      expect(find.text('2 reminders'), findsOneWidget);
      // Not the alert wording — nothing has been missed.
      expect(find.textContaining('missed'), findsNothing);
      expect(find.textContaining('Next'), findsOneWidget);
    });

    testWidgets('leads with what was missed, when something was', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime(2020, 1, 1)),
              _shot(2, remindAt: DateTime.now().add(const Duration(days: 1))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );

      expect(find.text('1 missed'), findsOneWidget);
      // The next one is real, but "something already slipped past you" is the
      // more useful half and the row only has room for one.
      expect(find.textContaining('Next'), findsNothing);
    });

    testWidgets('opens the list when tapped', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('1 reminder'));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('a library with only reminders is not "all filed"', (
      tester,
    ) async {
      // The clear state collapses the whole block to one quiet line. A pending
      // reminder is work, so claiming there is none would be the app telling
      // somebody they are done while holding an alarm for them.
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: <ScreenshotEntity>[
              _shot(1, remindAt: DateTime.now().add(const Duration(hours: 2))),
            ],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );

      expect(find.text('1 reminder'), findsOneWidget);
    });

    testWidgets('and nothing is drawn when there are none', (tester) async {
      await tester.pumpWidget(
        wrap(
          HomeInbox(
            unsorted: const <ScreenshotEntity>[],
            waiting: const {},
            reminders: const <ScreenshotEntity>[],
            onOpenLibrary: (_) {},
            onOpenIntent: (_) {},
            onOpenReminders: () {},
          ),
        ),
      );

      expect(find.textContaining('reminder'), findsNothing);
    });
  });
}
