import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Getting a backup file out of the app and back into it.
///
/// Both directions deliberately hand the choice to the operating system rather
/// than to SHOTO. The app never learns where the backup ends up, which is the
/// only version of "your data stays yours" that survives contact with a
/// feature whose whole job is producing a copy of everything.
class BackupFileService {
  static const MethodChannel _channel = MethodChannel('shoto/files');

  /// Hands [filePath] to the system share sheet so the user picks the
  /// destination — their own Drive, their Files app, a message to themselves.
  ///
  /// Not written straight to Downloads: a fixed location is one more thing to
  /// ask permission for, one more thing to explain, and it would still be on
  /// the phone that is about to be lost.
  Future<void> exportFile(String filePath, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(filePath)], subject: subject),
    );
  }

  /// Opens the system document picker.
  ///
  /// Returns the path of a readable copy, or null when the user backed out —
  /// which is an ordinary outcome and must not be reported as a failure.
  Future<String?> pickBackup() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('pickBackup');
    } on PlatformException catch (error) {
      debugPrint('SHOTO file picker failed: ${error.message}');
      return null;
    } on MissingPluginException {
      // The channel lives in MainActivity; the share sheet runs in its own
      // activity with its own engine and has no picker registered. Restoring
      // is not offered there, but returning null beats throwing if it ever is.
      return null;
    }
  }
}
