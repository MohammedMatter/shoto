import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/feature_trials.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// Brings up everything [ensurePremium] reads, for a process that skipped it.
///
/// ## Why this exists
///
/// `main` has two entry paths and they load deliberately different amounts.
/// The full app resolves the subscription stack before its first frame, so
/// every gate in it can be asked synchronously-ish and no badge arrives late.
/// The **share sheet does not** — it is launched mid-gesture from inside
/// another app, and its whole justification is appearing before the user has
/// finished letting go. Its fast path in `main` loads five things and lists
/// the subscription repository among what it deliberately skips, on the
/// grounds that quick save is free.
///
/// That was true right up until the sheet learned to offer covering. Safe
/// Share is paid, so the gate now runs on a path where nothing it reads has
/// been initialized: [SubscriptionRepository.getStatus] on an unconfigured
/// store, [FeatureTrials.remaining] against an empty map — which does not fail
/// loudly, it fails as *a subscriber being shown a paywall* and *a spent trial
/// reading as unspent*.
///
/// ## Why not just load it in `main` after all
///
/// Because the great majority of shares never touch a paid feature. Filing is
/// free and is what most people came to do, and paying the store round trip on
/// every single share — in front of the one screen in this app where latency
/// is least affordable — to serve the shares that go the other way is the
/// wrong trade. This is awaited at the moment the user taps the paid thing,
/// where a beat of work is expected and invisible.
///
/// ## Idempotent on purpose
///
/// Backing out of Safe Share and tapping it again must not re-initialize the
/// store, and the sheet has no lifecycle long enough to own this state itself.
/// The future is kept rather than a bool, so two taps racing each other wait
/// on the same work instead of starting it twice.
Future<void> ensurePremiumServicesReady() =>
    _ready ??= _load();

Future<void>? _ready;

Future<void> _load() async {
  // DevAccess first, and that ordering is the same constraint `main`
  // documents: the repository consults it when deciding what to report, so a
  // status resolved before it is loaded is a status that has not heard about
  // the tester switch.
  await sl<DevAccess>().load();

  // No-ops rather than throwing when no store is configured — see
  // RevenueCatDataSource — so this is safe on a build without RevenueCat.
  await sl<SubscriptionRepository>().initialize();

  // Read by the gate to decide whether there is a free try left. Loaded after
  // the store for no reason other than that a subscriber never reaches it.
  await sl<FeatureTrials>().load();
}

/// Lets a test start from a process that has loaded nothing.
///
/// The memo above is a top-level variable, so without this the second test in
/// a file would observe the first one's initialization and pass for a reason
/// that has nothing to do with what it asserts.
void resetPremiumServicesForTest() => _ready = null;
