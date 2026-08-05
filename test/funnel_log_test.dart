import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/funnel_log.dart';

/// The funnel is only worth having if its numbers mean what they say, and two
/// of them are easy to get wrong: a "first seen" that quietly moves, and a
/// retention figure that counts twenty saves in one sitting as coming back
/// twenty times.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('first launch records the denominator', () async {
    final FunnelLog log = FunnelLog();
    await log.load();

    expect(log.reached(FunnelStep.installed), isTrue);
    expect(log.count(FunnelStep.installed), 1);
    // Nothing else may be assumed to have happened.
    expect(log.reached(FunnelStep.screenshotSaved), isFalse);
    expect(log.firstAt(FunnelStep.purchased), isNull);
  });

  test('a second launch does not re-record the install', () async {
    final FunnelLog first = FunnelLog();
    await first.load();
    final DateTime? installedAt = first.firstAt(FunnelStep.installed);

    final FunnelLog second = FunnelLog();
    await second.load();

    expect(second.count(FunnelStep.installed), 1);
    expect(second.firstAt(FunnelStep.installed), installedAt);
  });

  test('firstAt never moves, however often a step repeats', () async {
    final FunnelLog log = FunnelLog();
    await log.load();

    await log.record(FunnelStep.screenshotSaved);
    final DateTime? firstSave = log.firstAt(FunnelStep.screenshotSaved);
    expect(firstSave, isNotNull);

    await log.record(FunnelStep.screenshotSaved);
    await log.record(FunnelStep.screenshotSaved);

    expect(log.firstAt(FunnelStep.screenshotSaved), firstSave);
    expect(log.count(FunnelStep.screenshotSaved), 3);
  });

  test('repeats on one day count as one active day', () async {
    final FunnelLog log = FunnelLog();
    await log.load();

    await log.record(FunnelStep.screenshotSaved);
    await log.record(FunnelStep.screenshotSaved);
    await log.record(FunnelStep.screenshotSaved);

    // Three saves, one sitting. Retention has not been demonstrated.
    expect(log.count(FunnelStep.screenshotSaved), 3);
    expect(log.daysActive(FunnelStep.screenshotSaved), 1);
  });

  test('a save on a later day is what counts as coming back', () async {
    final FunnelLog log = FunnelLog();
    // Seeded directly: the alternative is waiting until tomorrow.
    final DateTime yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );
    log.loadFromMemory(<String, int>{
      'funnel_screenshotSaved_first': yesterday.millisecondsSinceEpoch,
      'funnel_screenshotSaved_last': yesterday.millisecondsSinceEpoch,
      'funnel_screenshotSaved_count': 1,
      'funnel_screenshotSaved_days': 1,
    });

    await log.record(FunnelStep.screenshotSaved);

    expect(log.count(FunnelStep.screenshotSaved), 2);
    expect(log.daysActive(FunnelStep.screenshotSaved), 2);
    // The first save still points at yesterday.
    expect(log.firstAt(FunnelStep.screenshotSaved)!.day, yesterday.day);
  });

  test('the snapshot names every step and invents no data', () async {
    final FunnelLog log = FunnelLog();
    await log.load();
    await log.record(FunnelStep.searchUsed);

    final String snapshot = log.snapshot();
    for (final FunnelStep step in FunnelStep.values) {
      expect(snapshot, contains(step.name));
    }
    expect(snapshot, contains('searchUsed'));
    // Steps that never happened must say so rather than showing a zero date.
    expect(snapshot, contains('purchased: never'));
  });

  test('recording before load is a no-op rather than a crash', () async {
    // The share sheet reaches for this early; it must never be the reason a
    // save fails.
    final FunnelLog log = FunnelLog();
    await log.record(FunnelStep.screenshotSaved);
    expect(log.count(FunnelStep.screenshotSaved), 0);
  });
}
