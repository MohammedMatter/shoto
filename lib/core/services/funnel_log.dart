import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The handful of moments that say whether Shoto worked for somebody.
///
/// Deliberately short. A list of every tap produces a number for everything
/// and an answer to nothing; these are the steps where a person either
/// continues or stops, which is the only sequence worth being able to read.
enum FunnelStep {
  /// First launch ever. The denominator for everything below.
  installed,

  /// The introduction was finished rather than abandoned.
  onboardingCompleted,

  /// A screenshot entered the library, by any route — the share sheet or the
  /// picker. This is activation: before it the app is a description, after it
  /// the app is a thing the user owns.
  screenshotSaved,

  /// A folder was created. The first real sign of intent to organize rather
  /// than to hoard.
  folderCreated,

  /// Search was opened. Now free, so this finally measures whether people
  /// want it rather than whether they will pay to find out.
  searchUsed,

  /// Safe Share produced a cleaned copy. The headline feature actually
  /// completing, not merely being opened.
  safeShareCompleted,

  /// The paywall was shown. Paired with [purchased] this is the conversion
  /// rate; on its own it says how often the app asks.
  paywallSeen,

  /// A subscription was bought.
  purchased,
}

/// What happened on this device, recorded on this device, and never sent
/// anywhere.
///
/// **Why this is local-only.**
///
/// Shoto's whole claim is that nothing leaves the phone, and that claim is
/// structural rather than a policy promise — there is no server to send to.
/// Bolting on a third-party analytics SDK would make the claim false in the
/// most embarrassing way possible: the app that never uploads your
/// screenshots, quietly uploading your behaviour. So this uploads nothing.
///
/// **Why it exists anyway.**
///
/// Shipping with no instrumentation at all means every decision after launch
/// is a guess: how many people finish the introduction, how many ever save a
/// second screenshot, whether anybody opens Safe Share. Those questions have
/// answers, and the answers are already on the device — they simply were not
/// being written down. This writes them down.
///
/// What it buys today is a truthful support conversation and a real answer
/// when a tester says "I tried it and gave up": [snapshot] can be read out in
/// Settings or attached to a support mail *by the user, deliberately*. If
/// aggregate numbers are ever wanted, the events already exist and the only
/// thing left to build is an explicit, opt-in, off-by-default upload — which
/// is a decision to make in the open rather than a default to slip in.
///
/// Nothing here identifies anybody. There is no user id, no device id, no
/// screenshot content: four integers per step, and no free text ever.
class FunnelLog {
  /// Counts and timestamps only. Named so a `SharedPreferences` dump is
  /// self-explanatory to whoever is reading it over somebody's shoulder.
  static String _key(FunnelStep step, String field) =>
      'funnel_${step.name}_$field';

  final Map<String, int> _values = <String, int>{};
  bool _loaded = false;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final FunnelStep step in FunnelStep.values) {
      for (final String field in const ['first', 'last', 'count', 'days']) {
        final int? value = prefs.getInt(_key(step, field));
        if (value != null) _values[_key(step, field)] = value;
      }
    }
    _loaded = true;

    // The denominator has to be written by the app rather than inferred, or
    // "installed" would silently mean "first launch that happened to reach
    // whatever code recorded it".
    if (firstAt(FunnelStep.installed) == null) {
      await record(FunnelStep.installed);
    }
  }

  /// Notes that [step] happened, now.
  ///
  /// Safe to call on every occurrence — the first timestamp is written once
  /// and never moved, so callers do not have to know whether this is the
  /// first time. That matters: making each call site ask "is this the first
  /// save?" is how a funnel ends up measuring the caller's bookkeeping
  /// instead of the user's behaviour.
  Future<void> record(FunnelStep step) async {
    if (!_loaded) return;

    final DateTime now = DateTime.now();
    final int millis = now.millisecondsSinceEpoch;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_values[_key(step, 'first')] == null) {
      await _write(prefs, step, 'first', millis);
    }

    // Distinct *days* rather than a raw count, because the question retention
    // asks is "did they come back", and twenty saves in one sitting is one
    // answer to that, not twenty.
    final int? lastMillis = _values[_key(step, 'last')];
    final bool isNewDay =
        lastMillis == null ||
        !_sameDay(DateTime.fromMillisecondsSinceEpoch(lastMillis), now);
    if (isNewDay) {
      await _write(prefs, step, 'days', (_values[_key(step, 'days')] ?? 0) + 1);
    }

    await _write(prefs, step, 'last', millis);
    await _write(prefs, step, 'count', (_values[_key(step, 'count')] ?? 0) + 1);
  }

  DateTime? firstAt(FunnelStep step) {
    final int? millis = _values[_key(step, 'first')];
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  DateTime? lastAt(FunnelStep step) {
    final int? millis = _values[_key(step, 'last')];
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  int count(FunnelStep step) => _values[_key(step, 'count')] ?? 0;

  /// How many separate days [step] happened on.
  int daysActive(FunnelStep step) => _values[_key(step, 'days')] ?? 0;

  bool reached(FunnelStep step) => count(step) > 0;

  /// The whole funnel as plain text, for a support mail the user sends
  /// themselves.
  ///
  /// Deliberately human-readable rather than JSON: somebody should be able to
  /// look at what they are about to send and see that it is six numbers about
  /// their own usage, not a payload they have to trust.
  String snapshot() {
    final StringBuffer buffer = StringBuffer();
    for (final FunnelStep step in FunnelStep.values) {
      final DateTime? first = firstAt(step);
      buffer.writeln(
        '${step.name}: '
        '${first == null ? 'never' : first.toIso8601String().split('T').first}'
        ' · ${count(step)}x · ${daysActive(step)}d',
      );
    }
    return buffer.toString().trimRight();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _write(
    SharedPreferences prefs,
    FunnelStep step,
    String field,
    int value,
  ) async {
    _values[_key(step, field)] = value;
    await prefs.setInt(_key(step, field), value);
  }

  @visibleForTesting
  void loadFromMemory(Map<String, int> values) {
    _values
      ..clear()
      ..addAll(values);
    _loaded = true;
  }
}
