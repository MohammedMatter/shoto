import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';

import 'support/fake_gallery.dart';

/// **Which part of a screenshot survives the crop.**
///
/// A screenshot says what it is in its first fifth — the status bar, the app's
/// header, the sender, the subject, the heading. Centre-cropping a tall
/// capture into a square tile keeps the middle of a message thread instead,
/// which looks identical on every screenshot anybody owns.
///
/// This is asserted here rather than left to the golden files because the
/// goldens cannot see it: the fake gallery paints flat colour, so a tile
/// aligned to the top and a tile aligned to the centre produce byte-identical
/// PNGs. The change was invisible to the whole suite until this existed.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await FakeGallery.install();
  });
  tearDownAll(FakeGallery.uninstall);

  final AssetEntity asset = FakeGallery.asset(1);

  Future<Alignment> alignmentOf(WidgetTester tester, Widget thumbnail) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: 120, height: 120, child: thumbnail),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<Image>(find.byType(Image)).alignment as Alignment;
  }

  testWidgets('a tile keeps the top of the screenshot', (tester) async {
    expect(
      await alignmentOf(tester, AssetThumbnailImage(asset: asset)),
      Alignment.topCenter,
    );
  });

  testWidgets('a single capture being judged stays centred', (tester) async {
    // Nothing is cropped under BoxFit.contain, so alignment only decides which
    // end the letterboxing goes on — and the triage screen asks the user to
    // look at one capture, which belongs in the middle of its box.
    expect(
      await alignmentOf(
        tester,
        AssetThumbnailImage(
          asset: asset,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
      Alignment.center,
    );
  });
}
