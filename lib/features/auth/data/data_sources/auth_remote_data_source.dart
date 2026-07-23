import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shoto/core/constants/auth_constants.dart';
import 'package:shoto/core/utils/nonce_generator.dart';
import 'package:shoto/features/auth/data/models/user_model.dart';

class AuthRemoteDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInInitialized = false;

  AuthRemoteDataSource({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: AuthConstants.googleServerClientId,
    );
    _googleSignInInitialized = true;
  }

  Future<UserModel> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final fb.OAuthCredential credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    log(googleAuth.idToken.toString());
    final fb.UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(credential);

    return UserModel.fromFirebaseUser(userCredential.user!);
  }

  Future<UserModel> signInWithApple() async {
    final String rawNonce = NonceGenerator.generate();
    final String hashedNonce = NonceGenerator.sha256Of(rawNonce);

    final AuthorizationCredentialAppleID appleCredential =
        await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: hashedNonce,
        );

    final fb.OAuthCredential oauthCredential = fb.OAuthProvider(
      'apple.com',
    ).credential(idToken: appleCredential.identityToken, rawNonce: rawNonce);

    final fb.UserCredential userCredential = await _firebaseAuth
        .signInWithCredential(oauthCredential);
    final fb.User user = userCredential.user!;

    // Apple only shares the user's name on the very first sign-in, so we
    // persist it on the Firebase profile ourselves the first time we see it.
    final String fullName =
        '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
            .trim();
    if (fullName.isNotEmpty && user.displayName == null) {
      await user.updateDisplayName(fullName);
    }

    return UserModel.fromFirebaseUser(_firebaseAuth.currentUser ?? user);
  }

  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
      (user) => user == null ? null : UserModel.fromFirebaseUser(user),
    );
  }

  UserModel? get currentUser {
    final fb.User? user = _firebaseAuth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }
}
