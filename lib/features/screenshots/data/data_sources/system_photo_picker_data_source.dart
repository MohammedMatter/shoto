import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// The operating system's own photo picker.
///
/// This exists so the app can accept images **without ever looking through the
/// user's gallery**. The distinction is the whole reason it is here rather than
/// an in-app grid built on photo_manager, which the app already depends on and
/// could trivially have used:
///
/// * An in-app picker has to *list* albums to show them. Whatever it does with
///   the result, the app has read the user's photos to draw that screen.
/// * The system picker runs outside the app. The user sees their photos in the
///   OS's own UI, and the app is handed the files that were picked and nothing
///   else — it never learns what else is on the phone.
///
/// On Android 13+ this is the platform Photo Picker, which needs no media
/// permission at all; on iOS it is `PHPicker`, same story. SHOTO does hold photo
/// permission for its own album, so this is not what makes the app work — it is
/// what keeps "import" honest about its scope.
///
/// The files that come back are **copies in the app's cache**, not gallery
/// assets. There is no asset id to claim in place, which is why importing a
/// picked file goes through the same copy-into-SHOTO's-album path a shared
/// screenshot does.
class SystemPhotoPickerDataSource {
  final ImagePicker _picker;

  SystemPhotoPickerDataSource({ImagePicker? picker})
    : _picker = picker ?? ImagePicker() {
    _useAndroidPhotoPicker();
  }

  /// Opts Android into the **real** platform Photo Picker.
  ///
  /// The class doc above describes what this app wants, and until this line
  /// existed it described something the app was not actually getting.
  /// `image_picker` still defaults `useAndroidPhotoPicker` to false, which
  /// sends an `ACTION_GET_CONTENT` intent — the old document-provider flow.
  /// On Android 13+ the system intercepts that and draws the photo picker
  /// anyway, but in a compatibility activity
  /// (`PhotopickerGetContentActivity`) rather than the picker proper. This
  /// flag sends `ACTION_PICK_IMAGES` instead, which is the real thing: it
  /// runs entirely outside the app and needs no media permission, so the
  /// privacy claim in the class doc above is finally true rather than
  /// aspirational.
  ///
  /// **It does not change how the picker is dismissed**, and that is worth
  /// recording because it is the obvious thing to try. Both activities were
  /// checked on Android 17: swiping the sheet down closes it, the back
  /// gesture closes it, and tapping the dimmed area outside it does nothing
  /// in either. That behaviour belongs to a system activity in another
  /// process — no Flutter-side setting reaches it, and the only way to get a
  /// sheet that closes on an outside tap would be an in-app picker, which
  /// this class exists specifically to avoid.
  ///
  /// Set on the platform instance rather than passed per call, because that
  /// is the only place the plugin reads it from. Guarded by a type check
  /// instead of `Platform.isAndroid` so it is a no-op on every other platform
  /// (and in tests, where the instance is a fake) without touching `dart:io`.
  static void _useAndroidPhotoPicker() {
    final ImagePickerPlatform platform = ImagePickerPlatform.instance;
    if (platform is ImagePickerAndroid) platform.useAndroidPhotoPicker = true;
  }

  /// Opens the picker and returns the paths of what the user chose, or an empty
  /// list if they backed out.
  ///
  /// Multi-select, because the case this feature exists for is a handful of
  /// screenshots at once — offering one at a time would mean reopening the
  /// picker for each, which is the version of this that makes people give up.
  ///
  /// No `imageQuality` or `maxWidth`: those make the plugin re-encode the image,
  /// and a screenshot re-encoded as a lossy JPEG loses exactly what a screenshot
  /// is kept for — legible text. The bytes arrive as they are.
  Future<List<String>> pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage();
    return picked.map((file) => file.path).toList();
  }
}
