import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';

/// A detection together with the characters of the OCR text it came out of.
///
/// The span is not decoration. Every extractor in this feature runs over the
/// same string and each must skip what an earlier one already claimed — an
/// event's "12/05/2026" is also eight digits the phone rule would happily take,
/// and a Wi-Fi password is also four to eight digits with the word "password"
/// beside it, which is the exact definition of a verification code.
///
/// The five entity extractors do this bookkeeping inline in
/// [ActionExtractor] because they were written as regexes with no state. The
/// intent extractors parse rather than match, so they hand their spans back
/// instead.
class Extraction {
  final DetectedAction action;

  /// Offsets into the digit-normalised text handed to the extractor.
  final int start;
  final int end;

  const Extraction(this.action, this.start, this.end);
}
