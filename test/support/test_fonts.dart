import 'dart:io';

import 'package:flutter/services.dart';

/// Loads real typefaces into a widget test.
///
/// `flutter test` deliberately draws every glyph as a filled box so that
/// layout tests can't break on a font update. That is the right default for
/// assertions and the wrong one for looking at a screenshot — a golden full
/// of black rectangles tells you nothing about whether a screen reads well.
/// Anything generating an image to review should call this first.
Future<void> loadTestFonts() async {
  // Every family the app declares, because a golden is only worth looking at
  // if the type in it is the type that ships. This list went stale once
  // already: it still named `PlusJakartaSans` after the app had moved to
  // Archivo + IBM Plex, so `loadTestFonts()` quietly loaded nothing and every
  // golden came out as rows of filled rectangles — which reads as "the font
  // failed" only if you know it should not.
  await _loadFamily('IBMPlexSans', ['IBMPlexSans.ttf']);
  await _loadFamily('Archivo', ['Archivo.ttf']);
  await _loadFamily('IBMPlexMono', [
    'IBMPlexMono-Regular.ttf',
    'IBMPlexMono-SemiBold.ttf',
  ]);

  // Three Noto fallbacks — Arabic, Devanagari and Nastaliq — used to be
  // loaded here, because a golden rendered in Arabic came out as boxes
  // without them. Every shipped language is Latin now and the faces are no
  // longer bundled, so there is nothing to load; `_loadFamily` skips a file
  // that is not there, but naming a font the app does not have would make
  // this list stale in exactly the way its comment above warns about.
  //
  // Whatever brings a non-Latin language back adds its face to both places.
  await _loadIconFont();
}

Future<void> _loadFamily(String family, List<String> fileNames) async {
  final FontLoader loader = FontLoader(family);
  bool any = false;

  for (final String name in fileNames) {
    final File file = File('assets/fonts/$name');
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
    any = true;
  }

  if (any) await loader.load();
}

Future<void> _loadIconFont() async {
  final File? file = _findIconFont();
  if (file == null) return;

  final FontLoader loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
  await loader.load();
}

/// The icon font ships inside the Flutter SDK, whose location differs per
/// machine — so it is searched for rather than hardcoded, and a miss just
/// means boxes rather than a failed test.
File? _findIconFont() {
  final String? flutterRoot = _flutterRoot();
  if (flutterRoot == null) return null;

  final List<String> candidates = [
    'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    'bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/'
        'MaterialIcons-Regular.otf',
  ];

  for (final String relative in candidates) {
    final File file = File('$flutterRoot/$relative');
    if (file.existsSync()) return file;
  }
  return null;
}

String? _flutterRoot() {
  final String? fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

  // The test runner itself lives in the SDK: .../bin/cache/dart-sdk/bin/dart
  final List<String> parts = Platform.resolvedExecutable
      .replaceAll(r'\', '/')
      .split('/');
  final int cacheIndex = parts.lastIndexOf('cache');
  if (cacheIndex < 2) return null;
  return parts.sublist(0, cacheIndex - 1).join('/');
}
