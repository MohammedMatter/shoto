import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// Returns this device to an anonymous entitlement when somebody signs out.
///
/// **The half that is easy to forget, and the half that leaks.** Attaching
/// without detaching leaves the previous account's entitlement sitting on the
/// device, so the next person to sign in on the same phone inherits somebody
/// else's Pro.
///
/// Nothing is cancelled and nothing local is touched: the entitlement stays
/// with the account on RevenueCat's side and signing back in anywhere brings
/// it back, and the library was never keyed to the account in the first place
/// — it belongs to the phone. Signing out of Shoto is not meant to take
/// anything away.
class DetachSubscriptionAccountUseCase {
  final SubscriptionRepository repository;
  DetachSubscriptionAccountUseCase(this.repository);

  Future<SubscriptionStatus> call() => repository.detachAccount();
}
