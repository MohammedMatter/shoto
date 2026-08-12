import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/funnel_log.dart';
import 'package:shoto/core/services/premium_bootstrap.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/domain/entities/folder_seed.dart';
import 'package:shoto/features/folders/domain/repositories/folders_repository.dart';
import 'package:shoto/features/folders/domain/use_cases/create_folder_use_case.dart';
import 'package:shoto/features/folders/domain/use_cases/get_folders_use_case.dart';
import 'package:shoto/features/quick_save/presentation/pages/quick_save_page.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/create_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_custom_intents_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_intent_ids_by_recent_use_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/update_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// **Covering has to be reachable from the sheet Android actually opens — and
/// it must not stand in front of it.**
///
/// Sharing a picture into Shoto does not start the app. `ShareActivity` starts,
/// boots Flutter on `/share`, and that route is [QuickSavePage] — a panel that
/// for a while knew only how to file into a folder. Covering was built,
/// translated into seven languages and covered by a golden, and all of it hung
/// off `ShareIntentListener`, which lives in the app shell that a share never
/// reaches. `MainActivity` declares no SEND filter at all. The app's headline
/// feature had a front door on a wall with no road to it.
///
/// The first road was a gate: a two-option choice the sheet opened on. That
/// reached the interesting case by charging the common one — nearly every
/// share is somebody keeping a picture, and all of them were stopped to
/// choose, in front of a sheet whose promise is that it takes two seconds.
///
/// So filing is the default and covering is one line in the header — the one
/// place on this panel with room already going spare, which means the sheet is
/// exactly as tall as it was before any of this. These tests are about both
/// halves: that the way in exists and says what it is, and that it never
/// becomes the thing you have to get past.
void main() {
  late Directory cache;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('shoto_share_test');
    // DevAccess and FeatureTrials both read here during the covering path's
    // lazy bootstrap.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // The bootstrap memoises its future at library scope, so without this the
    // second test observes the first one's initialization.
    resetPremiumServicesForTest();
    _register();
  });

  tearDown(() {
    sl.reset();
    if (cache.existsSync()) cache.deleteSync(recursive: true);
  });

  Future<AppLocalizations> english() =>
      AppLocalizations.delegate.load(const Locale('en'));

  /// One real file per shared image.
  ///
  /// Real, rather than a path that happens to be a string: the folder form
  /// draws a thumbnail of every incoming picture with `Image.file`, and a
  /// missing file turns that into a decode error thrown inside the test's own
  /// widget tree — a failure about the fixture, reported as a failure of the
  /// sheet.
  List<Map<String, Object?>> sharedImages(
    int count, {
    bool fromShoto = false,
  }) {
    return List<Map<String, Object?>>.generate(count, (int index) {
      final File file = File('${cache.path}/shared_$index.png');
      file.writeAsBytesSync(_onePixelPng);
      // No mediaId: this is a picture arriving from another app, which is the
      // case the covering offer exists for. With one, the sheet would resolve
      // it against the library first.
      return <String, Object?>{
        'path': file.path,
        'mediaId': null,
        'fromShoto': fromShoto,
      };
    });
  }

  /// Answers the platform channel `ShareActivity` would be on the other end of.
  ///
  /// [counts] is served one entry per `getSharedImages`, so a test can hand
  /// the sheet a *different* share the second time it asks — which is the only
  /// way to tell a real re-read from a rebuild that kept the old answer.
  void mockShareChannel(
    List<int> counts, {
    VoidCallback? onClose,
    bool fromShoto = false,
  }) {
    final List<int> remaining = List<int>.of(counts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('shoto/share'), (
          MethodCall call,
        ) async {
          switch (call.method) {
            case 'getSharedImages':
              final int count = remaining.length > 1
                  ? remaining.removeAt(0)
                  : remaining.first;
              return <String, Object?>{
                'images': sharedImages(count, fromShoto: fromShoto),
                'skipped': 0,
              };
            case 'close':
              // The activity finishing is the only observable difference
              // between "done" and "back where you started", so it is what the
              // hand-off test asserts on.
              onClose?.call();
              return null;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('shoto/share'), null),
    );
  }

  /// Swallows the system share sheet, which a test has no way to answer.
  void mockSystemShareSheet() {
    const MethodChannel channel = MethodChannel(
      'dev.fluttercommunity.plus/share',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => 'dev.test');
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
  }

  /// Sends the platform message `ShareActivity.onNewIntent` sends.
  Future<void> deliverSecondShare(WidgetTester tester) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          'shoto/share',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('reshare'),
          ),
          (ByteData? _) {},
        );
    await tester.pumpAndSettle();
  }

  /// Stands the sheet up against whatever mocks the test has already set.
  Future<void> pumpSheetOnly(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.light),
          home: const QuickSavePage(),
        ),
      ),
    );

    // The sheet defers its first real rebuild until the entrance finishes —
    // see `_entered` — so a single pump only ever shows the spinner.
    await tester.pumpAndSettle();
  }

  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<int> images,
  }) async {
    mockShareChannel(images);
    await pumpSheetOnly(tester);
  }

  testWidgets('the sheet opens on filing, with covering named in the header', (
    tester,
  ) async {
    await pumpSheet(tester, images: <int>[1]);
    final AppLocalizations l10n = await english();

    // Filing is what is there on arrival — folders, and the folder chip the
    // fake library provides. Nothing has to be answered to reach it.
    expect(find.text('Receipts'), findsOneWidget);

    // Covering is present, as a labelled button plus the short question that
    // says why you would press it. A bare shield was an earlier build, and an
    // icon with no words reads as decoration rather than as a control.
    expect(find.text(l10n.quickSaveCoverAction), findsOneWidget);
    expect(find.text(l10n.quickSaveCoverWhy), findsOneWidget);
  });

  testWidgets('the entry costs the sheet no height at all', (tester) async {
    // **The constraint this whole arrangement exists to satisfy.**
    //
    // Two earlier designs put covering in front of filing — a two-option gate,
    // then a full-width row under the save button — and both were rejected for
    // the same reason: this sheet is a two-second surface and every pixel it
    // grows is a pixel of it arriving later.
    //
    // The entry sits in the header's own column, beside a thumbnail whose size
    // sets that row's height and which two lines of text do not fill. So the
    // words land in space the sheet was already paying for.
    //
    // Measured as the header being no taller with the entry than without it,
    // on two shares that are otherwise identical — one picture each, same
    // title, same folders, differing only in whether covering applies. That is
    // exactly the difference being priced.
    await pumpSheet(tester, images: <int>[1]);
    final AppLocalizations l10n = await english();
    expect(find.text(l10n.quickSaveCoverAction), findsOneWidget);
    final double withEntry = tester
        .getSize(find.byKey(const ValueKey<String>('shareHeader')))
        .height;

    // Torn down and rebuilt so the second sheet is a genuinely fresh read
    // rather than the first one rebuilt — the widget goes before the locator
    // is reset, so nothing is left resolving against a dead graph.
    await tester.pumpWidget(const SizedBox.shrink());
    await sl.reset();
    _register();
    mockShareChannel(<int>[1], fromShoto: true);
    await pumpSheetOnly(tester);
    expect(find.text(l10n.quickSaveCoverAction), findsNothing);
    final double without = tester
        .getSize(find.byKey(const ValueKey<String>('shareHeader')))
        .height;

    expect(withEntry, without);
  });

  testWidgets('a second share replaces the one on screen', (tester) async {
    // **The bug this exists for made the app look broken.** `ShareActivity` is
    // `singleTop`, so a share arriving while the sheet is still up is handed
    // to that instance rather than starting a new one — and until it forwarded
    // that, the sheet kept showing the previous picture and the share the user
    // had just performed did nothing whatsoever.
    //
    // Four images first, then one: the offer is absent on the first share by
    // the rule above and present on the second, so this can only pass if the
    // sheet genuinely re-read rather than rebuilding on a stale answer.
    await pumpSheet(tester, images: <int>[4, 1]);
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.quickSaveCoverAction), findsNothing);

    await deliverSecondShare(tester);

    expect(find.text(l10n.quickSaveCoverAction), findsOneWidget);
  });

  testWidgets('a second share unwinds whatever was stacked over the sheet', (
    tester,
  ) async {
    // Anything pushed over the panel belongs to the picture being replaced.
    // A Safe Share review left standing would show findings for a screenshot
    // the user is no longer sharing, above a button that sends it.
    await pumpSheet(tester, images: <int>[1, 1]);
    final AppLocalizations l10n = await english();

    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('review of the old picture')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('review of the old picture'), findsOneWidget);

    await deliverSecondShare(tester);

    expect(find.text('review of the old picture'), findsNothing);
    expect(find.text(l10n.quickSaveCoverAction), findsOneWidget);
  });

  testWidgets('handing the picture on closes the sheet, it does not re-ask', (
    tester,
  ) async {
    // **The complaint this exists for**: covering a screenshot and sending it
    // landed the user back on "cover it, or keep it?" — the app asking them to
    // start the task they had just finished. Both ways out of Safe Share
    // returned to the offer, so finishing looked exactly like retreating.
    final List<String> closed = <String>[];
    mockShareChannel(<int>[1], onClose: () => closed.add('closed'));
    mockSystemShareSheet();

    await pumpSheetOnly(tester);
    final AppLocalizations l10n = await english();

    await tester.tap(find.text(l10n.quickSaveCoverAction));
    await tester.pumpAndSettle();

    // The fake scanner finds nothing, so Safe Share offers the one-button
    // "send it anyway" — still a completed hand-off, and still the end.
    await tester.tap(find.text(l10n.safeShareShareAnyway));
    await tester.pumpAndSettle();

    // Asserted as the `close` call rather than as the offer disappearing.
    // What removes the offer from a real screen is Android finishing the
    // activity, which is exactly what this call asks for — in a widget test
    // there is no activity, so the retracted sheet is still in the tree.
    // `close` is the whole difference between "done" and "asked again".
    expect(closed, <String>['closed'], reason: 'the activity must finish');
  });

  testWidgets('backing out of covering does return to the offer', (
    tester,
  ) async {
    // The other half of the same rule. A mis-tap on "cover" must not cost the
    // whole share — that is why the offer is still here on the way back.
    final List<String> closed = <String>[];
    mockShareChannel(<int>[1], onClose: () => closed.add('closed'));
    mockSystemShareSheet();

    await pumpSheetOnly(tester);
    final AppLocalizations l10n = await english();

    await tester.tap(find.text(l10n.quickSaveCoverAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.safeShareShareAnyway), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.quickSaveCoverAction), findsOneWidget);
    // And the sheet stayed: retreating must not finish the activity, or the
    // mis-tap this branch exists to forgive would cost the share after all.
    expect(closed, isEmpty);
  });

  // **"Keep the copy in Shoto" has no widget test, and that is a gap, not a
  // decision.**
  //
  // The path renders the covered image and *writes it to disk* before the page
  // pops. A widget test drives its own clock and does not drive the
  // filesystem, so the write never completes inside `pumpAndSettle` — and
  // `runAsync` around the tap does not rescue it either, because the write is
  // started by the framework's own gesture callback rather than by the test.
  //
  // Faking the write would leave the assertion testing a mock. So the button
  // is checked on a device instead, and this note is here so the next person
  // knows the absence was noticed rather than overlooked.

  testWidgets('the covered copy coming back goes straight to the folders', (
    tester,
  ) async {
    // **Closing the loop the covering flow opens.** Covering ends at the
    // system share sheet, and Shoto is one of the choices there — so "cover
    // this, then keep the clean copy" is a single sensible run of the feature.
    // Offering to cover the copy that Safe Share had just produced made the
    // app look like it had forgotten what it was doing ten seconds earlier.
    mockShareChannel(<int>[1], fromShoto: true);

    await pumpSheetOnly(tester);
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.quickSaveCoverAction), findsNothing);
    expect(find.text('Receipts'), findsOneWidget);
  });

  testWidgets('a multi-image share is never offered covering', (tester) async {
    // Safe Share reviews one capture. An offer spanning four would have to act
    // on one of them, and the user would send the other three believing all
    // four had been checked — so this share goes straight to filing.
    await pumpSheet(tester, images: <int>[4]);
    final AppLocalizations l10n = await english();

    expect(find.text(l10n.quickSaveCoverAction), findsNothing);
    expect(find.text('Receipts'), findsOneWidget);
  });
}

