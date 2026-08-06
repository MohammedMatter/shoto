import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/routes/app_sheet.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_sort.dart';
import 'package:shoto/features/screenshots/presentation/widgets/lens_provenance_note.dart';
import 'package:shoto/features/screenshots/presentation/widgets/library_view_sheet.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_filter_row.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// The library's filter strip and the sheet the content traits moved into, in
/// the states that actually matter, so the design can be *looked at*.
///
/// This file used to render two stacked chip axes. There is one row now: the
/// traits are in [showLibraryViewSheet] beside the sort order, which is what
/// took roughly 40dp of controls back off the top of the grid. Both halves are
/// here because the question the change has to answer is visual and split
/// across them — is the row quieter, and did the traits stay findable.
///
/// Running with `--update-goldens` writes real PNGs; it is never a regression
/// gate, so a normal `flutter test` run skips it.
const Map<ContentTrait, int> _counts = <ContentTrait, int>{
  ContentTrait.sensitive: 3,
  ContentTrait.link: 24,
  ContentTrait.contact: 11,
  ContentTrait.code: 6,
  ContentTrait.event: 2,
};

/// Takes a *builder* rather than a built widget, and that is load-bearing.
///
/// `testTheme` builds the app's real `ThemeData`, whose `TextTheme` is a set
/// of concrete styles sized in `.sp` — so constructing it reads ScreenUtil,
/// and reading ScreenUtil before [ScreenUtilInit] has run throws. Passing
/// `_strip(...)` as an argument evaluated it one step too early; passing
/// `() => _strip(...)` runs it inside the builder, where the app itself
/// builds its themes.
Widget _wrap(Widget Function() build) => ScreenUtilInit(
  designSize: const Size(360, 690),
  minTextAdapt: true,
  builder: (context, _) => build(),
);

Widget _strip({
  required Locale locale,
  required LibraryFilter filter,
  ContentTrait? lens,
  int unreadCount = 0,
  Brightness brightness = Brightness.dark,
}) {
  final AppPalette palette = testPalette(brightness);
  return MaterialApp(
    theme: testTheme(brightness),
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScreenshotsFilterRow(
              totalCount: 128,
              unsortedCount: 41,
              favoritesCount: 9,
              filter: filter,
              onSelect: (_) {},
            ),
            // Still here, and still the feature's honesty mechanism: with the
            // chips gone this is the line that says an active lens can only
            // see what has been read.
            LensProvenanceNote(lens: lens, unreadCount: unreadCount),
          ],
        ),
      ),
    ),
  );
}

