import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';

/// Moves this device's entitlement onto the account somebody just signed into.
///
/// **This is the one thing signing in buys the user**, and until this use case
/// existed nothing called it: `attachAccount` was written, documented and
/// wired all the way down to `Purchases.logIn`, and then no caller was ever
/// added. So the app asked every user for a Google account before showing them
/// anything, and gave them a name on the settings card in return.
///
/// What it fixes is one specific dead end. Google does not move a subscription
/// between Google accounts — no button, no support request — so somebody who
/// buys Pro, changes phone *and* changes their Google account has no way back:
/// "Restore purchases" asks the store about whoever is signed in now, and the
/// store has never heard of them. Keying the entitlement to a Shoto account
/// instead means it is held by something the store does not own.
class AttachSubscriptionAccountUseCase {
  final SubscriptionRepository repository;
  AttachSubscriptionAccountUseCase(this.repository);

  Future<SubscriptionStatus> call(String accountId) =>
      repository.attachAccount(accountId);
}
