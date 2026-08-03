import 'dart:convert';

/// Stores the labels a vision model produced as one database column.
///
/// JSON rather than a delimited string, because real labels contain spaces —
/// `Ice cream`, `Interior design`, `Mobile phone`. Any separator character
/// picked instead would eventually appear inside a label and split it in half,
/// and a label split in half matches nothing.
class VisualLabelCodec {
  static String encode(Iterable<String> labels) => jsonEncode(labels.toList());

  /// Returns an empty list for anything unreadable rather than throwing.
  ///
  /// A corrupt row should cost one screenshot a re-scan, not abort the sweep
  /// over the whole library and leave every later screenshot unindexed.
  static List<String> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final Object? parsed = jsonDecode(raw);
      if (parsed is! List) return const [];
      return [
        for (final Object? item in parsed)
          if (item is String && item.isNotEmpty) item,
      ];
    } catch (_) {
      return const [];
    }
  }
}
