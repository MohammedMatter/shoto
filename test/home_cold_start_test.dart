import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/core/widgets/skeleton.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:shoto/features/folders/presentation/bloc/folders_state.dart';
import 'package:shoto/features/home/presentation/pages/home_page.dart';
import 'package:shoto/features/home/presentation/widgets/home_inbox.dart';
import 'package:shoto/features/home/presentation/widgets/home_search_field.dart';
import 'package:shoto/features/screenshots/domain/entities/library_summary.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_bloc.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// What Home draws in the second before the gallery answers.
///
/// **The bug this pins.** Closing Shoto completely and reopening it used to
/// show a hole where the main block goes: the loading branch drew
/// `SizedBox.shrink`, and every structural decision on the page — whether
/// there is a search field, whether there is a Recent section, which of two
/// headings Tools gets — was made from `screenshots.isNotEmpty`, which is
/// false for the whole of a cold start no matter how full the library is. So
/// the app opened in the shape of a fresh install and then rearranged itself
/// into the shape of a used one. That is not slowness; it is the page changing
/// its mind while somebody is looking at it.
///
/// None of this is visible in a golden, which photographs one settled frame.
/// What matters here is the *unsettled* one.
class _StubScreenshotsBloc extends Cubit<ScreenshotsState>
    implements ScreenshotsBloc {
  _StubScreenshotsBloc(super.state);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFoldersBloc extends Cubit<FoldersState> implements FoldersBloc {
  _StubFoldersBloc() : super(FoldersLoadedState(const []));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCaptures implements ScreenshotRepository {
  @override
  Future<List<AssetEntity>> getNewCaptures({required DateTime since}) async =>
      const [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<ThemeController>()) {
      sl.registerLazySingleton<ThemeController>(() => ThemeController());
    }
    if (!sl.isRegistered<DevAccess>()) {
      sl.registerLazySingleton<DevAccess>(() => DevAccess());
    }
    if (!sl.isRegistered<FeatureTrials>()) {
      sl.registerLazySingleton<FeatureTrials>(() => FeatureTrials());
    }
    if (!sl.isRegistered<ProStatus>()) {
      sl.registerLazySingleton<ProStatus>(
        () => ProStatus(_FakeSubscriptionRepository(), sl<DevAccess>()),
      );
    }
    if (!sl.isRegistered<GetNewCapturesUseCase>()) {
      sl.registerLazySingleton<GetNewCapturesUseCase>(
        () => GetNewCapturesUseCase(_NoCaptures(), sl<AppPreferences>()),
      );
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
          home: MultiBlocProvider(
            providers: [
              BlocProvider<ScreenshotsBloc>(
                create: (_) => _StubScreenshotsBloc(state),
              ),
              BlocProvider<FoldersBloc>(create: (_) => _StubFoldersBloc()),
            ],
            child: HomePage(
              onOpenLibrary: (_) {},
              onOpenLibraryForIntent: (_) {},
            ),
          ),
        ),
      ),
    );
    // Past the entrance cascade, but **never `pumpAndSettle`**: the
    // placeholders breathe on a repeating controller, so a settle here waits
    // for an animation that is designed never to end.
    await tester.pump(const Duration(milliseconds: 700));
  }

  /// A library of twelve with four still unsorted and two waiting to be paid,
  /// known from the local tables alone.
  final LibrarySummary summary = LibrarySummary(
    total: 12,
    unsorted: 4,
    // Not a const map: `IntentRef` overrides `==` so that a renamed custom
    // intent is still the same intent, and a class with custom equality
    // cannot be a constant map's key.
    waiting: <IntentRef, int>{const BuiltInIntent(ScreenshotIntent.pay): 2},
  );

  testWidgets('a cold start draws the real unsorted count, not a blank', (
    tester,
  ) async {
    await render(tester, ScreenshotsLoadingState(summary: summary));

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    expect(find.text(l10n.homeNeedsYou), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    // The verb the user set, with its own count beside it.
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the page is laid out for a library it knows exists', (
    tester,
  ) async {
    await render(tester, ScreenshotsLoadingState(summary: summary));

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    // All three were gated on having the *pictures*, and so were absent for
    // the whole of a cold start and then appeared — the search field pushing
    // everything down by its own height, Recent by a great deal more.
    expect(find.byType(HomeSearchField), findsOneWidget);
    expect(find.text(l10n.homeToolsTitle), findsOneWidget);
    expect(find.text(l10n.homeToolsTitleEmpty), findsNothing);

    // Recent sits below the fold on a phone, and a sliver list does not build
    // what it cannot show — so this has to be scrolled to rather than simply
    // looked for.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();
    expect(find.text(l10n.homeRecent), findsOneWidget);
  });

  testWidgets('nothing in the pending page is tappable into thin air', (
    tester,
  ) async {
    await render(tester, ScreenshotsLoadingState(summary: summary));

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    // Recent's "see all" opens the library this screen is still waiting for.
    expect(find.text(l10n.homeSeeAll), findsNothing);
  });

  testWidgets('with nothing known yet the space is held, not left empty', (
    tester,
  ) async {
    // No summary: the frames before even the local read has answered.
    await render(tester, ScreenshotsLoadingState());

    expect(find.byType(HomeInboxSkeleton), findsOneWidget);
    expect(find.byType(SkeletonPulse), findsWidgets);

    final AppLocalizations l10n = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    // And it claims nothing about a library nobody has looked at — least of
    // all that it is all filed.
    expect(find.text(l10n.homeInboxClear), findsNothing);
    expect(find.text(l10n.homeInboxEmpty), findsNothing);
  });

  testWidgets('an empty summary is a fresh install, not a pending one', (
    tester,
  ) async {
    await render(
      tester,
      ScreenshotsLoadingState(summary: LibrarySummary.empty),
    );

    // A device with nothing in its library has nothing to preview, so the
    // page must not reserve a search field and a picture strip for content
    // that is never going to arrive.
    expect(find.byType(HomeSearchField), findsNothing);
    expect(find.byType(HomeInbox), findsNothing);
  });
}
