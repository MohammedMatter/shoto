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

  String _mapError(Object error) {
    if (error is GoogleSignInException) {
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          return 'Sign-in was cancelled.';
        case GoogleSignInExceptionCode.clientConfigurationError:
          return 'Google Sign-In isn\'t configured correctly for this app yet.';
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Google Sign-In isn\'t available on this device right now.';
        case GoogleSignInExceptionCode.interrupted:
          return 'Sign-in was interrupted. Please try again.';
        default:
          return 'Google sign-in failed: ${error.description ?? error.code}';
      }
    }

    final String message = error.toString().toLowerCase();
    if (message.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
