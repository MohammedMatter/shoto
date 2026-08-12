import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/home/presentation/widgets/home_greeting.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// **A display name is untrusted input, and this is the proof.**
///
/// It arrives from a Google or Apple account and can be anything: three words,
/// a company, an empty string, a name longer than the screen. The greeting
/// puts it on the largest line of the app's first page, so every one of those
/// has to have a defined answer — and the one answer that is *not* acceptable
/// is cutting it short. "Abdurrahm…" reads as a bug about the person, not
/// about the layout.
///
/// These tests pin the three rules: first word only, refuse the absurd, and
/// **scale rather than ellipsise** everything in between.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._name);

  final String? _name;

  @override
  UserEntity? get currentUser =>
      _name == null ? null : UserEntity(id: 'u1', name: _name);

  @override
  String get userId => 'u1';

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

void main() {
  setUpAll(() {
    HomeGreeting.debugClock = () => DateTime(2026, 8, 9, 14);

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
  });

  tearDownAll(() => HomeGreeting.debugClock = null);

  /// Re-registered per test rather than once, because the whole point is what
  /// the widget does with *different* names.
  void useName(String? name) {
    if (sl.isRegistered<AuthRepository>()) {
      sl.unregister<AuthRepository>();
    }
    sl.registerSingleton<AuthRepository>(_FakeAuthRepository(name));
  }

  tearDown(() {
    if (sl.isRegistered<AuthRepository>()) {
      sl.unregister<AuthRepository>();
    }
  });

  Future<void> pump(WidgetTester tester, String? name) async {
    useName(name);
    // A phone-width viewport, because the question is entirely about what
    // happens when a name runs out of room.
    tester.view.physicalSize = const Size(1080, 800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: HomeGreeting(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Whether the paragraph actually ran out of room.
  ///
  /// `find.text` matches on `Text.data`, which is the string handed *in* — an
  /// ellipsised line still reports it in full, so asserting on that alone
  /// would pass while the screen showed "Abdurrahm…". `didExceedMaxLines` is
  /// the renderer's own answer to "did I have to cut this", which is the
  /// question.
  bool wasTruncated(WidgetTester tester, Finder textFinder) {
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: textFinder, matching: find.byType(RichText)).first,
    );
    return paragraph.didExceedMaxLines;
  }

  testWidgets('an ordinary name is shown whole', (WidgetTester tester) async {
    await pump(tester, 'Mohammed');
    expect(find.text('Mohammed'), findsOneWidget);
    expect(find.text('Good afternoon'), findsOneWidget);
  });

  testWidgets('only the first word is used', (WidgetTester tester) async {
    await pump(tester, 'Mohammed Abo Matter');
    expect(find.text('Mohammed'), findsOneWidget);
    expect(find.text('Mohammed Abo Matter'), findsNothing);
  });

  testWidgets('a name written with extra whitespace still yields a word', (
    WidgetTester tester,
  ) async {
    // `split(' ')` would return an empty first token here and the greeting
    // would silently lose its name. Splitting on `\s+` is what stops it.
    await pump(tester, '  Mohammed   Abo ');
    expect(find.text('Mohammed'), findsOneWidget);
  });

  testWidgets('a long first name is scaled down, never cut', (
    WidgetTester tester,
  ) async {
    const String long = 'Abdurrahmanullah';
    await pump(tester, long);

    // Present in full. If the widget had kept its old `TextOverflow.ellipsis`
    // this still passes on `Text.data` — hence the paragraph check below.
    expect(find.text(long), findsOneWidget);
    expect(
      wasTruncated(tester, find.text(long)),
      isFalse,
      reason: 'the name must be scaled to fit, not ellipsised',
    );

    // And it is genuinely smaller than the untruncated headline would be:
    // `scaleDown` applies a transform, so the painted box is narrower than
    // the text's own intrinsic width.
    final FittedBox box = tester.widget<FittedBox>(find.byType(FittedBox));
    expect(box.fit, BoxFit.scaleDown);

    final Size painted = tester.getSize(find.byType(FittedBox));
    final Size intrinsic = tester.getSize(find.text(long));
    expect(
      painted.width,
      lessThan(intrinsic.width + 1),
      reason: 'a name too wide for the row must be scaled into it',
    );
  });

  testWidgets('an absurd name is refused rather than shrunk to nothing', (
    WidgetTester tester,
  ) async {
    final String absurd = 'A' * 60;
    await pump(tester, absurd);

    expect(find.text(absurd), findsNothing);
    // Falls all the way back: the greeting takes the headline slot itself.
    expect(find.text('Good afternoon'), findsOneWidget);
  });

  testWidgets('no account, and no empty comma', (WidgetTester tester) async {
    await pump(tester, null);
    expect(find.text('Good afternoon'), findsOneWidget);
    // Specifically the greeting's own comma. A bare `textContaining(',')`
    // matches the date line ("August 9, 2026 · Sunday") and fails for a
    // reason that has nothing to do with the name.
    expect(find.textContaining('afternoon,'), findsNothing);
  });

  testWidgets('an empty display name is treated as no name', (
    WidgetTester tester,
  ) async {
    await pump(tester, '   ');
    expect(find.text('Good afternoon'), findsOneWidget);
  });
}
