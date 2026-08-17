import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/feature_trials.dart';

/// The free try each expensive-to-describe feature hands out once.
///
/// Worth checking rather than eyeballing because both ways of getting it wrong
/// are invisible and expensive: an allowance that never runs out gives the
/// paid features away, and one that is spent twice by a single use puts the
/// paywall in front of somebody who was told they had a try left.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('a try is spent once and does not come back', () async {
    final FeatureTrials trials = FeatureTrials();
    await trials.load();

    expect(trials.hasTrial(FeatureTrial.safeShare), isTrue);
    expect(trials.remaining(FeatureTrial.safeShare), 1);

    expect(await trials.consume(FeatureTrial.safeShare), isTrue);

    expect(trials.hasTrial(FeatureTrial.safeShare), isFalse);
    expect(trials.remaining(FeatureTrial.safeShare), 0);
    expect(await trials.consume(FeatureTrial.safeShare), isFalse);
  });

  test('spending one feature leaves the others alone', () async {
    final FeatureTrials trials = FeatureTrials();
    await trials.load();

    await trials.consume(FeatureTrial.safeShare);

    expect(trials.hasTrial(FeatureTrial.stitch), isTrue);
  });

  test('restarting the app is not a way to get another try', () async {
    final FeatureTrials first = FeatureTrials();
    await first.load();
    expect(await first.consume(FeatureTrial.stitch), isTrue);

    // A fresh instance over the same stored preferences.
    final FeatureTrials second = FeatureTrials();
    await second.load();

    expect(second.hasTrial(FeatureTrial.stitch), isFalse);
  });

  /// See the class doc on [FeatureTrials]: one sweep of a library is not a
  /// sample of the duplicates feature, it is the whole of it.
  test('a feature with no allowance never grants one', () async {
    final FeatureTrials trials = FeatureTrials();
    await trials.load();

    expect(trials.hasTrial(FeatureTrial.duplicates), isFalse);
    expect(trials.remaining(FeatureTrial.duplicates), 0);
    expect(await trials.consume(FeatureTrial.duplicates), isFalse);
  });
}
