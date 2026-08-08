import 'dart:math';

/// A random string, for the one id Shoto mints: the device's own.
///
/// This was `NonceGenerator`, and it had a second method that hashed a nonce
/// with SHA-256 for Sign in with Apple. Apple is gone along with the rest of
/// signing in, and with it the only reason this file depended on `crypto`.
abstract class RandomId {
  RandomId._();

  static const String _charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

  static String generate([int length = 32]) {
    final Random random = Random.secure();
    return List.generate(
      length,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }
}
