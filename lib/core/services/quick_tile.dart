import 'dart:io';

import 'package:flutter/services.dart';

/// How the system answered a request to install Shoto's Quick Settings tile.
enum QuickTileOutcome {
  /// It is in the panel now — either just placed, or already there.
  added,

  /// The dialog was shown and the user said no.
  declined,

  /// The platform cannot be asked: Android below 13, iOS, or a skin whose
  /// System UI refused the call. The manual route still works, so the UI
  /// explains it rather than reporting a failure.
  unsupported,
}

/// The Quick Settings tile, from Dart's side.
///
/// One method, and it exists for a reason worth stating: **the tile is
/// invisible until somebody puts it in their panel**, and doing that by hand
/// means pulling the shade down, finding the pencil, scrolling a drawer of
/// grey tiles and dragging one into the grid. Those are instructions, and a
/// feature that ships with instructions ships to nobody.
///
/// Android 13 will show the panel's own dialog on request, which turns four
/// described steps into one tap on a surface the user already trusts. That is
/// the whole of what this class is for.
///
/// Kept out of the settings page — and out of any widget — so the platform
/// check lives in one place. Every caller gets the same three answers and
/// none of them has to know what `TIRAMISU` is.
abstract final class QuickTile {
  static const MethodChannel _channel = MethodChannel('shoto/tile');

  /// Whether this platform has a Quick Settings panel at all.
  ///
  /// A cheap, synchronous answer so a settings row can decide whether to
  /// exist without a round trip and without a frame of the wrong layout. It
  /// says nothing about the Android *version* — that is the native side's
  /// call, and it comes back as [QuickTileOutcome.unsupported].
  static bool get isSupportedPlatform => Platform.isAndroid;

  /// Asks Android to place the tile, showing its own confirmation dialog.
  ///
  /// Never throws: a channel that is missing or a System UI that refuses both
  /// resolve to [QuickTileOutcome.unsupported], because from the user's side
  /// those are the same situation — the shortcut has to be added by hand.
  static Future<QuickTileOutcome> requestAdd() async {
    if (!isSupportedPlatform) return QuickTileOutcome.unsupported;
    try {
      final String? answer = await _channel.invokeMethod<String>('requestAdd');
      return switch (answer) {
        'added' => QuickTileOutcome.added,
        'declined' => QuickTileOutcome.declined,
        _ => QuickTileOutcome.unsupported,
      };
    } on PlatformException {
      return QuickTileOutcome.unsupported;
    } on MissingPluginException {
      return QuickTileOutcome.unsupported;
    }
  }
}
