import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';

class SubscriptionEvent {}

class LoadOfferingsEvent extends SubscriptionEvent {}

class PurchasePackageEvent extends SubscriptionEvent {
  final SubscriptionPackageInfo package;
  PurchasePackageEvent(this.package);
}

class RestorePurchasesEvent extends SubscriptionEvent {}
