import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';

class SubscriptionState {}

class SubscriptionLoadingState extends SubscriptionState {}

class SubscriptionLoadedState extends SubscriptionState {
  final List<SubscriptionPackageInfo> packages;
  final SubscriptionStatus status;
  final bool isPurchasing;
  final AppMessage? errorMessage;

  SubscriptionLoadedState({
    required this.packages,
    required this.status,
    this.isPurchasing = false,
    this.errorMessage,
  });

  SubscriptionLoadedState copyWith({
    List<SubscriptionPackageInfo>? packages,
    SubscriptionStatus? status,
    bool? isPurchasing,
    AppMessage? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionLoadedState(
      packages: packages ?? this.packages,
      status: status ?? this.status,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Nothing to show yet — only used for the initial offerings load failing.
class SubscriptionErrorState extends SubscriptionState {
  final AppMessage message;
  SubscriptionErrorState(this.message);
}

/// One-shot state: the paywall listens for this to pop itself and confirm
/// success, rather than staying on this state.
class SubscriptionPurchaseSuccessState extends SubscriptionState {
  final SubscriptionStatus status;
  SubscriptionPurchaseSuccessState(this.status);
}
