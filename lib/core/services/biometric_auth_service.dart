import 'package:local_auth/local_auth.dart';

/// Which biometrics the prompt will actually offer, collapsed to the four
/// cases the UI has anything different to say about.
///
/// [unknown] is not "none": Android often reports only a strength bucket
/// (weak/strong) instead of naming the modality, and the folder can still be
/// unlocked — we just cannot honestly call it a face or a fingerprint.
enum BiometricKind { faceAndFingerprint, face, fingerprint, unknown }

/// Thin wrapper over `local_auth` gating access to private folders. Not a
/// full clean-arch feature — a cross-cutting device capability with no
/// domain/data split needed, same precedent as [ThemeController].
class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// What the *system* will actually accept — not what the phone advertises
  /// in its own Settings app.
  ///
  /// This distinction is the whole reason this getter exists. Several Android
  /// skins (MIUI in particular) ship a "Face unlock" that only ever unlocks
  /// the lock screen: it is implemented outside the biometric framework, so
  /// it registers no face sensor and BiometricPrompt cannot offer it to us at
  /// all. On such a phone this returns fingerprint only, however loudly
  /// Settings talks about faces, and the UI has to believe this list rather
  /// than promise something the prompt will never show.
  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const <BiometricType>[];
    }
  }

  /// [BiometricType.strong] / [BiometricType.weak] are the buckets Android
  /// reports when it will not name the modality, so neither of them counts as
  /// evidence of a face — hence [BiometricKind.unknown] rather than a guess.
  Future<BiometricKind> enrolledKind() async {
    final List<BiometricType> types = await availableBiometrics();
    final bool face = types.contains(BiometricType.face);
    final bool finger = types.contains(BiometricType.fingerprint);
    if (face && finger) return BiometricKind.faceAndFingerprint;
    if (face) return BiometricKind.face;
    if (finger) return BiometricKind.fingerprint;
    return BiometricKind.unknown;
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          // Face is a *passive* biometric: you do not touch anything, so
          // Android defaults to demanding a second, explicit "Confirm" tap
          // after it recognises you. That turns a glance into a glance plus a
          // tap and makes face unlock feel broken next to the fingerprint
          // path, which opens the folder the instant it matches. Opening a
          // private folder is not a transaction — nothing is spent, nothing
          // is sent — so the confirmation step buys nothing here.
          sensitiveTransaction: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
