import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/asset_thumbnail_image.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';

/// [FolderCard] draws a picture with a caption under it, inside a tile whose
/// height the grid fixes in advance. Two things about that can go wrong
/// silently, and both are checked here rather than left to be noticed on a
/// phone.
void main() {
  /// The geometry the real grid hands one tile, worked out the same way
  /// FoldersPage's delegate does: a 360dp-wide screen, a 20dp gutter each
  /// side, 14dp between two columns, at `childAspectRatio: 0.72`.
  const double tileWidth = (360 - 40 - 14) / 2;
  const double tileHeight = tileWidth / 0.72;

  FolderEntity folder({
    String name = 'Receipts',
    int screenshotCount = 12,
    bool isPrivate = false,
  }) => FolderEntity(
    id: 1,
    name: name,
    color: 0xFF5B8DEF,
    createdAt: DateTime(2026, 1, 1),
    screenshotCount: screenshotCount,
    isPrivate: isPrivate,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required FolderEntity entity,
    AssetEntity? cover,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: FolderCard(
                    folder: entity,
                    cover: cover,
                    onTap: () {},
                    onMoreTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// The caption is the part that grows, and the tile cannot.
  ///
  /// This is why the cover is wrapped in `Expanded` rather than given a fixed
  /// [AspectRatio]: at a large system text scale a fixed-ratio cover plus two
  /// lines of caption is taller than the tile, and Flutter answers that with
  /// yellow stripes across the bottom of every folder on the screen. Here the
  /// picture simply gets shorter.
  testWidgets('caption never overflows the tile, at any text scale', (
    WidgetTester tester,
  ) async {
    AppColors.setBrightness(Brightness.dark);

    // 2.0 is past what the Android accessibility slider reaches by default;
    // if it survives that it survives the real range.
    for (final double scale in <double>[1, 1.3, 1.6, 2]) {
      await pumpCard(
        tester,
        entity: folder(name: 'Receipts and warranties 2026'),
        textScale: scale,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'FolderCard overflowed its tile at text scale $scale',
      );
    }
  });

  /// **A locked folder must not show what is inside it.**
  ///
  /// Opening a private folder costs a fingerprint, so a cover thumbnail on the
  /// grid would hand over the exact thing the lock exists to withhold — to
  /// anybody holding the phone, without them touching it. The guard lives
  /// inside the cover widget so no call site can forget it, and this is what
  /// stops a later refactor from quietly removing it.
  testWidgets('a private folder draws no cover, even when one is available', (
    WidgetTester tester,
  ) async {
    AppColors.setBrightness(Brightness.dark);

    final AssetEntity asset = AssetEntity(
      id: 'asset-1',
      typeInt: AssetType.image.index,
      width: 1080,
      height: 2400,
    );

    await pumpCard(tester, entity: folder(isPrivate: true), cover: asset);

    expect(
      find.byType(AssetThumbnailImage),
      findsNothing,
      reason: 'a locked folder rendered its contents on the grid',
    );
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  /// The other half of the same rule: an unlocked folder with nothing in it
  /// falls back to its own colour rather than to a grey box, so the folder
  /// just created — the one being looked for — is still recognisable.
  testWidgets('an empty folder falls back to its colour and folder glyph', (
    WidgetTester tester,
  ) async {
    AppColors.setBrightness(Brightness.dark);

    await pumpCard(tester, entity: folder(screenshotCount: 0));

    expect(find.byType(AssetThumbnailImage), findsNothing);
    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
  });

  /// Generation-only, like the other goldens in this directory: no committed
  /// baseline, never fails a normal run. It exists so the grid can be looked
  /// at rather than only asserted about — spacing, the colour edge, and how
  /// the caption sits under the picture are not things an assertion can judge.
  ///
  /// Every tile here is a placeholder cover, because a widget test has no
  /// gallery to read a real thumbnail out of. That still answers the question
  /// this golden is for: the geometry is identical either way, and a
  /// photograph would only make it easier to look at.
  Future<void> renderGrid(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    AppColors.setBrightness(brightness);

    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final List<FolderEntity> folders = [
      FolderEntity(
        id: 1,
        name: 'Receipts',
        color: 0xFF5B8DEF,
        createdAt: DateTime(2026),
        screenshotCount: 24,
      ),
      FolderEntity(
        id: 2,
        name: 'Recipes',
        color: 0xFF7E9B5E,
        createdAt: DateTime(2026),
        screenshotCount: 8,
      ),
      FolderEntity(
        id: 3,
        name: 'Bank statements 2026',
        color: 0xFFFFC857,
        createdAt: DateTime(2026),
        screenshotCount: 3,
        isPrivate: true,
      ),
      FolderEntity(
        id: 4,
        name: 'Design',
        color: 0xFFEF5DA8,
        createdAt: DateTime(2026),
        screenshotCount: 0,
      ),
    ];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: folders.length,
                itemBuilder: (context, index) => FolderCard(
                  folder: folders[index],
                  onTap: () {},
                  onMoreTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('folders grid — dark', (WidgetTester tester) async {
    await renderGrid(tester, Brightness.dark);
    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('goldens/folders_grid_dark.png'),
    );
  }, skip: !autoUpdateGoldenFiles);

  testWidgets('folders grid — light', (WidgetTester tester) async {
    await renderGrid(tester, Brightness.light);
    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('goldens/folders_grid_light.png'),
    );
  }, skip: !autoUpdateGoldenFiles);
}