/// Everything [QuickSavePage] resolves, and nothing else.
void _register() {
  final _FakeScreenshotRepository screenshots = _FakeScreenshotRepository();
  final _FakeFoldersRepository folders = _FakeFoldersRepository();

  sl.registerSingleton<ScreenshotRepository>(screenshots);
  sl.registerSingleton<FoldersRepository>(folders);
  sl.registerSingleton(GetFoldersUseCase(folders));
  sl.registerSingleton(CreateFolderUseCase(folders));
  sl.registerSingleton(ThemeController());

  // Every tappable surface in the app fires a haptic, and the haptic reads the
  // preference at call time — so a tap in a test that has not registered this
  // throws out of the gesture handler and the tap silently does nothing.
  // Unloaded is the right state here: it defaults to on, which is what a tap
  // in the app does.
  sl.registerSingleton(AppPreferences());

  // What the covering path stands up on the tap. The store is faked because a
  // test has no RevenueCat; the other two are the real thing over mocked
  // preferences, since their whole job is reading those.
  // Written to when the covering pass actually produces a copy.
  sl.registerSingleton(FunnelLog());
  sl.registerSingleton(DevAccess());
  sl.registerSingleton(FeatureTrials());
  final _FakeSubscriptionRepository store = _FakeSubscriptionRepository();
  sl.registerSingleton<SubscriptionRepository>(store);
  // Read by `ensurePremium`, which the covering screen's unlock runs through.
  sl.registerSingleton(GetSubscriptionStatusUseCase(store));

  // Finds nothing, on purpose. A scanner that reported findings would put the
  // paywall between the tap and the hand-off, and what these tests are about
  // is what happens *after* the picture leaves — not the gate in front of it.
  sl.registerSingleton<RedactionService>(_FakeRedactionService());

  // The intent row on the folder form reads the catalog, and the catalog is
  // assembled from five use cases over the same repository — so the fake above
  // is enough to stand all of it up.
  sl.registerSingleton(
    IntentCatalog(
      getCustomIntentsUseCase: GetCustomIntentsUseCase(screenshots),
      getIntentIdsByRecentUseUseCase: GetIntentIdsByRecentUseUseCase(
        screenshots,
      ),
      createCustomIntentUseCase: CreateCustomIntentUseCase(screenshots),
      updateCustomIntentUseCase: UpdateCustomIntentUseCase(screenshots),
      deleteCustomIntentUseCase: DeleteCustomIntentUseCase(screenshots),
    ),
  );
}

