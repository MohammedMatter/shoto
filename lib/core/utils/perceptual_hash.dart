import 'dart:typed_data';

/// Difference-hash ("dHash") — a perceptual fingerprint of an image.
///
/// Unlike a cryptographic hash (MD5/SHA), where changing a single pixel
/// produces a completely different result, a perceptual hash stays nearly
/// identical for images that *look* the same. That's what lets us catch the
/// "I screenshotted this twice" case, where the two files differ in
/// compression or by a few pixels of scroll but are visually the same shot.
///
/// How it works: the image is squashed to a tiny 9x8 grayscale grid, then
/// each pixel is compared to its right-hand neighbour — brighter yields a 1
/// bit, darker a 0. That's 8 comparisons per row x 8 rows = 64 bits. Because
/// it only encodes *relative* brightness gradients, it's naturally immune to
/// overall brightness/contrast shifts and to re-compression.
///
/// Two hashes are then compared by [hammingDistance] — how many of those 64
/// bits differ. Identical images score 0; visually-similar ones score a
/// handful; unrelated images typically score 25+.
abstract class PerceptualHash {
  PerceptualHash._();

  /// Grid the source image must be scaled to before hashing. One column
  /// wider than tall because each row compares adjacent pixel *pairs*.
  static const int sampleWidth = 9;
  static const int sampleHeight = 8;

  /// Number of differing bits below which two images count as duplicates.
  ///
  /// Tuned conservatively: re-encodings of the same screenshot land at 0-4,
  /// genuinely different screenshots of the same app (e.g. two chats in the
  /// same messenger) usually exceed 12. Going higher starts folding those
  /// together, which is the failure mode that actually loses a user's data.
  static const int duplicateThreshold = 8;

  /// Builds a hash from raw RGBA bytes of a [sampleWidth] x [sampleHeight]
  /// image (4 bytes per pixel, row-major) — the format
  /// `ui.Image.toByteData(format: rawRgba)` returns.
  ///
  /// Returns 16 lowercase hex chars (64 bits), or null if [rgba] isn't the
  /// expected length.
  static String? fromRgba(Uint8List rgba) {
    const int expectedLength = sampleWidth * sampleHeight * 4;
    if (rgba.length < expectedLength) return null;

    // Collapse to a single luminance value per pixel first, so the bit
    // comparison below is a plain numeric one.
    final Uint8List luminance = Uint8List(sampleWidth * sampleHeight);
    for (int i = 0; i < luminance.length; i++) {
      final int offset = i * 4;
      final int r = rgba[offset];
      final int g = rgba[offset + 1];
      final int b = rgba[offset + 2];
      // Rec. 601 luma coefficients — weights each channel by how much the
      // human eye actually contributes it to perceived brightness.
      luminance[i] = ((r * 299 + g * 587 + b * 114) ~/ 1000).clamp(0, 255);
    }

    final Uint8List bits = Uint8List(8); // 64 bits packed into 8 bytes
    int bitIndex = 0;
    for (int y = 0; y < sampleHeight; y++) {
      for (int x = 0; x < sampleWidth - 1; x++) {
        final int left = luminance[y * sampleWidth + x];
        final int right = luminance[y * sampleWidth + x + 1];
        if (left > right) {
          bits[bitIndex ~/ 8] |= 1 << (7 - (bitIndex % 8));
        }
        bitIndex++;
      }
    }

    final StringBuffer hex = StringBuffer();
    for (final int byte in bits) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  /// The 64 bits of [hash] as a single integer, or null if it is malformed.
  ///
  /// **Parse once, compare many.** Clustering a library compares every hash
  /// with every other one, so anything done *inside* that loop is paid
  /// n²/2 times: at a thousand screenshots that is half a million pairs, and
  /// [hammingDistance] was spending sixteen `substring` allocations and
  /// sixteen `int.tryParse` calls on each of them. Measured, that loop cost
  /// 434ms at a thousand screenshots and 1.7 seconds at two thousand —
  /// synchronous, on the thread drawing the progress bar that was supposed to
  /// be reassuring the user.
  ///
  /// Accumulated byte by byte rather than through `int.parse`, which throws on
  /// a 16-digit hex value above 2^63-1. Dart integers are 64-bit two's
  /// complement, so the top bit simply makes the result negative — which
  /// [distanceBetween] handles, and which is invisible to `^`.
  static int? packed(String hash) {
    if (hash.length != 16) return null;

    int value = 0;
    for (int i = 0; i < 16; i += 2) {
      final int? byte = int.tryParse(hash.substring(i, i + 2), radix: 16);
      if (byte == null) return null;
      value = (value << 8) | byte;
    }
    return value;
  }

  /// How many of the 64 bits differ between two [packed] hashes.
  static int distanceBetween(int a, int b) => _popCount64(a ^ b);

  /// How many of the 64 bits differ between two hashes produced by
  /// [fromRgba]. Returns 64 (maximum distance, i.e. "not similar") if
  /// either input is malformed, so a bad hash can never be mistaken for a
  /// match.
  ///
  /// Convenience for a one-off comparison. Anything comparing in bulk should
  /// [packed] its hashes first and use [distanceBetween].
  static int hammingDistance(String a, String b) {
    final int? left = packed(a);
    final int? right = packed(b);
    if (left == null || right == null) return 64;
    return distanceBetween(left, right);
  }

  /// Set bits in a 64-bit value, by the usual SWAR folding.
  ///
  /// Unsigned shifts throughout: a hash with its top bit set is a negative
  /// Dart integer, and an arithmetic `>>` would smear the sign across every
  /// step and report far more set bits than there are.
  static int _popCount64(int value) {
    int v = value;
    v -= (v >>> 1) & 0x5555555555555555;
    v = (v & 0x3333333333333333) + ((v >>> 2) & 0x3333333333333333);
    v = (v + (v >>> 4)) & 0x0f0f0f0f0f0f0f0f;
    return ((v * 0x0101010101010101) >>> 56) & 0x7f;
  }
}
