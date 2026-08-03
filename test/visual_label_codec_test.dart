import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/visual_label_codec.dart';

void main() {
  test('round-trips labels containing spaces', () {
    // The reason this is JSON and not a delimited string.
    const List<String> labels = ['Ice cream', 'Interior design', 'Cat'];
    expect(VisualLabelCodec.decode(VisualLabelCodec.encode(labels)), labels);
  });

  test('an empty list survives as an empty list', () {
    // Distinct from null: "looked, saw nothing" must not be re-scanned as
    // "never looked".
    final String encoded = VisualLabelCodec.encode(const []);
    expect(encoded, isNot(isEmpty));
    expect(VisualLabelCodec.decode(encoded), isEmpty);
  });

  test('null and empty input read as no labels', () {
    expect(VisualLabelCodec.decode(null), isEmpty);
    expect(VisualLabelCodec.decode(''), isEmpty);
  });

  test('a corrupt row costs one re-scan, not an exception', () {
    for (final String junk in ['{', 'not json', '{"a":1}', '"Cat"', '42']) {
      expect(VisualLabelCodec.decode(junk), isEmpty, reason: junk);
    }
  });

  test('non-string and empty entries are dropped, the rest kept', () {
    expect(VisualLabelCodec.decode('["Cat", 7, null, "", "Dog"]'), [
      'Cat',
      'Dog',
    ]);
  });
}
