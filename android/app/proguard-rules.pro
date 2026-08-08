# R8 rules for the release build.
#
# **Without this file `flutter build apk --release` does not complete**, which
# is worth stating plainly: every build this project has ever run was a debug
# one, and the failure only appears at the step that produces the thing you
# would upload.
#
# `google_mlkit_text_recognition` declares the Chinese, Devanagari, Japanese
# and Korean recognizers as `compileOnly` — the plugin compiles against them so
# it can offer every script, and ships none of them, so an app that only wants
# Latin does not carry four extra models. Its `initialize` method therefore
# references classes that are genuinely not in the APK, and R8 stops rather
# than guessing that the branch is unreachable.
#
# It *is* unreachable: `TextRecognitionDataSource` only ever asks for the Latin
# recognizer. These four lines say so.
#
# If Shoto ever needs to read Chinese, Japanese, Korean or Devanagari script,
# the fix is to add the matching artifact as a real `implementation` dependency
# — not to widen this rule.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
