import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_icons.dart';

/// The picker draws [FolderIcons.groups]; the app resolves a saved
/// `folders.icon_key` through [FolderIcons.byKey] and
/// [FolderIcons.brandsByKey]. Those are two lists maintained by hand, and
/// nothing in the language stops them disagreeing.
///
/// Both ways of disagreeing are silent and neither is caught by
/// `flutter analyze`:
///
/// * a key added to a map and forgotten in a group still resolves for anybody
///   who already has it, and can never be **chosen** — it simply is not on the
///   only screen that offers glyphs;
/// * a key listed in a group and missing from the maps draws the fallback
///   folder, so the picker shows a row of identical tiles that all claim to be
///   different.
void main() {
  group('folder icon groups', () {
    final Set<String> catalog = <String>{
      ...FolderIcons.byKey.keys,
      ...FolderIcons.brandsByKey.keys,
    };
    final List<String> grouped = <String>[
      for (final FolderIconGroup g in FolderIcons.groups) ...g.keys,
    ];

    test('every catalog key is offered by exactly one group', () {
      expect(grouped.toSet(), catalog);
    });

    test('no key appears in two groups', () {
      expect(grouped.length, grouped.toSet().length);
    });

    test('every grouped key resolves to a real glyph', () {
      for (final String key in grouped) {
        final bool isBrand = FolderIcons.brand(key) != null;
        // `resolve` returns the fallback for anything unknown, so an ordinary
        // key that is missing would pass a null check and fail here — which is
        // the whole point. 'folder' is the one key allowed to *be* the
        // fallback.
        final bool resolves =
            isBrand || key == 'folder' || FolderIcons.resolve(key) != FolderIcons.fallback;
        expect(resolves, isTrue, reason: '"$key" has no glyph');
      }
    });

    test('the default the editor opens on is a real key', () {
      expect(catalog, contains(FolderIcons.keys.first));
    });

    test('groups are non-empty and labelled', () {
      // A heading over nothing is a heading that reads as a bug, and an empty
      // section still costs a scroll stop.
      for (final FolderIconGroup g in FolderIcons.groups) {
        expect(g.keys, isNotEmpty);
        expect(g.label, isA<String Function(BuildContext)>());
      }
    });
  });
}
