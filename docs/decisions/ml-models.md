# The machine-learning models

## What ships

Two ML Kit capabilities are used, and they are now shipped differently:

- **Text recognition — unbundled.** The model lives in Google Play services
  and is fetched rather than carried. Behind search (free) and Safe Share
  (paid).
- **Image labelling — bundled.** The visual vocabulary behind content filters,
  weights and all, inside the APK.

## Why one and not the other

The image-labelling plugin depends on `image-labeling-custom` and compiles its
Kotlin against classes that exist only in the bundled artifact. Excluding it
does not swap the model, it breaks the build. Swapping it needs a patched
plugin, which is a fork to maintain for a smaller saving than the OCR one.

Text recognition has no such problem: `play-services-mlkit-text-recognition`
exposes the identical `com.google.mlkit.vision.text` API, so the plugin
compiles unchanged.

## What it saved, measured

| | release APK, all three ABIs |
|---|---|
| bundled OCR | 122.6 MB |
| unbundled OCR | 93.5 MB |

About 29 MB, or roughly 10 MB per single-ABI download — and it is paid by every
free user, most of whom never run a scan.

## Why it was verified on a device rather than reasoned about

The swap cannot be trusted from a build that compiles. Its failure modes are
all at runtime — Play services too old, absent entirely (a real share of
Android has no Google Play), or the model not yet downloaded when the first
scan runs — and every one of them produces an app that looks fine and finds
nothing.

It also cannot be verified by searching and seeing results: the OCR text of
every screenshot already in the library is cached in sqlite, so a search can
succeed without any recognizer running at all. The evidence has to come from
the log.

Installed on a Xiaomi 23021RAAEG, search run, `adb logcat`:

```
W DynamiteModule: Local module descriptor class for
    com.google.mlkit.dynamite.text.latin not found.
D DecoupledTextDelegate: Start loading thin OCR module.
I DynamiteModule: Selected remote version of
    com.google.android.gms.vision.ocr, version >= 262833001
D nativeloader: Load .../libmlkit_google_ocr_pipeline_gms.so ... ok
I native  : Resizing Thread Pool: ocr_det_0 to 3
```

Line one is the bundled model being genuinely absent. The rest is the model
being loaded out of Play services and the detector actually running. Both
halves matter: either alone proves nothing.

## What is still untested

**A device with no Google Play services, or offline on first run.** The
`com.google.mlkit.vision.DEPENDENCIES` meta-data asks Play to fetch the model
at install time, which covers the ordinary case, but the app has no handling
for "the recognizer is not available" — it would surface as a scan that
returns nothing rather than as a message.

That is the next thing to fix if this ships to a wide audience, and it is
cheap: `MlKitContext` can be asked whether the module is present, and the one
place that needs to know is the screen that says "reading this screenshot".
