import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/content_traits.dart';
import 'package:shoto/features/screenshots/presentation/bloc/library_filter.dart';
import 'package:shoto/features/screenshots/presentation/widgets/lens_provenance_note.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshots_filter_row.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';

/// Renders the library's filter strip in the states that actually matter, so
/// the design can be *looked at*.
///
/// The whole point of this change is visual — two axes have to read as two
/// axes — and no assertion can tell you whether they do. Running with
/// `--update-goldens` writes real PNGs; it is never a regression gate, so a
/// normal `flutter test` run skips it.
const Map<ContentTrait, int> _counts = <ContentTrait, int>{
  ContentTrait.sensitive: 3,
  ContentTrait.link: 24,
  ContentTrait.contact: 11,
  ContentTrait.code: 6,
  ContentTrait.event: 2,
};

Widget _case({
  required Locale locale,
  required LibraryFilter filter,
  ContentTrait? lens,
  bool traitsReady = true,
  int unreadCount = 0,
  Map<ContentTrait, int> counts = _counts,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: AppColors.background,
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
              lens: lens,
              onSelectLens: (_) {},
              traitCounts: counts,
              traitsReady: traitsReady,
            ),
            LensProvenanceNote(lens: lens, unreadCount: unreadCount),
          ],
        ),
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  Widget app,
  String name,
) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(Column).first,
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
  });

  setUp(() {
    AppColors.setBrightness(Brightness.dark);
  });

  testWidgets('filter row states', (WidgetTester tester) async {
    // Must match the 360x690 design size. ScreenUtil derives `.h` from the
    // *view* height, so a short test surface silently shrinks every vertical
    // dimension — at 520 physical px the 50.h row collapsed to 12 logical px
    // and clipped its own labels away, which looks exactly like a font that
    // failed to load.
    tester.view.physicalSize = const Size(1080, 2070);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Widget wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, _) => child,
    );

    // 1. Resting: status only, before the trait pass has finished. This is the
    //    first thing anyone sees, and it must not look like a broken row.
    await _shoot(
      tester,
      wrap(
        _case(
          locale: const Locale('en'),
          filter: LibraryFilter.all,
          traitsReady: false,
        ),
      ),
      'library_filter_1_status_only',
    );

    // 2. Both groups present, nothing narrowed — the separator has to make the
    //    two axes read as two.
    await _shoot(
      tester,
      wrap(_case(locale: const Locale('en'), filter: LibraryFilter.all)),
      'library_filter_2_both_axes',
    );

    // 3. Both axes on at once, with the danger trait active. The gradient pill
    //    and the flat rose chip must be distinguishable at a glance.
    await _shoot(
      tester,
      wrap(
        _case(
          locale: const Locale('en'),
          filter: LibraryFilter.unsorted,
          lens: ContentTrait.sensitive,
        ),
      ),
      'library_filter_3_sensitive_lens',
    );

    // 4. A read-provenance lens with unread screenshots outstanding — the
    //    honesty line at its longest.
    await _shoot(
      tester,
      wrap(
        _case(
          locale: const Locale('en'),
          filter: LibraryFilter.all,
          lens: ContentTrait.link,
          unreadCount: 87,
        ),
      ),
      'library_filter_4_unread_note',
    );

    // 5. Arabic, RTL. The row must start from the right and the note must not
    //    flip its punctuation to the front.
    await _shoot(
      tester,
      wrap(
        _case(
          locale: const Locale('ar'),
          filter: LibraryFilter.unsorted,
          lens: ContentTrait.link,
          unreadCount: 87,
        ),
      ),
      'library_filter_5_arabic_rtl',
    );

    // 6. Light mode, so the flat accent fills can be checked for contrast
    //    against a pale surface rather than only a dark one.
    AppColors.setBrightness(Brightness.light);
    await _shoot(
      tester,
      wrap(
        _case(
          locale: const Locale('en'),
          filter: LibraryFilter.favorites,
          lens: ContentTrait.code,
        ),
      ),
      'library_filter_6_light',
    );
  }, skip: !autoUpdateGoldenFiles);
}
