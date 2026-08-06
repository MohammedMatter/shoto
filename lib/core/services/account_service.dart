import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/firebase_options.dart';

/// An optional account, and the word doing the work is *optional*.
///
/// **What it is for, and the only thing it is for: carrying a subscription.**
///
/// A Play or App Store purchase belongs to the store account that paid for it,
/// and Google does not let a subscription move between Google accounts — there
/// is no button, no setting, and no support request that does it. So somebody
/// who buys Pro, changes phone *and* changes their Google account has no way
/// back: "Restore purchases" asks the store about the account currently signed
/// in, and gets nothing.
///
/// An account fixes exactly that, because the entitlement then lives against
/// an id **we** own rather than against the store's. It does not move the
/// billing — that stays on the old Google account until it lapses — and it
/// does not sync the library, which is device-local sqlite and would need a
/// server this app deliberately does not have.
///
/// ---
///
/// **It is never a wall.** SHOTO had a mandatory sign-in on its first screen
/// once, and it cost every new user an identity handoff to see an empty
/// library. See `docs/decisions/accounts.md`. This is offered in exactly two
/// places: right after a purchase, and when a restore comes back empty. Both
/// are moments where an account has just become worth something.
///
/// **Firebase is loaded on demand.** `Firebase.initializeApp` used to run at
/// startup and was the single slowest step in launching the app, for an SDK
/// most sessions never touched. Here it runs the first time somebody actually
/// opens the account sheet, so a user who never makes an account never pays
/// for one. Every method below calls [_ready] first; nothing else in the app
/// may assume Firebase exists.
class AccountService extends ChangeNotifier {
  Future<void>? _initializing;
  fb.FirebaseAuth? _auth;

  /// Initializes Firebase once, and only when something needs it.
  ///
  /// The future is held rather than a boolean flag so two taps in quick
  /// succession await the same initialization instead of starting a second
  /// one — `initializeApp` throws if it runs twice concurrently.
  Future<fb.FirebaseAuth> _ready() async {
    _initializing ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _initializing;
    return _auth ??= fb.FirebaseAuth.instance;
  }

  /// Whether an account is attached, without touching Firebase.
  ///
  /// Cached locally so anything that paints — the settings row — can ask
  /// synchronously during a build. It is a display detail, never a gate:
  /// whether the user is *entitled* is [ProStatus]'s question, and it is
  /// answered by RevenueCat rather than by this.
  String? _email;
  String? get email => _email;
  bool get isSignedIn => _email != null;

  /// Picks up a session Firebase restored from disk, if there is one.
  ///
  /// Only worth calling once something else has already paid for
  /// initialization; on a cold start nothing does, which is the point.
  Future<void> refresh() async {
    if (_initializing == null) return;
    final fb.FirebaseAuth auth = await _ready();
    _setEmail(auth.currentUser?.email);
  }

  /// Signs in, creating the account if this email has never been seen.
  ///
  /// One method rather than two screens, because "sign in" and "sign up" is a
  /// distinction the user should not have to make about their own email
  /// address: they know whether they have an account here about as well as
  /// they remember which of five services they used last year.
  ///
  /// Returns null on success, or a message to show.
  Future<AppMessage?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final fb.FirebaseAuth auth = await _ready();
      try {
        await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      } on fb.FirebaseAuthException catch (error) {
        // `user-not-found` is what a first-time account looks like, and
        // `invalid-credential` is what recent Firebase returns instead when
        // email enumeration protection is on — it cannot tell the caller
        // whether the address or the password was wrong, on purpose. Trying
        // to create is how we find out: if the address is taken, creation
        // fails with `email-already-in-use`, which means the password was
        // wrong and nothing has been created.
        if (error.code != 'user-not-found' &&
            error.code != 'invalid-credential') {
          rethrow;
        }
        await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      }

      _setEmail(auth.currentUser?.email);
      return null;
    } on fb.FirebaseAuthException catch (error) {
      return _messageFor(error.code);
    } catch (error) {
      debugPrint('SHOTO account sign-in failed: $error');
      return AppMessage.accountFailed;
    }
  }

  Future<AppMessage?> sendPasswordReset(String email) async {
    try {
      final fb.FirebaseAuth auth = await _ready();
      await auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on fb.FirebaseAuthException catch (error) {
      return _messageFor(error.code);
    } catch (error) {
      debugPrint('SHOTO password reset failed: $error');
      return AppMessage.accountFailed;
    }
  }

  Future<void> signOut() async {
    if (_initializing != null) {
      final fb.FirebaseAuth auth = await _ready();
      await auth.signOut();
    }
    _setEmail(null);
  }

  /// The signed-in user's id, for RevenueCat to alias the entitlement to.
  Future<String?> currentUserId() async {
    if (_initializing == null) return null;
    final fb.FirebaseAuth auth = await _ready();
    return auth.currentUser?.uid;
  }

  void _setEmail(String? value) {
    if (_email == value) return;
    _email = value;
    notifyListeners();
  }

  /// Firebase's codes, turned into sentences the app already speaks.
  ///
  /// Deliberately not `error.message`: those are English, written for
  /// developers, and this app ships in six languages.
  static AppMessage _messageFor(String code) => switch (code) {
    'invalid-email' => AppMessage.accountBadEmail,
    'weak-password' => AppMessage.accountWeakPassword,
    'email-already-in-use' ||
    'wrong-password' ||
    'invalid-credential' => AppMessage.accountWrongPassword,
    'too-many-requests' => AppMessage.accountTooMany,
    'network-request-failed' => AppMessage.accountOffline,
    _ => AppMessage.accountFailed,
  };
}
