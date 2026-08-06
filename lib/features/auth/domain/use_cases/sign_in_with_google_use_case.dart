import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;
  SignInWithGoogleUseCase(this.repository);

  Future<UserEntity> call() => repository.signInWithGoogle();
}
