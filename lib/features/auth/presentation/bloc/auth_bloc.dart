import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_apple_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SignOutUseCase signOutUseCase;

  AuthBloc({
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.signOutUseCase,
  }) : super(AuthInitialState()) {
    on<SignInWithGoogleEvent>((event, emit) async {
      emit(AuthLoadingState(AuthMethod.google));
      try {
        final user = await signInWithGoogleUseCase();
        emit(AuthSuccessState(user));
      } catch (error) {
        emit(AuthErrorState(_mapError(error)));
      }
    });

    on<SignInWithAppleEvent>((event, emit) async {
      emit(AuthLoadingState(AuthMethod.apple));
      try {
        final user = await signInWithAppleUseCase();
        emit(AuthSuccessState(user));
      } catch (error) {
        emit(AuthErrorState(_mapError(error)));
      }
    });

    on<SignOutRequestedEvent>((event, emit) async {
      await signOutUseCase();
      emit(AuthSignedOutState());
    });
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
