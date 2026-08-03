import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_offerings_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/get_subscription_status_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/purchase_package_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/restore_purchases_use_case.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:shoto/features/subscription/presentation/bloc/subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetOfferingsUseCase getOfferingsUseCase;
  final GetSubscriptionStatusUseCase getSubscriptionStatusUseCase;
  final PurchasePackageUseCase purchasePackageUseCase;
  final RestorePurchasesUseCase restorePurchasesUseCase;

  SubscriptionBloc({
    required this.getOfferingsUseCase,
    required this.getSubscriptionStatusUseCase,
    required this.purchasePackageUseCase,
    required this.restorePurchasesUseCase,
  }) : super(SubscriptionLoadingState()) {
    on<LoadOfferingsEvent>(_onLoad);
    on<PurchasePackageEvent>(_onPurchase);
    on<RestorePurchasesEvent>(_onRestore);
  }

  Future<void> _onLoad(
    LoadOfferingsEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoadingState());
    try {
      final List<SubscriptionPackageInfo> packages =
          await getOfferingsUseCase();
      final SubscriptionStatus status = await getSubscriptionStatusUseCase();
      emit(SubscriptionLoadedState(packages: packages, status: status));
    } catch (error) {
      emit(SubscriptionErrorState(AppMessage.plans));
    }
  }

  Future<void> _onPurchase(
    PurchasePackageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final SubscriptionState current = state;
    if (current is! SubscriptionLoadedState) return;
    emit(current.copyWith(isPurchasing: true, clearError: true));
    try {
      final SubscriptionStatus status = await purchasePackageUseCase(
        event.package,
      );
      emit(SubscriptionPurchaseSuccessState(status));
    } on PlatformException catch (error) {
      final PurchasesErrorCode code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        emit(current.copyWith(isPurchasing: false));
      } else {
        emit(
          current.copyWith(
            isPurchasing: false,
            errorMessage: AppMessage.purchase,
          ),
        );
      }
    } catch (error) {
      emit(
        current.copyWith(
          isPurchasing: false,
          errorMessage: AppMessage.purchase,
        ),
      );
    }
  }

  Future<void> _onRestore(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final SubscriptionState current = state;
    if (current is! SubscriptionLoadedState) return;
    emit(current.copyWith(isPurchasing: true, clearError: true));
    try {
      final SubscriptionStatus status = await restorePurchasesUseCase();
      if (status.isPremium) {
        emit(SubscriptionPurchaseSuccessState(status));
      } else {
        emit(
          current.copyWith(
            isPurchasing: false,
            status: status,
            errorMessage: AppMessage.noSubscription,
          ),
        );
      }
    } catch (error) {
      emit(
        current.copyWith(isPurchasing: false, errorMessage: AppMessage.restore),
      );
    }
  }
}