/// The sheet, opened for real rather than built directly, so what is
/// photographed is what the user meets — surface, insets and all.
///
/// [slot] keys the whole app, and it is load-bearing. `pumpWidget` reuses the
/// element tree when the new widget matches the old one, so the Navigator —
/// and the route pushed onto it — survived from one case to the next: the
/// second and third sheets were never built, and all three goldens came out
/// byte-identical pictures of the first. A distinct key forces a real
/// teardown between cases.
Widget _sheetHost({
  required String slot,
  required Locale locale,
  ContentTrait? lens,
  bool traitsReady = true,
  int unreadCount = 0,
  bool isScanning = false,
  Map<ContentTrait, int> counts = _counts,
  Brightness brightness = Brightness.dark,
}) {
  final AppPalette palette = testPalette(brightness);
  return MaterialApp(
    key: ValueKey<String>(slot),
    theme: testTheme(brightness),
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: ElevatedButton(
            // The body directly, not `showLibraryViewSheet` — that one now
            // watches the Library's bloc, and these goldens are photographs
            // of a layout rather than of a state machine.
            onPressed: () => showAppSheet<void>(
              context: context,
              builder: (_) => debugLibraryViewSheet(
                sort: LibrarySort.newest,
                lens: lens,
                traitCounts: counts,
                traitsReady: traitsReady,
                unreadCount: unreadCount,
                isScanning: isScanning,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  Widget app,
  String name, {
  Finder? target,
  bool openSheet = false,

  /// False when the frame contains a never-ending animation.
  ///
  /// `pumpAndSettle` waits for the tree to stop changing, and a
  /// [CircularProgressIndicator] never does — the scanning state hung the
  /// whole file until this existed.
  bool settle = true,
}) async {
  await tester.pumpWidget(app);
  if (openSheet) {
    await tester.tap(find.text('open'));
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // One frame to build the pushed route, then long enough for its entrance
    // to finish. Advancing straight to 400ms in a single pump photographed a
    // sheet that had not been built yet — a blank white frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }
  await expectLater(
    target ?? find.byType(Column).first,
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await loadTestFonts();
    // The pills subscribe to it for theme changes; without a registration
    // every one of them throws before it can paint.
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerSingleton<ThemeController>(ThemeController());
    }
    // The sheet's rows ripple and buzz, and `Haptics` reads the preference
    // out of the locator to decide whether to.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    // The density control moved into this sheet when the Library header went
    // from four buttons to three, and this file was not updated with it — so
    // the sheet half of the generator threw on every run. It never showed up
    // as a failure because goldens are skipped unless `--update-goldens` is
    // passed, which is exactly the blind spot a generation-only test has.
    if (!sl.isRegistered<GridDensityController>()) {
      sl.registerLazySingleton<GridDensityController>(
        () => GridDensityController(),
      );
    }
  });

  testWidgets('filter strip states', (WidgetTester tester) async {
    // Must match the 360x690 design size. ScreenUtil derives `.h` from the
    // *view* height, so a short test surface silently shrinks every vertical
    // dimension — at 520 physical px the 50.h row collapsed to 12 logical px
    // and clipped its own labels away, which looks exactly like a font that
    // failed to load.
    tester.view.physicalSize = const Size(1080, 2070);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // 1. Resting. One row, and this is now the entire cost of the filter
    //    controls above the grid.
    await _shoot(
      tester,
      _wrap(
        () => _strip(locale: const Locale('en'), filter: LibraryFilter.all),
      ),
      'library_strip_1_resting',
    );

    // 2. Arrived from Home's hero: Unsorted lit, agreeing with the 58px
    //    figure that was tapped.
    await _shoot(
      tester,
      _wrap(
        () =>
            _strip(locale: const Locale('en'), filter: LibraryFilter.unsorted),
      ),
      'library_strip_2_unsorted',
    );

    // 3. A lens is on. With the chips gone this line is the only thing on the
    //    grid saying so, besides the dot on the header button.
    await _shoot(
      tester,
      _wrap(
        () => _strip(
          locale: const Locale('en'),
          filter: LibraryFilter.all,
          lens: ContentTrait.link,
          unreadCount: 87,
        ),
      ),
      'library_strip_3_lens_note',
    );

    // 4. Arabic, RTL. The row must start from the right and the note must not
    //    flip its punctuation to the front.
    await _shoot(
      tester,
      _wrap(
        () => _strip(
          locale: const Locale('ar'),
          filter: LibraryFilter.unsorted,
          lens: ContentTrait.link,
          unreadCount: 87,
        ),
      ),
      'library_strip_4_arabic_rtl',
    );

    await _shoot(
      tester,
      _wrap(
        () => _strip(
          locale: const Locale('en'),
          filter: LibraryFilter.favorites,
          brightness: Brightness.light,
        ),
      ),
      'library_strip_5_light',
    );
  });

  testWidgets('view sheet states', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2070);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final Finder sheet = find.byType(BottomSheet);

    // 1. Everything present: order, every trait that would land on something,
    //    and the scan for what has never been read. The whole second axis, in
    //    rows wide enough to hold "Phone or email · 11" without cutting it —
    //    which the chip could not.
    await _shoot(
      tester,
      _wrap(
        () => _sheetHost(
          slot: 'full',
          locale: const Locale('en'),
          unreadCount: 87,
        ),
      ),
      'library_sheet_1_full',
      target: sheet,
      openSheet: true,
    );

    // 2. A trait active, so the tick and the "Everything" way out are both
    //    visible in one frame.
    await _shoot(
      tester,
      _wrap(
        () => _sheetHost(
          slot: 'lens',
          locale: const Locale('en'),
          lens: ContentTrait.sensitive,
        ),
      ),
      'library_sheet_2_lens_active',
      target: sheet,
      openSheet: true,
    );

    // 3. Nothing read yet. The trait section is absent entirely rather than a
    //    list of dead zeroes, leaving the one row that fixes it.
    await _shoot(
      tester,
      _wrap(
        () => _sheetHost(
          slot: 'unread',
          locale: const Locale('en'),
          unreadCount: 12,
          counts: const <ContentTrait, int>{},
        ),
      ),
      'library_sheet_3_nothing_read',
      target: sheet,
      openSheet: true,
    );

    await _shoot(
      tester,
      _wrap(
        () => _sheetHost(
          slot: 'scanning',
          locale: const Locale('ar'),
          unreadCount: 12,
          isScanning: true,
          counts: const <ContentTrait, int>{},
        ),
      ),
      'library_sheet_4_scanning_arabic',
      target: sheet,
      openSheet: true,
      settle: false,
    );

    // 5-8. The remaining shipped languages. "Teléfono o correo" is more than
    //      twice the width of "Codes", and a sheet that fits in English says
    //      nothing about whether it fits at all.
    for (final (String code, String name) in <(String, String)>[
      ('es', '5_spanish'),
      ('fr', '6_french'),
      ('hi', '7_hindi'),
      ('ur', '8_urdu'),
    ]) {
      await _shoot(
        tester,
        _wrap(
          () => _sheetHost(
            slot: code,
            locale: Locale(code),
            lens: ContentTrait.contact,
            unreadCount: 87,
          ),
        ),
        'library_sheet_$name',
        target: sheet,
        openSheet: true,
      );
    }
  });
}
