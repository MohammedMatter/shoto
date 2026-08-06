abstract class AuthConstants {
  AuthConstants._();

  // Firebase Console > Authentication > Sign-in method > Google > Web SDK
  // configuration > "Web client ID". Required by google_sign_in on Android
  // to return a Firebase-compatible idToken.
  static const String googleServerClientId =
      '562378341342-lo85c11t82bivjrs2i11717phebv9b11.apps.googleusercontent.com';
}
