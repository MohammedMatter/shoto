import 'package:shoto/core/services/local_identity.dart';
import 'package:shoto/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalIdentity _localIdentity;

  AuthRepositoryImpl(this._remoteDataSource, this._localIdentity);

  @override
  Future<UserEntity> signInWithGoogle() => _remoteDataSource.signInWithGoogle();

  @override
  Future<UserEntity> signInWithApple() => _remoteDataSource.signInWithApple();

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  Stream<UserEntity?> get authStateChanges =>
      _remoteDataSource.authStateChanges;

  @override
  UserEntity? get currentUser => _remoteDataSource.currentUser;

  /// Deliberately ignores [currentUser].
  ///
  /// Returning the Firebase uid whenever one happened to be present would
  /// reintroduce the bug this whole change exists to remove: the library
  /// would swap out from under the user at sign-in and swap back at sign-out.
  /// The device id is the answer in both cases.
  @override
  String get userId => _localIdentity.id;
}
