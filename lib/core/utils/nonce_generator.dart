import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

abstract class NonceGenerator {
  NonceGenerator._();

  static const String _charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

  static String generate([int length = 32]) {
    final Random random = Random.secure();
    return List.generate(
      length,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  static String sha256Of(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
