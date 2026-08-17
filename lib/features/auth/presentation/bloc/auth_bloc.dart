import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/subscription/domain/use_cases/attach_subscription_account_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/detach_subscription_account_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_apple_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SignOutUseCase signOutUseCase;

  /// What signing in is *for*. See [AttachSubscriptionAccountUseCase] — the
  /// account carries the entitlement and nothing else, so this pair is the
  /// entire functional payload of both events below.
  final AttachSubscriptionAccountUseCase attachSubscriptionAccountUseCase;
  final DetachSubscriptionAccountUseCase detachSubscriptionAccountUseCase;

  /// Repainted rather than left to the stream.
  ///
  /// RevenueCat does push an update after `logIn`, and waiting for it would
  /// mean the user lands on Home still being told they are on the free tier
  /// for however long that takes. [ProStatus.refresh] exists for exactly this
  /// — "used after a purchase or a restore, where waiting for the stream would
  /// leave the screen a beat behind the user's own action" — and signing in is
  /// the third such action.
  final ProStatus proStatus;

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.signOutUseCase,
    required this.attachSubscriptionAccountUseCase,
    required this.detachSubscriptionAccountUseCase,
    required this.proStatus,
  }) : super(AuthInitialState()) {
    on<SignInWithGoogleEvent>((event, emit) async {
      emit(AuthLoadingState(AuthMethod.google));
      try {
        final user = await signInWithGoogleUseCase();
        await _attach(user.id);
        emit(AuthSuccessState(user));
      } catch (error) {
        emit(AuthErrorState(_mapError(error)));
      }
    });

    on<SignInWithAppleEvent>((event, emit) async {
      emit(AuthLoadingState(AuthMethod.apple));
      try {
        final user = await signInWithAppleUseCase();
        await _attach(user.id);
        emit(AuthSuccessState(user));
      } catch (error) {
        emit(AuthErrorState(_mapError(error)));
      }
    });

    on<SignOutRequestedEvent>((event, emit) async {
      await signOutUseCase();
      await _detach();
      emit(AuthSignedOutState());
    });
  }

  /// Hands the entitlement to the account, and **never fails the sign-in for
  /// it**.
  ///
  /// This is the one judgement call in the change. A sign-in that reports an
  /// error because a subscription service did not answer is a sign-in that
  /// failed for a reason the user cannot act on and cannot even see the point
  /// of — they signed in, the account exists, Firebase is happy. Since this is
  /// also the gate in front of the whole app, letting it throw would mean
  /// RevenueCat being briefly unreachable locks somebody out of their own
  /// screenshots.
  ///
  /// Nothing is lost by swallowing it either, which is what makes the trade
  /// easy: the attach is idempotent and runs again on the next sign-in, and
  /// the purchase itself is held by the store the whole time.
  ///
  /// It swallows *here* rather than being lifted out of the caller's `try`,
  /// because it is called from inside the block that produces
  /// [AuthErrorState]: anything escaping this method would be reported to the
  /// user as the sign-in itself having failed.
  Future<void> _attach(String accountId) async {
    try {
      await attachSubscriptionAccountUseCase(accountId);
      await proStatus.refresh();
    } catch (error) {
      debugPrint('Shoto: could not attach subscription to account — $error');
    }
  }

  /// Leaves the device anonymous again. Same tolerance, and more important
  /// here: a sign-out that refuses to complete is a user who cannot leave.
  Future<void> _detach() async {
    try {
      await detachSubscriptionAccountUseCase();
      await proStatus.refresh();
    } catch (error) {
      debugPrint('Shoto: could not detach subscription from account — $error');
    }
  }

  /// Names the message; the widget showing it resolves it against the current
  /// locale. See [AppMessage].
  ///
  /// The two configuration cases deliberately fall through to [
  /// AppMessage.generic] rather than keeping their own sentences. Both said
  /// something only the developer can act on — Google Sign-In is misconfigured
  /// for this build — and translating "Google Sign-In isn't configured
  /// correctly for this app yet" into six languages would be six translations
  /// of a message no user can ever do anything about. The condition is still
  /// distinguishable in logs, where it belongs.
  AppMessage _mapError(Object error) {
    if (error is GoogleSignInException) {
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => AppMessage.signInCancelled,
        GoogleSignInExceptionCode.interrupted => AppMessage.signInInterrupted,
        _ => AppMessage.generic,
      };
    }

    final String message = error.toString().toLowerCase();
    if (message.contains('network')) return AppMessage.network;
    return AppMessage.generic;
  }
}
