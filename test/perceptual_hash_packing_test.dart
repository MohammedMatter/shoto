import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/perceptual_hash.dart';

/// **The comparison inside an n² loop is where a scan's time goes.**
///
/// Clustering a library compares every hash with every other one, so anything
/// done per pair is paid half a million times at a thousand screenshots.
/// `hammingDistance` did sixteen `substring` allocations and sixteen
/// `int.tryParse` calls on each — measured at 445ms for a thousand and 1.5
/// seconds for two thousand, synchronous, on the thread drawing the progress
/// bar that was supposed to be reassuring somebody. Packing each hash into an
/// integer once brings the same comparisons to 11ms and 45ms.
///
/// This file exists because that is a rewrite of a correctness-critical
/// comparison for speed, and the risk of such a rewrite is not that it is
/// slow — it is that it quietly disagrees with the version it replaced. So
/// the two are checked against each other over random input, and the
/// sign-extension trap that makes them disagree has its own test.
void main() {
  group('packing a hash', () {
    test('round-trips every byte value', () {
      expect(PerceptualHash.packed('0000000000000000'), 0);
      expect(PerceptualHash.packed('00000000000000ff'), 255);
      expect(PerceptualHash.packed('0102030405060708'), 0x0102030405060708);
    });

    test('accepts a hash with the top bit set', () {
      // `int.parse` throws on this: 0xffff… exceeds 2^63-1. Accumulating byte
      // by byte wraps it to -1 instead, which is the same 64 bits and is all
      // the comparison needs.
      expect(PerceptualHash.packed('ffffffffffffffff'), -1);
      expect(PerceptualHash.packed('8000000000000000'), isNotNull);
    });

    test('refuses anything that is not sixteen hex characters', () {
      expect(PerceptualHash.packed(''), isNull);
      expect(PerceptualHash.packed('abc'), isNull);
      expect(PerceptualHash.packed('00000000000000zz'), isNull);
      expect(PerceptualHash.packed('00000000000000000'), isNull);
    });
  });

  group('distance', () {
    test('counts every differing bit, including the top one', () {
      // The sign-extension trap. An arithmetic `>>` smears the sign bit
      // through the folding and reports far more set bits than there are, so
      // two hashes differing in one high bit would look like strangers.
      expect(PerceptualHash.distanceBetween(-1, -1), 0);
      expect(PerceptualHash.distanceBetween(-1, 0), 64);
      expect(
        PerceptualHash.distanceBetween(
          PerceptualHash.packed('8000000000000000')!,
          PerceptualHash.packed('0000000000000000')!,
        ),
        1,
      );
    });

    test('is zero for a hash against itself, whatever it is', () {
      final Random random = Random(11);
      for (int i = 0; i < 200; i++) {
        final int value = random.nextInt(1 << 32) ^ (random.nextInt(1 << 32) << 32);
        expect(PerceptualHash.distanceBetween(value, value), 0);
      }
    });
  });

  test('agrees with the string comparison it replaced, on random input', () {
    final Random random = Random(3);
    String hash() => List<String>.generate(
      16,
      (_) => '0123456789abcdef'[random.nextInt(16)],
    ).join();

    for (int i = 0; i < 2000; i++) {
      final String a = hash();
      final String b = hash();
      expect(
        PerceptualHash.distanceBetween(
          PerceptualHash.packed(a)!,
          PerceptualHash.packed(b)!,
        ),
        PerceptualHash.hammingDistance(a, b),
        reason: '$a vs $b',
      );
    }
  });

  test('a malformed hash is still maximally distant, never a match', () {
    // The property the old comparison guaranteed and the new one must keep:
    // a hash that cannot be read must not be mistaken for a similar one.
    expect(PerceptualHash.hammingDistance('nonsense', '0000000000000000'), 64);
    expect(PerceptualHash.hammingDistance('0000000000000000', ''), 64);
    expect(
      PerceptualHash.hammingDistance('nonsense', 'nonsense'),
      greaterThan(PerceptualHash.duplicateThreshold),
    );
  });
}
