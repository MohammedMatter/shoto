import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The paid features a free user is allowed to try once, and whether they
/// still have that try left.
///
/// ## Why a trial at all
///
/// Every paid feature in Shoto is one you cannot judge from a description.
/// "Covers card numbers and addresses with a solid block" is a claim; watching
/// it find the number on *your* screenshot is the product. Until now the only
/// way to cross that gap was to pay first, which asks somebody to buy a thing
/// they have never seen work.
///
/// So the expensive-to-describe features hand out one real use. Not a
/// watermarked demo and not a preview — the actual feature, on the user's own
/// screenshot, with the result theirs to keep. A trial that produces something
/// you cannot use is an advert wearing a trial's clothes.
///
/// ## Why not on everything
///
/// [FeatureTrial.duplicates] gets none, and that is a considered exception
/// rather than an oversight. Finding duplicates is valuable in proportion to
/// how much of the library it sweeps, so a single run *is* the feature —
/// somebody could clear their whole library once and never need it again. A
/// free try only makes sense where one use demonstrates the value without
/// delivering all of it.
///
/// ## Counted on success, never on the attempt
///
/// [consume] is called by the gate that lets the feature open, so a trial is
/// spent when the feature actually runs. It is deliberately **not** spent by
/// opening a page and backing out — a user who taps Safe Share, looks at it
/// and leaves has not seen anything yet, and charging them their one try for
/// that would be the worst possible first impression of a paid product.
class FeatureTrials extends ChangeNotifier {
  static const String _prefix = 'trial_used_';

  final Map<FeatureTrial, int> _used = <FeatureTrial, int>{};

  /// How many free uses of [feature] are left. Zero for a feature that never
  /// had any, and zero once the allowance is spent.
  int remaining(FeatureTrial feature) =>
      (feature.allowance - (_used[feature] ?? 0)).clamp(0, feature.allowance);

  bool hasTrial(FeatureTrial feature) => remaining(feature) > 0;

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final FeatureTrial feature in FeatureTrial.values) {
      _used[feature] = prefs.getInt('$_prefix${feature.name}') ?? 0;
    }
    notifyListeners();
  }

  /// Spends one free use and reports whether there was one to spend.
  ///
  /// Returns false when the allowance is already gone, which is the caller's
  /// signal to show the paywall instead. Writing happens after the notify so
  /// the screen never waits on a disk round trip to open.
  Future<bool> consume(FeatureTrial feature) async {
    if (!hasTrial(feature)) return false;

    _used[feature] = (_used[feature] ?? 0) + 1;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix${feature.name}', _used[feature]!);
    return true;
  }

  /// Puts every allowance back. **Debug and tester use only** — there is no
  /// path to this from the UI, because a trial you can reset is not a trial.
  @visibleForTesting
  Future<void> resetAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    for (final FeatureTrial feature in FeatureTrial.values) {
      _used[feature] = 0;
      await prefs.remove('$_prefix${feature.name}');
    }
    notifyListeners();
  }
}

/// The paid features that can be tried, and how many times.
///
/// An enum rather than a string key, so a typo is a compile error instead of a
/// feature that silently offers infinite trials. The names are persisted, so
/// **renaming a value resets that feature's allowance for everybody** — add
/// new values, never rename old ones.
enum FeatureTrial {
  /// One run of the redaction pass on a real screenshot, kept.
  safeShare(allowance: 1),

  /// One merge of a real scrolling capture, saved.
  stitch(allowance: 1),

  /// **None**, deliberately. See the class doc on [FeatureTrials]: one sweep
  /// of a library is not a sample of this feature, it is the whole of it.
  duplicates(allowance: 0);

  const FeatureTrial({required this.allowance});

  /// Free uses granted, for the lifetime of the install.
  final int allowance;
}
