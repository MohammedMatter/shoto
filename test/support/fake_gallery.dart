import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';

/// Stands in for the phone's gallery so a screen that draws thumbnails can be
/// photographed.
///
/// `AssetThumbnailImage` resolves through `AssetEntityImageProvider`, which
/// asks the `com.fluttercandies/photo_manager` channel for bytes. A widget
/// test has no platform on the other end, so the call returns null, the image
/// fails to resolve, and Flutter reports it as an unhandled error — which
/// fails the test before it can compare anything.
///
/// Answering `getThumb` ourselves fixes both halves at once: no error, and a
/// real picture in the card rather than an empty box.
abstract final class FakeGallery {
  static const MethodChannel _channel = MethodChannel(
    'com.fluttercandies/photo_manager',
  );

  /// Six flat colours, cycled by asset id.
  ///
  /// Flat rather than photographic on purpose. These stand for screenshots the
  /// reviewer is not meant to read — what the strip has to prove is card
  /// geometry, the hairline that separates a dark capture from the canvas, and
  /// where the row stops. A recognisable photograph in each card would draw
  /// the eye to the content and away from all three.
  static const List<Color> _fills = <Color>[
    Color(0xFF3A3A3A),
    Color(0xFFD8D8D8),
    Color(0xFF1C1C1C),
    Color(0xFF6E6E6E),
    Color(0xFFEFEFEF),
    Color(0xFF2A2A2A),
  ];

  static final Map<int, Uint8List> _pngs = <int, Uint8List>{};

  /// Renders the palette once and installs the channel handler.
  ///
  /// Call from `setUpAll`. The bytes are built here rather than hard-coded so
  /// they stay one obvious thing — a solid rectangle — instead of a base64
  /// blob nobody can check.
  static Future<void> install() async {
    if (_pngs.isEmpty) {
      for (int i = 0; i < _fills.length; i++) {
        _pngs[i] = await _solid(_fills[i]);
      }
    }

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
          // Everything else — `notify`, `startChangeNotify`, the permission
          // calls — answers null rather than falling through to a
          // MissingPluginException. A widget that merely *registers* for
          // gallery changes should not fail a test that has no gallery.
          if (call.method != 'getThumb') return null;
          final String id = (call.arguments['id'] ?? '0').toString();
          final int slot = (int.tryParse(id) ?? 0) % _fills.length;
          return _pngs[slot];
        });
  }

  static void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  /// A screenshot-shaped asset. Only [id] and the dimensions are ever read by
  /// anything this app draws.
  static AssetEntity asset(int id) => AssetEntity(
    id: '$id',
    typeInt: AssetType.image.index,
    width: 1080,
    height: 2340,
  );

  static Future<Uint8List> _solid(Color color) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 60, 130), Paint()..color = color);
    final ui.Image image = await recorder.endRecording().toImage(60, 130);
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}
