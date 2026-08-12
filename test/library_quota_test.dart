import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/constants/subscription_constants.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/library_quota.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_managed_screenshot_count_use_case.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// The arithmetic behind the Library's quota band.
///
/// Every case here is one the widget cannot be trusted to reveal: a bar
/// clamped to its track looks identical whether the number behind it is 100%
/// or 137%, and "no ceiling" and "a very large ceiling" draw the same empty
/// space. These assert the numbers rather than the picture.
class _FakeScreenshotRepository implements ScreenshotRepository {
  _FakeScreenshotRepository(this.managed);

  int managed;

  /// Set to throw, to prove a failed count never wipes a good one.
  bool fail = false;

  @override
  Future<int> getManagedScreenshotCount() async {
    if (fail) throw StateError('database unavailable');
    return managed;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository(this.status);

  SubscriptionStatus status;
  final StreamController<SubscriptionStatus> _changes =
      StreamController<SubscriptionStatus>.broadcast();

  @override
  Future<SubscriptionStatus> getStatus() async => status;

  @override
  Stream<SubscriptionStatus> get statusChanges => _changes.stream;

  void emit(SubscriptionStatus next) {
    status = next;
    _changes.add(next);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeScreenshotRepository screenshots;
  late _FakeSubscriptionRepository subscription;
  late ProStatus pro;
  late LibraryQuota quota;

  Future<void> build({
    required int managed,
    required SubscriptionStatus status,
  }) async {
    screenshots = _FakeScreenshotRepository(managed);
    subscription = _FakeSubscriptionRepository(status);
    pro = ProStatus(subscription, DevAccess());
    await pro.load();
    quota = LibraryQuota(
      GetManagedScreenshotCountUseCase(screenshots),
      pro,
    );
    await quota.load();
  }

  test('a free library reports its count against the cap', () async {
    // **Derived from the cap, never a literal.** This was written as 41 of
    // 100 and broke the day the free tier moved to fifteen — not because the
    // meter was wrong, but because the test had the old business decision
    // baked into it. The number is a product choice and will move again; what
    // must hold is that a library under the line reports itself as under it.
    const int cap = SubscriptionConstants.freeScreenshotLimit;
    const int managed = cap - 1;
    await build(managed: managed, status: SubscriptionStatus.free);

    expect(quota.used, managed);
    expect(quota.limit, cap);
    expect(quota.isUnlimited, isFalse);
    expect(quota.isFull, isFalse);
    expect(quota.fraction, closeTo(managed / cap, 0.001));
  });

  test('the bar never overflows a library past its ceiling', () async {
    // A real state, not a corruption: the gate refuses *new* items only, so
    // anyone who was over the line before the cap existed — or who filled up
    // on Pro and then lapsed — keeps every screenshot they had.
    // Comfortably past whatever the cap currently is, for the same reason the
    // test above derives its number: the ceiling is a product decision that
    // moves, and "past it" has to keep meaning past it.
    const int over = SubscriptionConstants.freeScreenshotLimit * 2 + 7;
    await build(managed: over, status: SubscriptionStatus.free);

    expect(quota.isFull, isTrue);
    expect(quota.fraction, 1.0, reason: 'a bar wider than its track is a bug');
    expect(quota.used, over, reason: 'the number itself is never clamped');
  });

  test('exactly at the cap counts as full', () async {
    await build(
      managed: SubscriptionConstants.freeScreenshotLimit,
      status: SubscriptionStatus.free,
    );

    expect(quota.isFull, isTrue);
    expect(quota.fraction, 1.0);
  });

  test('a subscriber has no ceiling, and so no fraction to draw', () async {
    await build(
      managed: 137,
      status: const SubscriptionStatus(isPremium: true),
    );

    expect(quota.isUnlimited, isTrue);
    expect(quota.limit, isNull);
    // Null rather than 0: "no measure applies" is a different answer from
    // "the measure reads empty", and the band keys off it to draw nothing.
    expect(quota.fraction, isNull);
    expect(quota.isFull, isFalse, reason: 'no ceiling can never be reached');
  });

  test('paying removes the ceiling without the count moving', () async {
    const int managed = SubscriptionConstants.freeScreenshotLimit - 2;
    await build(managed: managed, status: SubscriptionStatus.free);
    expect(quota.limit, SubscriptionConstants.freeScreenshotLimit);

    int notifications = 0;
    quota.addListener(() => notifications++);

    subscription.emit(const SubscriptionStatus(isPremium: true));
    await Future<void>.delayed(Duration.zero);

    expect(quota.isUnlimited, isTrue);
    expect(
      quota.used,
      managed,
      reason: 'the library did not change, the plan did',
    );
    expect(
      notifications,
      greaterThan(0),
      reason: 'the band has to repaint the moment the purchase lands',
    );
  });

  test('a failed count leaves the last good one standing', () async {
    await build(managed: 41, status: SubscriptionStatus.free);

    screenshots.fail = true;
    await quota.refresh();

    // Going blank would read as "you have kept nothing", which is the most
    // alarming thing this could say by accident.
    expect(quota.used, 41);
  });

  test('nothing is reported until the first count lands', () async {
    screenshots = _FakeScreenshotRepository(41);
    subscription = _FakeSubscriptionRepository(SubscriptionStatus.free);
    pro = ProStatus(subscription, DevAccess());
    await pro.load();
    quota = LibraryQuota(GetManagedScreenshotCountUseCase(screenshots), pro);

    // Before load(): the band renders nothing rather than a zero, so that a
    // meter never shows 0 of 100 for a frame and then jumps.
    expect(quota.used, isNull);
    expect(quota.fraction, isNull);
  });
}
