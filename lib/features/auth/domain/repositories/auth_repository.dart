import 'package:shoto/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;

  /// The signed-in account, or null when nobody has signed in.
  ///
  /// Null is now an ordinary state rather than a reason to block the app:
  /// most people will use Shoto without ever signing in. Ask this when the
  /// question really is about the *account* — what name to show on the
  /// settings card, whether to offer sign-out. It is the wrong thing to ask
  /// when the question is whose data to read; see [userId].
  UserEntity? get currentUser;

  /// Whose data this is. Never null, and never changes when somebody signs
  /// in or out.
  ///
  /// Keeping these two separate is the whole point. The library belongs to
  /// the phone ([LocalIdentity]), so signing in cannot make it disappear and
  /// signing out cannot take it away — which is what would happen if data
  /// scoping followed the account, and is exactly what it used to do.
  String get userId;
}
