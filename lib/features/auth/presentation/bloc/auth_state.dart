import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';

enum AuthMethod { google, apple }

/// Sealed — see `docs/decisions/screen-states.md`.
sealed class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {
  final AuthMethod method;
  AuthLoadingState(this.method);
}

class AuthSuccessState extends AuthState {
  final UserEntity user;
  AuthSuccessState(this.user);
}

class AuthErrorState extends AuthState {
  final AppMessage message;
  AuthErrorState(this.message);
}

class AuthSignedOutState extends AuthState {}
