import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/backup_manifest.dart';

BackupFolder _folder(String name, {int color = 0xFF112233}) => BackupFolder(
  name: name,
  color: color,
  isPrivate: false,
  createdAt: DateTime.utc(2026, 3, 4),
);

BackupItem _item(String path, {int? folder, bool fav = false}) => BackupItem(
  path: path,
  folderIndex: folder,
  isFavorite: fav,
  ocrText: null,
  phash: null,
  visualLabels: const <String>[],
  addedAt: DateTime.utc(2026, 5, 6),
);

void main() {
  group('round trip', () {
    test('everything survives encode and decode', () {
      final BackupManifest source = BackupManifest.now(
        folders: <BackupFolder>[
          BackupFolder(
            name: 'وصفات',
            color: 0xFF3355FF,
            isPrivate: true,
            createdAt: DateTime.utc(2026, 1, 2, 3, 4),
          ),
        ],
        items: <BackupItem>[
          BackupItem(
            path: 'images/00001.png',
            folderIndex: 0,
            isFavorite: true,
            ocrText: 'رمز التحقق 481920',
            phash: 'a1b2c3d4e5f60718',
            visualLabels: const <String>['Cat', 'Ice cream'],
            addedAt: DateTime.utc(2026, 2, 3, 4, 5),
          ),
        ],
      );

      final BackupParseResult result = BackupManifest.decode(source.encode());
      expect(result.isComplete, isTrue);

      final BackupFolder folder = result.manifest.folders.single;
      expect(folder.name, 'وصفات');
      expect(folder.color, 0xFF3355FF);
      expect(folder.isPrivate, isTrue);
      expect(folder.createdAt, DateTime.utc(2026, 1, 2, 3, 4));

      final BackupItem item = result.manifest.items.single;
      expect(item.path, 'images/00001.png');
      expect(item.folderIndex, 0);
      expect(item.isFavorite, isTrue);
      expect(item.ocrText, 'رمز التحقق 481920');
      expect(item.phash, 'a1b2c3d4e5f60718');
      expect(item.visualLabels, <String>['Cat', 'Ice cream']);
      expect(item.addedAt, DateTime.utc(2026, 2, 3, 4, 5));
    });

    test('an empty library round trips', () {
      final BackupParseResult result = BackupManifest.decode(
        BackupManifest.now(
          folders: const <BackupFolder>[],
          items: const <BackupItem>[],
        ).encode(),
      );
      expect(result.manifest.folders, isEmpty);
      expect(result.manifest.items, isEmpty);
      expect(result.isComplete, isTrue);
    });

    test('labels containing spaces survive, since they genuinely do', () {
      final BackupItem item = BackupManifest.decode(
        BackupManifest.now(
          folders: const <BackupFolder>[],
          items: <BackupItem>[
            BackupItem(
              path: 'images/1.png',
              folderIndex: null,
              isFavorite: false,
              ocrText: null,
              phash: null,
              visualLabels: const <String>['Interior design', 'Ice cream'],
              addedAt: DateTime.utc(2026),
            ),
          ],
        ).encode(),
      ).manifest.items.single;
      expect(item.visualLabels, <String>['Interior design', 'Ice cream']);
    });
  });

  group('files this build must refuse outright', () {
    test('not JSON at all', () {
      expect(
        () => BackupManifest.decode('this is a photo, not a manifest'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('valid JSON that is not ours', () {
      expect(
        () => BackupManifest.decode('{"kind":"someoneelse.backup"}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a JSON array rather than an object', () {
      expect(
        () => BackupManifest.decode('[]'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('no version', () {
      expect(
        () => BackupManifest.decode('{"kind":"shoto.backup"}'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a version this build does not understand', () {
      // Refusing beats a best-effort read: a newer manifest may carry a field
      // whose absence changes meaning, and half-restoring a backup is how one
      // quietly loses the other half.
      final String future = jsonEncode(<String, Object?>{
        'kind': BackupManifest.kind,
        'version': BackupManifest.currentVersion + 1,
        'items': <Object?>[],
      });
      expect(
        () => BackupManifest.decode(future),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('damage is survived, counted, and never silent', () {
    String raw({List<Object?>? folders, List<Object?>? items}) =>
        jsonEncode(<String, Object?>{
          'kind': BackupManifest.kind,
          'version': BackupManifest.currentVersion,
          'created': 1770000000000,
          'folders': folders ?? <Object?>[],
          'items': items ?? <Object?>[],
        });

    test('an item with no path is skipped and reported', () {
      final BackupParseResult result = BackupManifest.decode(
        raw(
          items: <Object?>[
            <String, Object?>{'fav': true},
            _item('images/2.png').toJson(),
          ],
        ),
      );
      expect(result.manifest.items, hasLength(1));
      expect(result.skippedItems, 1);
      expect(result.isComplete, isFalse);
    });

    test('a nameless folder is skipped and reported', () {
      final BackupParseResult result = BackupManifest.decode(
        raw(
          folders: <Object?>[
            <String, Object?>{'color': 1},
            _folder('Receipts').toJson(),
          ],
        ),
      );
      expect(result.manifest.folders, hasLength(1));
      expect(result.skippedFolders, 1);
    });

    test('entries of the wrong type are skipped, not fatal', () {
      final BackupParseResult result = BackupManifest.decode(
        raw(folders: <Object?>['nonsense', 7], items: <Object?>[null, 'x']),
      );
      expect(result.manifest.folders, isEmpty);
      expect(result.manifest.items, isEmpty);
      expect(result.skippedFolders, 2);
      expect(result.skippedItems, 2);
    });

    test('a folder missing only its colour is kept', () {
      // Losing a colour is cosmetic. Dropping the folder would take every
      // screenshot filed in it down to unfiled with it.
      final BackupParseResult result = BackupManifest.decode(
        raw(
          folders: <Object?>[
            <String, Object?>{'name': 'Work', 'created': 1770000000000},
          ],
        ),
      );
      expect(result.manifest.folders.single.name, 'Work');
      expect(result.skippedFolders, 0);
    });
  });

  group('folder references', () {
    String rawWith(List<Object?> folders, List<Object?> items) =>
        jsonEncode(<String, Object?>{
          'kind': BackupManifest.kind,
          'version': BackupManifest.currentVersion,
          'folders': folders,
          'items': items,
        });

    test('an out-of-range index unfiles rather than misfiles', () {
      final BackupParseResult result = BackupManifest.decode(
        rawWith(
          <Object?>[_folder('Only one').toJson()],
          <Object?>[_item('images/1.png', folder: 5).toJson()],
        ),
      );
      expect(result.manifest.items.single.folderIndex, isNull);
    });

    test('a negative index unfiles too', () {
      final BackupParseResult result = BackupManifest.decode(
        rawWith(
          <Object?>[_folder('Only one').toJson()],
          <Object?>[_item('images/1.png', folder: -1).toJson()],
        ),
      );
      expect(result.manifest.items.single.folderIndex, isNull);
    });

    test('the screenshot itself is never lost to a bad reference', () {
      final BackupParseResult result = BackupManifest.decode(
        rawWith(<Object?>[], <Object?>[
          _item('images/1.png', folder: 0).toJson(),
        ]),
      );
      expect(result.manifest.items, hasLength(1));
      expect(result.skippedItems, 0);
    });

    test('valid indices are preserved exactly', () {
      final BackupParseResult result = BackupManifest.decode(
        rawWith(
          <Object?>[_folder('A').toJson(), _folder('B').toJson()],
          <Object?>[
            _item('images/1.png', folder: 0).toJson(),
            _item('images/2.png', folder: 1).toJson(),
            _item('images/3.png').toJson(),
          ],
        ),
      );
      expect(result.manifest.items.map((BackupItem i) => i.folderIndex), <int?>[
        0,
        1,
        null,
      ]);
    });
  });

  group('nothing device-specific leaks into the file', () {
    // The whole reason this format exists. An asset id is a MediaStore id and
    // a folder id comes from an AUTOINCREMENT sequence; either one written
    // into a backup restores a library pointing at things that do not exist.
    test('the encoded JSON carries no id fields', () {
      final String encoded = BackupManifest.now(
        folders: <BackupFolder>[_folder('Work')],
        items: <BackupItem>[_item('images/1.png', folder: 0, fav: true)],
      ).encode();

      final Map<String, Object?> root =
          jsonDecode(encoded) as Map<String, Object?>;
      final Map<String, Object?> folder =
          (root['folders'] as List).single as Map<String, Object?>;
      final Map<String, Object?> item =
          (root['items'] as List).single as Map<String, Object?>;

      expect(folder.keys, isNot(contains('id')));
      expect(item.keys, isNot(contains('id')));
      expect(item.keys, isNot(contains('asset_id')));
      expect(item.keys, isNot(contains('assetId')));
      expect(item.keys, isNot(contains('folder_id')));
      expect(encoded, isNot(contains('user_id')));
    });

    test('items address folders positionally', () {
      final Map<String, Object?> root =
          jsonDecode(
                BackupManifest.now(
                  folders: <BackupFolder>[_folder('A'), _folder('B')],
                  items: <BackupItem>[_item('images/1.png', folder: 1)],
                ).encode(),
              )
              as Map<String, Object?>;
      final Map<String, Object?> item =
          (root['items'] as List).single as Map<String, Object?>;
      expect(item['folder'], 1);
    });
  });

  test('optional fields are omitted rather than written as null', () {
    // Keeps a large library's manifest small: most screenshots are unfiled,
    // unstarred and unlabelled, and writing five nulls each adds up.
    final String encoded = BackupManifest.now(
      folders: const <BackupFolder>[],
      items: <BackupItem>[_item('images/1.png')],
    ).encode();
    final Map<String, Object?> item =
        ((jsonDecode(encoded) as Map<String, Object?>)['items'] as List).single
            as Map<String, Object?>;
    expect(item.keys, unorderedEquals(<String>['path', 'added']));
  });
}
