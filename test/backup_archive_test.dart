import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shoto/core/utils/backup_archive.dart';
import 'package:shoto/core/utils/backup_manifest.dart';

Uint8List _bytes(String marker) => Uint8List.fromList(utf8.encode(marker));

BackupFolder _folder(String name) => BackupFolder(
  name: name,
  color: 0xFF3355FF,
  isPrivate: false,
  createdAt: DateTime.utc(2026, 1, 1),
);

BackupSource _source(
  String marker, {
  String name = 'shot.png',
  int? folder,
  bool fav = false,
  String? text,
  List<String> labels = const <String>[],
}) => BackupSource(
  bytes: _bytes(marker),
  originalName: name,
  folderIndex: folder,
  isFavorite: fav,
  ocrText: text,
  phash: null,
  visualLabels: labels,
  addedAt: DateTime.utc(2026, 2, 2),
);

void main() {
  group('round trip through a real zip', () {
    test('images and their filing both come back', () {
      final Uint8List archive = BackupArchive.write(
        folders: <BackupFolder>[_folder('Receipts'), _folder('وصفات')],
        sources: <BackupSource>[
          _source('first', folder: 0, fav: true, text: 'رمز التحقق 481920'),
          _source('second', folder: 1, labels: <String>['Ice cream']),
          _source('third'),
        ],
      );

      final BackupContents contents = BackupArchive.read(archive);
      expect(contents.isComplete, isTrue);
      expect(contents.manifest.folders.map((BackupFolder f) => f.name), <
        String
      >['Receipts', 'وصفات']);
      expect(contents.entries, hasLength(3));

      expect(utf8.decode(contents.entries[0].bytes), 'first');
      expect(contents.entries[0].item.folderIndex, 0);
      expect(contents.entries[0].item.isFavorite, isTrue);
      expect(contents.entries[0].item.ocrText, 'رمز التحقق 481920');

      expect(utf8.decode(contents.entries[1].bytes), 'second');
      expect(contents.entries[1].item.visualLabels, <String>['Ice cream']);

      expect(utf8.decode(contents.entries[2].bytes), 'third');
      expect(contents.entries[2].item.folderIndex, isNull);
    });

    test('an empty library produces a readable archive', () {
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: const <BackupFolder>[],
          sources: const <BackupSource>[],
        ),
      );
      expect(contents.entries, isEmpty);
      expect(contents.manifest.folders, isEmpty);
      expect(contents.isComplete, isTrue);
    });

    test('image bytes are returned exactly, not re-encoded', () {
      // Backup must be lossless. Every byte value appears here so a stray
      // text conversion anywhere in the pipeline shows up as a mismatch.
      final Uint8List original = Uint8List.fromList(
        List<int>.generate(256, (int i) => i),
      );
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: const <BackupFolder>[],
          sources: <BackupSource>[
            BackupSource(
              bytes: original,
              originalName: 'a.png',
              folderIndex: null,
              isFavorite: false,
              ocrText: null,
              phash: null,
              visualLabels: const <String>[],
              addedAt: DateTime.utc(2026),
            ),
          ],
        ),
      );
      expect(contents.entries.single.bytes, orderedEquals(original));
    });
  });

  group('entry naming', () {
    test('every screenshot gets its own entry', () {
      // Two screenshots sharing a name inside the archive would mean one
      // overwriting the other — silent data loss in a backup feature.
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: const <BackupFolder>[],
          sources: <BackupSource>[
            _source('a', name: 'same.png'),
            _source('b', name: 'same.png'),
            _source('c', name: 'same.png'),
          ],
        ),
      );
      final Set<String> paths = contents.entries
          .map((BackupEntry e) => e.item.path)
          .toSet();
      expect(paths, hasLength(3));
      expect(
        contents.entries.map((BackupEntry e) => utf8.decode(e.bytes)),
        <String>['a', 'b', 'c'],
      );
    });

    test('the original extension is kept', () {
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: const <BackupFolder>[],
          sources: <BackupSource>[
            _source('j', name: 'photo.JPG'),
            _source('w', name: 'shot.webp'),
          ],
        ),
      );
      expect(contents.entries[0].item.path, endsWith('.jpg'));
      expect(contents.entries[1].item.path, endsWith('.webp'));
    });

    test('a nameless or odd source still gets a usable extension', () {
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: const <BackupFolder>[],
          sources: <BackupSource>[
            _source('a', name: 'noextension'),
            _source('b', name: 'trailing.'),
            _source('c', name: '.hidden'),
          ],
        ),
      );
      for (final BackupEntry entry in contents.entries) {
        expect(entry.item.path, endsWith('.png'));
      }
    });

    test('a folder index the folder list cannot resolve is not written', () {
      final BackupContents contents = BackupArchive.read(
        BackupArchive.write(
          folders: <BackupFolder>[_folder('Only one')],
          sources: <BackupSource>[
            _source('a', folder: 4),
            _source('b', folder: -1),
          ],
        ),
      );
      expect(contents.entries[0].item.folderIndex, isNull);
      expect(contents.entries[1].item.folderIndex, isNull);
    });
  });

  group('archives this build must refuse', () {
    test('bytes that are not a zip', () {
      expect(
        () => BackupArchive.read(_bytes('definitely not a zip file')),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a zip with no manifest', () {
      final Archive archive = Archive()
        ..add(ArchiveFile.string('images/1.png', 'x'));
      expect(
        () => BackupArchive.read(ZipEncoder().encodeBytes(archive)),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a zip whose manifest is someone else s', () {
      final Archive archive = Archive()
        ..add(
          ArchiveFile.string(BackupManifest.fileName, '{"kind":"other"}'),
        );
      expect(
        () => BackupArchive.read(ZipEncoder().encodeBytes(archive)),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('a truncated archive restores what survives', () {
    /// Rebuilds an archive with some image entries dropped, which is what a
    /// half-copied or partly-corrupted file looks like.
    Uint8List withoutImages(Uint8List source, Set<String> drop) {
      final Archive original = ZipDecoder().decodeBytes(source);
      final Archive rebuilt = Archive();
      for (final ArchiveFile file in original.files) {
        if (drop.any((String d) => file.name.endsWith(d))) continue;
        rebuilt.add(ArchiveFile.bytes(file.name, file.readBytes()!));
      }
      return ZipEncoder().encodeBytes(rebuilt);
    }

    test('a missing image is counted, and the rest still come back', () {
      final Uint8List full = BackupArchive.write(
        folders: <BackupFolder>[_folder('Work')],
        sources: <BackupSource>[
          _source('a', folder: 0),
          _source('b'),
          _source('c', folder: 0),
        ],
      );

      final BackupContents contents = BackupArchive.read(
        withoutImages(full, <String>{'00002.png'}),
      );

      expect(contents.entries, hasLength(2));
      expect(contents.missingImages, 1);
      expect(contents.isComplete, isFalse);
      expect(
        contents.entries.map((BackupEntry e) => utf8.decode(e.bytes)),
        <String>['a', 'c'],
      );
      // The folder survives even though a screenshot inside it did not.
      expect(contents.manifest.folders.single.name, 'Work');
    });
  });

  group('entries written by other tools are still found', () {
    // A user may well unzip a backup, look inside, and zip it back up with
    // whatever their machine ships. Those tools write separators and prefixes
    // differently, and losing every image over a leading "./" would be a
    // miserable way to discover the format is brittle.
    Uint8List rewritten(Uint8List source, String Function(String) rename) {
      final Archive original = ZipDecoder().decodeBytes(source);
      final Archive rebuilt = Archive();
      for (final ArchiveFile file in original.files) {
        rebuilt.add(ArchiveFile.bytes(rename(file.name), file.readBytes()!));
      }
      return ZipEncoder().encodeBytes(rebuilt);
    }

    final Uint8List full = BackupArchive.write(
      folders: const <BackupFolder>[],
      sources: <BackupSource>[_source('a'), _source('b')],
    );

    test('a leading ./ on every entry', () {
      final BackupContents contents = BackupArchive.read(
        rewritten(full, (String n) => './$n'),
      );
      expect(contents.entries, hasLength(2));
      expect(contents.missingImages, 0);
    });

    test('backslash separators', () {
      final BackupContents contents = BackupArchive.read(
        rewritten(full, (String n) => n.replaceAll('/', '\\')),
      );
      expect(contents.entries, hasLength(2));
    });

    test('an uppercased path', () {
      final BackupContents contents = BackupArchive.read(
        rewritten(full, (String n) => n.toUpperCase()),
      );
      expect(contents.entries, hasLength(2));
    });
  });

  test('the manifest sits at the archive root, readable on its own', () {
    // Somebody opening the zip should find the explanation without hunting,
    // and any JSON tool should parse it.
    final Archive archive = ZipDecoder().decodeBytes(
      BackupArchive.write(
        folders: <BackupFolder>[_folder('Work')],
        sources: <BackupSource>[_source('a', folder: 0)],
      ),
    );
    final ArchiveFile manifest = archive.files.firstWhere(
      (ArchiveFile f) => f.name == BackupManifest.fileName,
    );
    final Object? decoded = jsonDecode(utf8.decode(manifest.readBytes()!));
    expect(decoded, isA<Map<String, Object?>>());
    expect((decoded as Map<String, Object?>)['kind'], BackupManifest.kind);
  });

  // The path the app actually takes. Everything above goes through the
  // in-memory helpers, which is convenient for a test and is precisely what a
  // real library must never do — so the streaming pair needs covering on its
  // own terms rather than by proxy.
  group('streaming straight to and from a file', () {
    late Directory directory;
    late String path;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('shoto-bk');
      path = p.join(directory.path, 'backup.zip');
    });
    tearDown(() => directory.deleteSync(recursive: true));

    test('a library written one at a time comes back whole', () {
      final BackupWriter writer = BackupArchive.openWriter(
        path: path,
        folders: <BackupFolder>[_folder('Receipts'), _folder('وصفات')],
      );
      writer.add(_source('first', folder: 0, fav: true, text: 'رمز 481920'));
      writer.add(_source('second', folder: 1, labels: <String>['Ice cream']));
      writer.add(_source('third'));

      expect(writer.count, 3);
      final int size = writer.close();
      expect(size, File(path).lengthSync());

      final BackupReader reader = BackupArchive.openReader(path);
      addTearDown(reader.close);

      expect(reader.manifest.folders.map((BackupFolder f) => f.name), <String>[
        'Receipts',
        'وصفات',
      ]);

      final List<BackupEntry> entries = reader.entries().toList();
      expect(entries, hasLength(3));
      expect(reader.missingImages, 0);

      expect(utf8.decode(entries[0].bytes), 'first');
      expect(entries[0].item.folderIndex, 0);
      expect(entries[0].item.isFavorite, isTrue);
      expect(entries[0].item.ocrText, 'رمز 481920');

      expect(utf8.decode(entries[1].bytes), 'second');
      expect(entries[1].item.visualLabels, <String>['Ice cream']);

      expect(utf8.decode(entries[2].bytes), 'third');
      expect(entries[2].item.folderIndex, isNull);
    });

    test('the streamed file is byte-identical to the in-memory one', () {
      // The two writers must not drift into producing different formats — one
      // of them is what users have on disk and the other is what every test
      // above is checking.
      final BackupWriter writer = BackupArchive.openWriter(
        path: path,
        folders: <BackupFolder>[_folder('Work')],
      );
      writer.add(_source('a', folder: 0, fav: true));
      writer.add(_source('b'));
      writer.close();

      final BackupContents streamed = BackupArchive.read(
        File(path).readAsBytesSync(),
      );
      expect(streamed.isComplete, isTrue);
      expect(streamed.entries.map((BackupEntry e) => utf8.decode(e.bytes)), <
        String
      >['a', 'b']);
      expect(streamed.entries[0].item.isFavorite, isTrue);
    });

    test('an empty library still produces a readable archive', () {
      // Nothing to back up is not an error, and the file must not be a zip
      // with no central directory that every unzip tool then rejects.
      BackupArchive.openWriter(path: path, folders: <BackupFolder>[]).close();

      final BackupReader reader = BackupArchive.openReader(path);
      addTearDown(reader.close);
      expect(reader.entries().toList(), isEmpty);
      expect(reader.manifest.folders, isEmpty);
    });

    test('a file that is not a zip is refused by name, not by crash', () {
      File(path).writeAsStringSync('definitely not a zip file');
      expect(
        () => BackupArchive.openReader(path),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('a zip with no manifest is refused', () {
      final Archive plain = Archive()
        ..add(ArchiveFile.bytes('images/00001.png', _bytes('lonely')));
      File(path).writeAsBytesSync(ZipEncoder().encodeBytes(plain));
      expect(
        () => BackupArchive.openReader(path),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('adding after close is refused rather than silently dropped', () {
      final BackupWriter writer = BackupArchive.openWriter(
        path: path,
        folders: <BackupFolder>[],
      );
      writer.add(_source('a'));
      writer.close();
      expect(() => writer.add(_source('b')), throwsStateError);
      expect(writer.close, throwsStateError);
    });
  });
}
