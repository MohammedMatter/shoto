import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/localization/locale_controller.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/cache_service.dart';
import 'package:shoto/core/services/crash_reporting.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/settings/presentation/pages/settings_page.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// **The Settings page, driven rather than photographed.**
///
/// `settings_group_golden_test.dart` renders the *building blocks* by hand and
/// checks what they look like. That is the right shape for reviewing spacing
/// and colour, and it is blind to everything this file is about: it never
/// builds the real page, so it cannot notice a row that stopped reading its
/// controller, a badge that outlived the subscription that justified it, or a
/// label that overflows in German at the largest font scale.
///
/// **Two rows are absent here and it is not a gap in the test.**
/// `CaptureAlertsTile` and the Quick Settings row both gate on
/// `Platform.isAndroid`, which is false on the machine a widget test runs on —
/// so the page under test is genuinely the page a non-Android build draws.
/// That is worth knowing when reading a count of rows below, and it is checked
/// explicitly rather than left as a surprise.
void main() {
  late _FakeSubscriptionRepository subscription;
  late _FakeAuthRepository auth;
  late _FakeCacheService cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    subscription = _FakeSubscriptionRepository();
    auth = _FakeAuthRepository();
    cache = _FakeCacheService();

    await sl.reset();
    sl
      ..registerLazySingleton<AppPreferences>(() => AppPreferences())
      ..registerLazySingleton<ThemeController>(() => ThemeController())
      ..registerLazySingleton<LocaleController>(() => LocaleController())
      ..registerLazySingleton<CrashReporting>(() => CrashReporting())
      ..registerLazySingleton<DevAccess>(() => DevAccess())
      ..registerLazySingleton<FeatureTrials>(() => FeatureTrials())
      ..registerLazySingleton<CacheService>(() => cache)
      ..registerLazySingleton<AuthRepository>(() => auth)
      ..registerLazySingleton<ProStatus>(
        () => ProStatus(subscription, sl<DevAccess>()),
      );

    // The card at the top draws nothing until the store has answered once —
    // "not known yet" is deliberately not "not subscribed". Resolving it here
    // means every test below sees the page a real user sees.
    await sl<ProStatus>().refresh();
  });

  tearDown(() => sl.reset());

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Brightness brightness = Brightness.dark,
    Size size = const Size(1080, 2400),
  }) async {
    await loadTestFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    // The entrance stagger delays the later blocks by up to 240ms, and every
    // one of them holds an AnimationController — so nothing here can assert on
    // content until they have all arrived and settled.
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  }

  /// Brings [target] into view, scrolling only as far as it has to.
  ///
  /// **Rows below the fold are not built until they are scrolled to**, because
  /// this is a `ListView` — and just as importantly, rows scrolled *past* are
  /// disposed again. An earlier version of this file dragged to the bottom and
  /// then asserted on the heading at the top, which fails for a reason that has
  /// nothing to do with the page: the widget was real, built, and thrown away
  /// before anybody looked.
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// Drags from top to bottom without asserting anything, for the tests whose
  /// subject is that *nothing throws* on the way.
  Future<void> scrollThrough(WidgetTester tester) async {
    final Finder list = find.byType(Scrollable).first;
    for (int i = 0; i < 14; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  group('what the page draws', () {
    testWidgets('every group heading is present, in order', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      const List<String> titles = <String>[
        'Appearance',
        'Behaviour',
        'Storage',
        // The heading is "Pro", not "Premium" — the l10n key is
        // `settingsPremium` and the string is not. Reading the key instead of
        // the value is how a test ends up asserting a word the app never shows.
        'Pro',
        'Help',
        'Account',
      ];

      // **Swept rather than searched, and the difference matters.**
      // `scrollUntilVisible` needs a finder that resolves to one widget, and
      // "Appearance" is deliberately two — a group heading and the row inside
      // it. Dragging a fixed distance and noting what is on screen at each step
      // asks the question without needing the answer to be unique, and it
      // records *when* each was seen, which is what turns presence into order.
      final Map<String, int> firstSeen = <String, int>{};
      final Finder list = find.byType(Scrollable).first;
      for (int step = 0; step < 20; step++) {
        for (final String title in titles) {
          if (find.text(title).evaluate().isNotEmpty) {
            firstSeen.putIfAbsent(title, () => step);
          }
        }
        await tester.drag(list, const Offset(0, -280));
        await tester.pumpAndSettle();
      }

      for (final String title in titles) {
        expect(
          firstSeen,
          contains(title),
          reason: '$title never appeared on the way down',
        );
      }
      final List<int> order = titles
          .map((String t) => firstSeen[t]!)
          .toList(growable: false);
      expect(
        order,
        orderedEquals(<int>[...order]..sort()),
        reason: 'the groups are no longer in the documented running order',
      );
    });

    testWidgets('the two platform-gated rows are absent off Android', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await scrollThrough(tester);

      // Named so the day these start rendering on the host — a plugin gaining
      // a desktop implementation, someone swapping `Platform.isAndroid` for a
      // TargetPlatform check — this fails loudly rather than the other tests
      // quietly changing meaning.
      expect(find.text('Quick Settings tile'), findsNothing);
      expect(find.text('Notify me right away'), findsNothing);
    });

    testWidgets('rows state their current answer on the trailing edge', (
      WidgetTester tester,
    ) async {
      cache.bytes = 12_400_000;
      await sl<ThemeController>().setThemeMode(ThemeMode.dark);
      await pump(tester);

      // Appearance says which theme is in force, not what is inside the page.
      expect(find.text('Dark'), findsOneWidget);
      // Language says the language actually being read.
      expect(find.text('English'), findsOneWidget);

      await reveal(tester, find.text('Clear image cache'));
      // The cache says its size, wrapped in bidi isolates so it survives an
      // RTL paragraph — the assertion has to carry them too or it is testing
      // a string the app never produces.
      expect(find.text('\u206611.8 MB\u2069'), findsOneWidget);
    });

    testWidgets('the signed-in account is named at the top and in Account', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('Mary Lo'), findsOneWidget);
      // In the header, under the name.
      expect(find.text('mary@example.com'), findsOneWidget);

      // And again as the caption on the Account group, which is the other
      // place the question "which account is this" gets asked.
      await reveal(tester, find.text('Sign out'));
      expect(find.text('mary@example.com'), findsOneWidget);
    });

    testWidgets('signed out, the header falls back to the product name', (
      WidgetTester tester,
    ) async {
      auth.user = null;
      await pump(tester);

      expect(find.text('Shoto'), findsWidgets);
      expect(find.text('Mary Lo'), findsNothing);
    });
  });

  group('the PRO tag is a price, and comes down once it is paid', () {
    testWidgets('free: the paid row is tagged', (WidgetTester tester) async {
      await pump(tester);
      await reveal(tester, find.text('Find duplicates'));
      expect(find.byType(ProBadge), findsWidgets);
    });

    testWidgets('a subscription landing takes the tag off without a rebuild', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await reveal(tester, find.text('Find duplicates'));
      expect(find.byType(ProBadge), findsWidgets);

      // The page is kept alive in the shell's stack and does not rebuild on
      // its own — so this only passes while the page is listening to
      // ProStatus. That listener has been removed once already.
      subscription.status = SubscriptionStatus.tester;
      await sl<ProStatus>().refresh();
      await tester.pumpAndSettle();

      // The badge on the *rows* is gone. The header keeps its own, which is a
      // different claim — "you are on Pro" rather than "this costs money".
      expect(find.text('Find duplicates'), findsOneWidget);
      final Finder duplicatesRow = find.ancestor(
        of: find.text('Find duplicates'),
        matching: find.byType(SettingsNavTile),
      );
      expect(
        find.descendant(of: duplicatesRow, matching: find.byType(ProBadge)),
        findsNothing,
      );
    });
  });

  group('rows follow the controllers behind them', () {
    testWidgets('the Appearance row restates the theme when it changes', (
      WidgetTester tester,
    ) async {
      await sl<ThemeController>().setThemeMode(ThemeMode.light);
      await pump(tester);
      expect(find.text('Light'), findsOneWidget);

      await sl<ThemeController>().setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      expect(
        find.text('Light'),
        findsNothing,
        reason: 'the row kept the mode the user just left',
      );
    });

    testWidgets('the Language row restates the language when it changes', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      expect(find.text('English'), findsOneWidget);

      await sl<LocaleController>().setLanguage(AppLanguage.german);
      await tester.pumpAndSettle();

      expect(find.text('Deutsch'), findsOneWidget);
    });
  });

  group('switches write what they claim to write', () {
    testWidgets('haptics toggles the preference both ways', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final AppPreferences prefs = sl<AppPreferences>();
      final bool before = prefs.haptics;

      final Finder row = find.ancestor(
        of: find.text('Haptic feedback'),
        matching: find.byType(SettingsSwitchTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(AppSwitch)),
      );
      await tester.pumpAndSettle();
      expect(prefs.haptics, !before);

      await tester.tap(
        find.descendant(of: row, matching: find.byType(AppSwitch)),
      );
      await tester.pumpAndSettle();
      expect(prefs.haptics, before);
    });

    testWidgets('ask-before-deleting toggles the preference', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      final AppPreferences prefs = sl<AppPreferences>();
      final bool before = prefs.confirmBeforeDelete;

      final Finder row = find.ancestor(
        of: find.text('Ask before deleting'),
        matching: find.byType(SettingsSwitchTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(AppSwitch)),
      );
      await tester.pumpAndSettle();

      expect(prefs.confirmBeforeDelete, !before);
    });

    testWidgets('crash reports toggles the service', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await reveal(tester, find.text('Crash reports'));
      final CrashReporting crashes = sl<CrashReporting>();
      final bool before = crashes.isEnabled;

      final Finder row = find.ancestor(
        of: find.text('Crash reports'),
        matching: find.byType(SettingsSwitchTile),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(AppSwitch)),
      );
      await tester.pumpAndSettle();

      expect(crashes.isEnabled, !before);
    });
  });

  group('the cache row', () {
    testWidgets('an empty cache is drawn as unavailable, not as an offer', (
      WidgetTester tester,
    ) async {
      cache.bytes = 0;
      await pump(tester);
      await reveal(tester, find.text('Clear image cache'));

      final SettingsNavTile tile = tester.widget<SettingsNavTile>(
        find.ancestor(
          of: find.text('Clear image cache'),
          matching: find.byType(SettingsNavTile),
        ),
      );
      expect(
        tile.onTap,
        isNull,
        reason: 'a cache with nothing in it must not invite a tap',
      );
    });

    testWidgets('clearing empties it and the row re-measures itself', (
      WidgetTester tester,
    ) async {
      cache.bytes = 5 * 1024 * 1024;
      await pump(tester);
      await reveal(tester, find.text('Clear image cache'));

      expect(find.text('\u20665.0 MB\u2069'), findsOneWidget);

      await tester.tap(find.text('Clear image cache'));
      await tester.pumpAndSettle();

      expect(cache.cleared, isTrue);
      // Re-measured rather than left showing a size that is no longer there.
      expect(find.text('\u20665.0 MB\u2069'), findsNothing);
    });
  });

  group('nothing overflows', () {
    /// Every combination that has historically broken a row: the longest
    /// language in the app, the largest font scale a phone offers, the
    /// narrowest screen still supported, and both text directions.
    ///
    /// A `RenderFlex` overflow throws in a test rather than painting the yellow
    /// stripes, so `tester.takeException()` returning null *is* the assertion.
    for (final (String label, Locale locale, double scale, Size size)
        in const <(String, Locale, double, Size)>[
          ('english, default', Locale('en'), 1.0, Size(1080, 2400)),
          ('german, default', Locale('de'), 1.0, Size(1080, 2400)),
          ('german, 1.3x', Locale('de'), 1.3, Size(1080, 2400)),
          ('german, 1.3x, narrow', Locale('de'), 1.3, Size(720, 1600)),
          ('portuguese, 1.5x', Locale('pt'), 1.5, Size(1080, 2400)),
          ('french, 2.0x', Locale('fr'), 2.0, Size(1080, 2400)),
        ]) {
      testWidgets('no overflow — $label', (WidgetTester tester) async {
        await pump(tester, locale: locale, textScale: scale, size: size);
        expect(tester.takeException(), isNull);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no overflow in either brightness', (
      WidgetTester tester,
    ) async {
      for (final Brightness brightness in Brightness.values) {
        await pump(tester, brightness: brightness);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('destructive and disabled rows are drawn as such', () {
    testWidgets('sign out is red and offers no chevron', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      await reveal(tester, find.text('Sign out'));

      final Finder row = find.ancestor(
        of: find.text('Sign out'),
        matching: find.byType(SettingsNavTile),
      );
      expect(tester.widget<SettingsNavTile>(row).isDestructive, isTrue);

      // A chevron promises a screen; this opens a dialog and then leaves.
      expect(
        find.descendant(
          of: row,
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsNothing,
      );

      final Text label = tester.widget<Text>(find.text('Sign out'));
      expect(
        label.style?.color,
        testPalette(Brightness.dark).error,
        reason: 'the destructive row lost its red',
      );
    });

    testWidgets('a disabled row greys its glyph as well as its label', (
      WidgetTester tester,
    ) async {
      cache.bytes = 0;
      await pump(tester);
      await reveal(tester, find.text('Clear image cache'));

      final Finder glyph = find.descendant(
        of: find.ancestor(
          of: find.text('Clear image cache'),
          matching: find.byType(SettingsNavTile),
        ),
        matching: find.byType(SettingsGlyph),
      );
      final Icon icon = tester.widget<Icon>(
        find.descendant(of: glyph, matching: find.byType(Icon)),
      );
      expect(icon.color, testPalette(Brightness.dark).textDisabled);
    });
  });

  group('every row can actually be hit', () {
    /// Material and WCAG both put the floor at 48dp. The rows are deliberately
    /// no longer a uniform height — most lost their second line — and shrinking
    /// a list is the standard way to end up under it without noticing, so the
    /// floor is asserted rather than assumed.
    ///
    /// Measured on the *rendered* row rather than on the constraint that is
    /// supposed to produce it: `minHeight: 56.h` is a claim about logical
    /// pixels after `flutter_screenutil` has scaled it, and reading the number
    /// back out of the source would be checking that the code says what it
    /// says.
    testWidgets('no tappable row is under 48dp tall', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final Finder list = find.byType(Scrollable).first;
      int measured = 0;
      for (int step = 0; step < 20; step++) {
        for (final Element row in <Element>[
          ...find.byType(SettingsNavTile).evaluate(),
          ...find.byType(SettingsSwitchTile).evaluate(),
        ]) {
          final Size size = tester.getSize(find.byWidget(row.widget));
          measured++;
          expect(
            size.height,
            greaterThanOrEqualTo(48.0),
            reason: 'a row is only ${size.height.toStringAsFixed(1)}dp tall',
          );
        }
        await tester.drag(list, const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      expect(
        measured,
        greaterThan(10),
        reason: 'the sweep never saw the rows, so it proved nothing',
      );
    });
  });

  group('the page settles', () {
    testWidgets('the entrance finishes and leaves nothing animating', (
      WidgetTester tester,
    ) async {
      await pump(tester);
      // `pumpAndSettle` inside `pump` would already have thrown on a
      // never-ending animation; this states the guarantee rather than relying
      // on a helper to have done it, because a stagger that re-armed itself on
      // every rebuild is exactly the bug that would not show up anywhere else.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a rebuild mid-life does not replay the entrance', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      subscription.status = SubscriptionStatus.tester;
      await sl<ProStatus>().refresh();
      await tester.pump();

      // **Not `hasRunningAnimations`**, which is true here and correctly so:
      // the subscription card cross-fades between its two states, and
      // `subscription_card_widget.dart` argues at length for that one
      // transition. The claim being made is narrower — that the *entrance* did
      // not re-arm — so it is checked where it would show, on the opacity of
      // the blocks that entrance drives.
      final Iterable<Element> blocks = find.byType(EntranceStagger).evaluate();
      expect(blocks, isNotEmpty, reason: 'the entrance was never wired up');
      for (final Element block in blocks) {
        // The *outermost* fade under each block is the stagger's own. Taking
        // every descendant instead sweeps up the subscription card's
        // `AnimatedSwitcher`, which is legitimately mid-cross-fade right now
        // and would fail this for the one reason it is not asking about.
        final FadeTransition fade = tester.widget<FadeTransition>(
          find
              .descendant(
                of: find.byWidget(block.widget),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(
          fade.opacity.value,
          1.0,
          reason: 'a settled block faded itself back in',
        );
      }
    });
  });
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  SubscriptionStatus status = SubscriptionStatus.free;

  @override
  Future<SubscriptionStatus> getStatus() async => status;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements AuthRepository {
  UserEntity? user = const UserEntity(
    id: 'u1',
    name: 'Mary Lo',
    email: 'mary@example.com',
  );

  @override
  UserEntity? get currentUser => user;

  @override
  String get userId => 'device-1';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for the real one, which measures the OS temporary directory
/// through `path_provider` — a platform channel that answers nothing in a
/// widget test.
class _FakeCacheService implements CacheService {
  int bytes = 0;
  bool cleared = false;

  @override
  Future<int> getCacheSizeBytes() async => bytes;

  @override
  Future<void> clearCache() async {
    cleared = true;
    bytes = 0;
  }
}