/// A 1x1 transparent PNG — the smallest thing `Image.file` will decode.
final Uint8List _onePixelPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

/// Only the four members this sheet touches are answered.
///
/// `noSuchMethod` throws for the rest on purpose: a fake that silently returns
/// null for thirty methods hides the day one of them starts being called.
class _FakeScreenshotRepository implements ScreenshotRepository {
  @override
  Future<String?> findLibraryAsset(String assetId) async => null;

  @override
  Future<List<CustomIntent>> getCustomIntents() async =>
      const <CustomIntent>[];

  @override
  Future<List<String>> getIntentIdsByRecentUse() async => const <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'ScreenshotRepository.${invocation.memberName} was not expected here',
  );
}

/// Reports a clean screenshot, so covering runs straight through to the
/// hand-off without a paywall standing in the way.
class _FakeRedactionService implements RedactionService {
  /// Reports a clean screenshot, which takes the covering screen straight to
  /// its "nothing found" state — one button, no paywall in the way. These
  /// tests are about where the picture goes afterwards, and a review with
  /// findings would put the gate between the tap and the answer.
  @override
  Future<RedactionPlan> scan(File imageFile) async => const RedactionPlan(
    regions: <SensitiveRegion>[],
    imageSize: Size(100, 100),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'RedactionService.${invocation.memberName} was not expected here',
  );
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<void> initialize() async {}

  /// A subscriber, so `ensurePremium` returns on its first check.
  ///
  /// The free-trial branch would work too and is deliberately avoided: it
  /// raises a snack bar saying the try was on us, and a snack bar is a four
  /// second animation that keeps the tree from ever settling. These tests are
  /// about where the covered copy goes, not about the gate in front of it —
  /// the gate has its own tests.
  @override
  Future<SubscriptionStatus> getStatus() async =>
      const SubscriptionStatus(isPremium: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'SubscriptionRepository.${invocation.memberName} was not expected here',
  );
}

class _FakeFoldersRepository implements FoldersRepository {
  @override
  Future<List<FolderEntity>> getFolders() async => <FolderEntity>[
    FolderEntity(
      id: 1,
      name: 'Receipts',
      color: 0xFF4C8DFF,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  Future<bool> seedDefaultFolders(List<FolderSeed> seeds) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'FoldersRepository.${invocation.memberName} was not expected here',
  );
}
