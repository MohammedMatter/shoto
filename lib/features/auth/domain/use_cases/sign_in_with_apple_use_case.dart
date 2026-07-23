import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository repository;
  SignInWithAppleUseCase(this.repository);

  Future<UserEntity> call() => repository.signInWithApple();
}
