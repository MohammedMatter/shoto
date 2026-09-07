import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/utils/reminder_times.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/domain/use_cases/set_reminder_use_case.dart';
import 'package:shoto/features/screenshots/presentation/widgets/reminder_sheet.dart';

import 'support/fake_gallery.dart';
import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The sheet that answers "when should this come back?".
///
/// It shipped with no tests at all, which is how the thing these mostly guard
/// survived: **every row spelled out the date, and for four rows out of five
/// the date was what the row was called.** "Later today — Tue, Aug 18, 4:54
/// PM". The label named the day and the value named it again, leaving a column
/// of five near-identical grey strings whose only differing part — the time —
/// sat at the far end of each line.
class _RecordingSetReminder implements SetReminderUseCase {
  final List<({String assetId, DateTime? at})> calls =
      <({String assetId, DateTime? at})>[];

  @override
  Future<bool> call(
    String assetId,
    DateTime? at, {
    String title = '',
    String body = '',
  }) async {
    calls.add((assetId: assetId, at: at));
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ScreenshotEntity _shot(int id, {DateTime? remindAt}) => ScreenshotEntity(
  asset: FakeGallery.asset(id),
  isFavorite: false,
  folderId: null,
  remindAt: remindAt,
);

void main() {
  late _RecordingSetReminder setReminder;

  setUpAll(() async {
    // Real type: half of what is below is about whether the sheet fits, and
    // the default test font is roughly twice the width of the one that ships.
    await loadTestFonts();
    await FakeGallery.install();
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
  });

  setUp(() {
    setReminder = _RecordingSetReminder();
    if (sl.isRegistered<SetReminderUseCase>()) {
      sl.unregister<SetReminderUseCase>();
    }
    sl.registerSingleton<SetReminderUseCase>(setReminder);
  });

  /// Opens the sheet over an empty page and hands back the page's context,
  /// which is what the date formats below are read through.
  Future<BuildContext> open(
    WidgetTester tester,
    ScreenshotEntity item, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Size size = const Size(360, 690),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late BuildContext page;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (BuildContext context, Widget? _) => MaterialApp(
          locale: locale,
          theme: testTheme(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (BuildContext c, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              c,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext c) {
                page = c;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    showReminderSheet(page, item);
    await tester.pumpAndSettle();
    return page;
  }

  /// A date the way the sheet would print one, in the locale under test.
  String mediumDate(BuildContext context, DateTime at) =>
      MaterialLocalizations.of(context).formatMediumDate(at);

  /// Whether the paragraph actually ran out of room.
  ///
  /// `find.text` matches on `Text.data`, which is the string handed *in* — an
  /// ellipsised line still reports it in full. `didExceedMaxLines` is the
  /// renderer's own answer to "did I have to cut this", which is the question.
  /// Same idiom as `home_greeting_name_test`.
  bool wasTruncated(WidgetTester tester, Finder text) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)).first,
    );
    return paragraph.didExceedMaxLines;
  }

  group('how much of a moment each row says', () {
    testWidgets('a preset whose label names the day says only the time', (
      WidgetTester tester,
    ) async {
      final DateTime now = DateTime.now();
      final BuildContext page = await open(tester, _shot(1));

      // **The whole rule, stated over the whole sheet.** "Tomorrow morning"
      // lands tomorrow and says so in its own label, so tomorrow's date has no
      // business appearing anywhere on this surface.
      final DateTime tomorrow = resolveReminder(
        ReminderPreset.tomorrowMorning,
        now,
      );
      expect(find.text(page.l10n.reminderTomorrow), findsOneWidget);
      expect(find.textContaining(mediumDate(page, tomorrow)), findsNothing);
    });

    testWidgets('next week keeps its date, where the day is the news', (
      WidgetTester tester,
    ) async {
      final DateTime now = DateTime.now();
      final BuildContext page = await open(tester, _shot(1));

      final DateTime week = resolveReminder(ReminderPreset.nextWeek, now);
      expect(find.textContaining(mediumDate(page, week)), findsOneWidget);
    });

    testWidgets('the reminder already set is spelled out in full', (
      WidgetTester tester,
    ) async {
      // The one moment on the sheet with no label above it carrying half of
      // it, so this one does need the date.
      final DateTime at = DateTime.now().add(const Duration(days: 3));
      final BuildContext page = await open(tester, _shot(1, remindAt: at));

      expect(find.textContaining(mediumDate(page, at)), findsOneWidget);
    });
  });

  group('the sheet', () {
    testWidgets('shows the screenshot it is about', (
      WidgetTester tester,
    ) async {
      // It says "Remind me about this" and is raised over the tile, the row or
      // the picture that *this* referred to.
      await open(tester, _shot(1));
      expect(find.byType(AssetThumbnailImage), findsOneWidget);
    });

    testWidgets('offers to remove one only when there is one', (
      WidgetTester tester,
    ) async {
      final BuildContext page = await open(tester, _shot(1));
      expect(find.text(page.l10n.reminderClear), findsNothing);
    });

    testWidgets('and does offer it when there is', (WidgetTester tester) async {
      final BuildContext page = await open(
        tester,
        _shot(1, remindAt: DateTime.now().add(const Duration(days: 1))),
      );
      expect(find.text(page.l10n.reminderClear), findsOneWidget);
    });

    testWidgets('refuses to arm one where nothing could fire it', (
      WidgetTester tester,
    ) async {
      // **`Reminders.isSupported` is Android or iOS**, so on the machine these
      // tests run on every preset takes this branch. That makes the
      // happy path unreachable from a widget test — and makes this branch the
      // one worth pinning, because it is the difference between a reminder
      // that will not fire and a reminder that will not fire *silently*.
      final BuildContext page = await open(tester, _shot(7));

      await tester.tap(find.text(page.l10n.reminderTomorrow));
      await tester.pumpAndSettle();

      expect(setReminder.calls, isEmpty);
      expect(find.text(page.l10n.reminderUnsupported), findsOneWidget);

      // Let the message expire, or the binding reports its timer as pending.
      await tester.pumpAndSettle(const Duration(seconds: 4));
    });

    testWidgets('removing one goes through, and offers the way back', (
      WidgetTester tester,
    ) async {
      // Removal is not gated on the platform — there is always something to
      // take off, even where there was never anything to fire it — so this is
      // the one whole round trip these tests can actually take.
      final DateTime at = DateTime.now().add(const Duration(days: 1));
      final BuildContext page = await open(tester, _shot(7, remindAt: at));

      await tester.tap(find.text(page.l10n.reminderClear));
      await tester.pumpAndSettle();

      expect(setReminder.calls.length, 1);
      expect(setReminder.calls.single.assetId, '7');
      expect(setReminder.calls.single.at, isNull);

      // **The way back, on a screen whose whole subject is not losing things.**
      // The sheet's copy of this had no undo at all until it was pulled into
      // `removeRemindersWithUndo` alongside the list's — which is exactly the
      // failure writing the same four steps three times produces.
      expect(find.text(page.l10n.commonUndo), findsOneWidget);

      await tester.tap(find.text(page.l10n.commonUndo));
      await tester.pumpAndSettle();

      expect(setReminder.calls.length, 2);
      expect(setReminder.calls.last.at, at);

      await tester.pumpAndSettle(const Duration(seconds: 4));
    });
  });

  /// **Whether it fits, which it did not.**
  ///
  /// A plain bottom sheet is capped at about half the screen. This one measured
  /// 368.0 logical pixels against a cap of 368.1 — a tenth of a pixel of
  /// headroom, in English, at the default text size, on the tallest phone it
  /// was drawn on. At 1.3x it burst, and the failure is the one a `Column` in a
  /// sheet always has: the yellow-and-black stripe over rows nobody can reach.
  ///
  /// So both ends are covered here: a tall sheet is allowed to be tall, and it
  /// scrolls rather than overflows when even that is not enough.
  group('the sheet fits', () {
    for (final Locale locale in AppLocalizations.supportedLocales) {
      for (final double scale in const <double>[1.0, 1.3]) {
        testWidgets('${locale.languageCode} at ${scale}x', (
          WidgetTester tester,
        ) async {
          final BuildContext page = await open(
            tester,
            _shot(1, remindAt: DateTime.now().add(const Duration(days: 1))),
            locale: locale,
            textScale: scale,
          );

          expect(tester.takeException(), isNull);
          // Every row is on the surface, including the last one — which is
          // the one an overflow eats first.
          expect(find.text(page.l10n.reminderClear), findsOneWidget);
          expect(find.text(page.l10n.reminderPickTime), findsOneWidget);

          // **And at the ordinary text size the words survive whole**, which
          // is the other half of fitting: a one-line cap turns a wrap into an
          // ellipsis, and "Nächste Woc…" is not an improvement on anything.
          //
          // Only at 1.0×. At 1.3× the row carrying a date — "Next week", the
          // longest label on the sheet in every language here — does get cut
          // in French, Italian and Portuguese, and no arrangement of that row
          // avoids it: label and moment together want about forty pixels more
          // than the row has. What the layout decides is *which* half is cut,
          // and it cuts the words rather than the time. See `_Row`.
          //
          // Only the presets that are always offered are checked; the two
          // relative ones come off the sheet depending on the hour.
          if (scale == 1.0) {
            for (final String label in <String>[
              page.l10n.reminderTomorrow,
              page.l10n.reminderNextWeek,
              page.l10n.reminderPickTime,
              page.l10n.reminderClear,
            ]) {
              expect(
                wasTruncated(tester, find.text(label)),
                isFalse,
                reason: '"$label" was cut',
              );
            }
          }

          // The moment itself is never the half that gets cut, at either size.
          expect(
            wasTruncated(
              tester,
              find.textContaining(
                mediumDate(
                  page,
                  resolveReminder(ReminderPreset.nextWeek, DateTime.now()),
                ),
              ),
            ),
            isFalse,
          );
        });
      }
    }

    testWidgets('and scrolls rather than overflows on a short screen', (
      WidgetTester tester,
    ) async {
      // A 690-tall design on a 480-tall window, in the longest language, at a
      // large text size: past what any amount of sheet height can absorb.
      await open(
        tester,
        _shot(1, remindAt: DateTime.now().add(const Duration(days: 1))),
        locale: const Locale('de'),
        textScale: 1.6,
        size: const Size(360, 480),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
