# The machine-learning models

## What ships today

Two ML Kit models are compiled into the APK:

- `com.google.mlkit:text-recognition` — OCR. Behind search (free) and Safe
  Share (paid).
- `com.google.mlkit:image-labeling` (plus `image-labeling-custom` and
  `linkfirebase`) — the visual vocabulary behind content filters.

Both are the **bundled** variants: the model weights are inside the app, so the
first scan works offline and instantly. Every user carries them whether or not
they ever run a scan.

**What it costs, measured.** In a release APK containing all three ABIs
(122.6 MB), ML Kit's native libraries are about 60 MB compressed —
`libmlkit_google_ocr_pipeline.so` and `libmlkitcommonpipeline.so` are the two
largest entries in the file after Flutter's own engine. A single-ABI download
carries roughly a third of that, so the real per-user figure is nearer 20 MB.
That is still the largest single thing in the app that most free users will
never use.

## The unbundled alternative

Google ships a second variant of each artifact that keeps the model in Google
Play services and downloads it on first use:

```kotlin
// android/app/build.gradle.kts
configurations.all {
    exclude(group = "com.google.mlkit", module = "text-recognition")
    exclude(group = "com.google.mlkit", module = "image-labeling")
}
dependencies {
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.1")
    implementation("com.google.android.gms:play-services-mlkit-image-labeling:16.0.8")
}
```

```xml
<!-- AndroidManifest.xml, inside <application> -->
<meta-data android:name="com.google.mlkit.vision.DEPENDENCIES" android:value="ocr,ica" />
```

The Java API is the same in both variants, so the plugins' Kotlin compiles
against either.

## Why it is not done

**The swap cannot be verified without running OCR on a real device**, and OCR
is the engine under search, content filters and Safe Share — the three things
this release is about. A build that compiles proves nothing here: the failure
mode of the unbundled variant is at *runtime*, on a device where Play services
is old, or missing (no Google Play — a real share of Android), or the model
download has not finished when the first scan runs. All three produce an app
that looks fine and finds nothing.

It also changes the promise. Bundled, the first scan works on a plane. Unbundled,
the first scan needs a network and a wait, on a screen that currently says
"reading this screenshot" and means it.

## What would have to happen first

1. The swap, on a branch.
2. On device: OCR a screenshot **with the app freshly installed and offline**,
   and confirm the failure is a message rather than an empty result.
3. The same with Play services present but the model not yet downloaded — the
   `ModuleInstall` API can be asked directly rather than waiting for the first
   scan to trigger it.
4. A decision about the first-run experience, because there now is one.

Deferred rather than dropped. The saving is real and it is paid by every free
user; it is simply not a change to make blind, and it is not what stands
between this app and a release.
