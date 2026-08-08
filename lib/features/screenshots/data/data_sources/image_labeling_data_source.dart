import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shoto/core/utils/visual_vocabulary.dart';

/// Names what is *in* a picture, on the device, so a rule or a search can
/// reach a photo that contains no readable text at all.
///
/// Every other way Shoto understands a screenshot reads words: search, safe
/// share and smart actions all run on OCR. That leaves a real hole — a saved
/// photo, a meme, a design reference has nothing to read. This is the only
/// part of the app that looks at the image itself.
///
/// The model ships inside the app: nothing is uploaded, it works offline, and
/// it costs nothing per image — the same trade the OCR already makes.
///
/// ## Why this file is more than one model call
///
/// The first version was one call at a 0.6 threshold, and on a real library
/// it produced almost nothing usable: `["Screenshot"]`, `["Mobile phone"]`,
/// `["Product","Screenshot","Web page"]`. A rule saying "shows an animal"
/// never fired, even on a screenshot that was mostly dog.
///
/// The cause is that the model describes the **whole frame**, and the whole
/// frame is a phone screen. Status bar, navigation bar, app chrome and
/// browser UI are all real, confidently-labelled content — they just aren't
/// what the picture is *about*. Three changes together fix it:
///
/// 1. **Look at the middle as well as the whole.** The chrome lives at the
///    edges; the subject is almost always centred. A second pass over the
///    central crop gives the subject most of the frame instead of a fraction
///    of it, and the two results are merged — running the crop pass *only*
///    when the full frame came back empty was itself a bug, because a weak
///    but technically-meaningful label like `Poster` was enough to skip it.
/// 2. **A lower threshold, because the noise is now removable.** 0.6 was
///    chosen to keep junk out. With medium labels dropped by name, the
///    remaining labels are all about the subject, so a weaker signal is worth
///    keeping — a dog at 0.45 in a screenshot is a real dog.
/// 3. **Drop the medium labels** ([VisualVocabulary.mediumLabels]). "This is
///    a screenshot" is true of everything in the app and therefore useless.
class ImageLabelingDataSource {
  /// Deliberately below the package default of 0.5.
  ///
  /// A subject inside a screenshot is competing with the app UI around it, so
  /// its confidence is structurally lower than the same subject filling a
  /// photo. The labels that used to justify a high bar are now discarded by
  /// name instead.
  static const double _confidenceThreshold = 0.35;

  /// How much of each edge the centre pass throws away.
  ///
  /// 12% clears a status bar and a navigation bar on every phone shape
  /// without cutting into content — the top and bottom are where the chrome
  /// is, and nobody's subject starts in the status bar.
  static const double _cropInset = 0.12;

  /// One labeler reused for the app's lifetime — same as
  /// [TextRecognitionDataSource]. Creating one per image reloads the model
  /// on every call.
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: _confidenceThreshold),
  );

  /// The meaningful labels in [imageFile], most confident first.
  ///
  /// Returns an empty list rather than throwing when anything fails: a
  /// screenshot that cannot be labelled is one that visual rules won't reach,
  /// which is where the app already was. It must never take an indexing
  /// sweep down with it.
  Future<List<String>> label(File imageFile) async {
    // Both passes, always, merged.
    //
    // The first version ran the centre pass *only* when the full frame found
    // nothing meaningful, which sounded like a sensible saving and was in
    // fact the bug. A real library produced labels like `Poster` for the
    // whole frame — technically about the subject, so the shortcut fired,
    // returned `["Poster"]`, and the dog filling the middle of that same
    // screenshot was never looked for. Seven rows in the reported library
    // were stuck exactly there.
    //
    // The two passes answer different questions — "what is this picture" and
    // "what is in the middle of it" — and a screenshot usually needs both.
    // The saving was never worth what it cost: one extra model call is a few
    // tens of milliseconds against a feature that either works or doesn't.
    final List<String> full = await _labelFile(imageFile);

    final File? centre = await _centreCrop(imageFile);
    if (centre == null) return full;

    try {
      final List<String> inner = await _labelFile(centre);
      // Order matters — it is confidence order, and the shortlist the rule
      // builder offers is cut from the top. The centre pass goes first
      // because a subject that survived the crop is the better answer to
      // "what does this show".
      return <String>{...inner, ...full}.toList();
    } finally {
      // Best-effort: a leftover crop in the cache directory is harmless and
      // is cleared with the rest of it.
      try {
        await centre.delete();
      } catch (_) {}
    }
  }

  Future<List<String>> _labelFile(File file) async {
    try {
      final InputImage input = InputImage.fromFilePath(file.path);
      final List<ImageLabel> labels = await _labeler.processImage(input);
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      return VisualVocabulary.meaningful([
        for (final ImageLabel label in labels) label.label,
      ]);
    } catch (_) {
      return const [];
    }
  }

  /// Writes the middle of [source] to a temporary file, or null if it cannot.
  Future<File?> _centreCrop(File source) async {
    try {
      final ui.Image image = await decodeImageFromList(
        await source.readAsBytes(),
      );
      final double dx = image.width * _cropInset;
      final double dy = image.height * _cropInset;
      final Rect src = Rect.fromLTRB(
        dx,
        dy,
        image.width - dx,
        image.height - dy,
      );

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        src,
        Rect.fromLTWH(0, 0, src.width, src.height),
        Paint(),
      );
      final ui.Image cropped = await recorder.endRecording().toImage(
        src.width.round(),
        src.height.round(),
      );
      final ByteData? png = await cropped.toByteData(
        format: ui.ImageByteFormat.png,
      );

      image.dispose();
      cropped.dispose();
      if (png == null) return null;

      final Directory dir = await getTemporaryDirectory();
      final File out = File(
        '${dir.path}/label_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(png.buffer.asUint8List());
      return out;
    } catch (_) {
      return null;
    }
  }

  void dispose() => _labeler.close();
}
