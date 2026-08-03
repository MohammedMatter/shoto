import 'package:flutter/services.dart';
import 'package:shoto/features/screenshots/data/data_sources/system_photo_picker_data_source.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';

/// The whole manual-import action: open the OS picker, save what came back.
///
/// Two collaborators rather than one because they answer different questions —
/// the picker decides *which* files, the repository decides what a library is —
/// and merging them would put an OS dialog inside the thing that owns the
/// database.
///
/// Returns how many screenshots joined the library: 0 covers both "the user
/// changed their mind in the picker" and "nothing could be read", and the caller
/// tells those apart by whether anything was picked at all.
class ImportFromSystemPickerUseCase {
  final SystemPhotoPickerDataSource picker;
  final ScreenshotRepository repository;

  ImportFromSystemPickerUseCase(this.picker, this.repository);

  Future<ImportResult> call() async {
    final List<String> paths;
    try {
      paths = await picker.pickImages();
    } on PlatformException catch (_) {
      // The picker is the operating system's, and it can decline to appear for
      // reasons that have nothing to do with this app: a channel that isn't
      // there (the usual one — a plugin added since the installed build, so the
      // native half is missing until the app is reinstalled rather than hot
      // reloaded), a device with no picker activity, an OEM that broke it.
      //
      // Caught here rather than left to propagate because the alternative is
      // what shipped: an unhandled PlatformException reaching the framework and
      // being reported to the user as a crash, for pressing a button.
      return const ImportResult(picked: 0, imported: 0, pickerFailed: true);
    }

    if (paths.isEmpty) return const ImportResult(picked: 0, imported: 0);

    final int imported = await repository.importPickedFiles(paths);
    return ImportResult(picked: paths.length, imported: imported);
  }
}

/// What an import attempt actually did.
///
/// Both numbers, because the difference between them is the only way the UI can
/// be honest. Picked 5 and imported 5 is "5 added"; picked 5 and imported 3 has
/// to say so rather than claim five.
///
/// And [pickerFailed] separately from both, because "nothing was picked" has two
/// meanings that must not share a message: a user who opened the picker and
/// changed their mind wants no message at all, while a picker that never opened
/// needs to say so or the button looks broken.
class ImportResult {
  final int picked;
  final int imported;

  /// The picker itself could not be opened. Not a user decision.
  final bool pickerFailed;

  const ImportResult({
    required this.picked,
    required this.imported,
    this.pickerFailed = false,
  });

  /// The user closed the picker without choosing. Silent by design.
  bool get cancelled => picked == 0 && !pickerFailed;

  bool get partial => imported < picked;
}
