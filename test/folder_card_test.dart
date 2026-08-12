import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_card.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// [FolderCard] draws two stacked shapes inside a tile whose height the grid
/// fixes in advance, with the folder's name written across the front one.
/// Several things about that can go wrong silently, and they are checked here
/// rather than left to be noticed on a phone.
void main() {
  /// The geometry the real grid hands one tile, worked out the same way
  /// FoldersPage's delegate does: a 360dp-wide screen, a 20dp gutter each
  /// side, 12dp between three columns, at `childAspectRatio: 0.76`.
  const double tileWidth = (360 - 40 - 24) / 3;
  const double tileHeight = tileWidth / 0.76;

  FolderEntity folder({
    String name = 'Receipts',
    int screenshotCount = 12,
    bool isPrivate = false,
    String? iconKey = 'receipt',
  }) => FolderEntity(
    id: 1,
    name: name,
    color: 0xFF5B8DEF,
    createdAt: DateTime(2026, 1, 1),
    screenshotCount: screenshotCount,
    isPrivate: isPrivate,
    iconKey: iconKey,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required FolderEntity entity,
    double textScale = 1,
    Brightness brightness = Brightness.dark,
  }) async {
    final AppPalette palette = testPalette(brightness);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              backgroundColor: palette.background,
              body: Center(
                child: SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: FolderCard(
                    folder: entity,
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

  /// The pocket is the part that grows, and the tile cannot.
  ///
  /// This is why the pocket is anchored to the bottom of a `Stack` with an
  /// intrinsic height rather than given a fixed fraction of the tile: at a
  /// large system text scale a fixed-height pocket plus two lines of text
  /// overflows, and Flutter answers that with yellow stripes across the bottom
  /// of every folder on the screen. Here the pocket simply grows upward over
  /// the plate behind it.
  testWidgets('the name plate never overflows the tile, at any text scale', (
    WidgetTester tester,
  ) async {
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

  /// **A locked folder must not advertise what is in it.**
  ///
  /// The rule outlived the screenshot cover it was written for. A folder whose
  /// contents cost a fingerprint should not wear a glyph that describes them —
  /// a padlock says the one thing about it that is true from outside.
  testWidgets('a private folder wears the padlock, not its own glyph', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, entity: folder(isPrivate: true, iconKey: 'pill'));

    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medication_rounded), findsNothing);
  });

  /// A folder that predates the icon column has no key at all, which is a
  /// state the grid still has to draw — those folders were plain folders and
  /// they stay plain folders.
  testWidgets('a folder with no icon key falls back to the folder glyph', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, entity: folder(iconKey: null));

    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
  });

  /// The count comes from the entity, and it is the one number on the card.
  testWidgets('an empty folder still says so', (WidgetTester tester) async {
    await pumpCard(tester, entity: folder(screenshotCount: 0));

    expect(find.text('No screenshots'), findsOneWidget);
  });

  /// The "⋯" is what makes rename and delete discoverable — a long-press has
  /// no visual affordance, so nobody finds it. It is dropped only where the
  /// card is a preview of a folder that does not exist yet.
  testWidgets('the more button appears only when there is a handler', (
    WidgetTester tester,
  ) async {
    await pumpCard(tester, entity: folder());
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(Brightness.dark),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: tileWidth,
                height: tileHeight,
                child: FolderCard(folder: folder(), onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });

  /// The grid, for looking at rather than asserting about: the folder shape,
  /// the offset between plate and pocket, how a long name ellipsizes and how
  /// eight hues sit beside each other are not things an assertion can judge.
  Future<void> renderGrid(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    final AppPalette palette = testPalette(brightness);

    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final List<FolderEntity> folders = [
      FolderEntity(
        id: 1,
        name: 'Trip plans',
        color: 0xFF5B8DEF,
        createdAt: DateTime(2026),
        screenshotCount: 24,
        iconKey: 'map',
      ),
      FolderEntity(
        id: 2,
        name: 'Recipes',
        color: 0xFFF5883C,
        createdAt: DateTime(2026),
        screenshotCount: 8,
        iconKey: 'food',
      ),
      FolderEntity(
        id: 3,
        name: 'Medications',
        color: 0xFFFF8A65,
        createdAt: DateTime(2026),
        screenshotCount: 3,
        iconKey: 'pill',
      ),
      FolderEntity(
        id: 4,
        name: 'AI notes',
        color: 0xFF8B7BF0,
        createdAt: DateTime(2026),
        screenshotCount: 0,
        iconKey: 'sparkle',
      ),
      FolderEntity(
        id: 5,
        name: 'Bank statements 2026',
        color: 0xFFFFC857,
        createdAt: DateTime(2026),
        screenshotCount: 12,
        isPrivate: true,
        iconKey: 'money',
      ),
      FolderEntity(
        id: 6,
        name: 'Workouts',
        color: 0xFF33E0C2,
        createdAt: DateTime(2026),
        screenshotCount: 5,
        iconKey: 'fitness',
      ),
      FolderEntity(
        id: 7,
        name: 'Music',
        color: 0xFFEF5DA8,
        createdAt: DateTime(2026),
        screenshotCount: 2,
        iconKey: 'music',
      ),
      // No key at all — the shape a folder made before the column existed
      // still comes out as.
      FolderEntity(
        id: 8,
        name: 'Design',
        color: 0xFF7E9B5E,
        createdAt: DateTime(2026),
        screenshotCount: 1,
      ),
    ];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: testTheme(brightness),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: palette.background,
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.76,
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
  });

  testWidgets('folders grid — light', (WidgetTester tester) async {
    await renderGrid(tester, Brightness.light);
    await expectLater(
      find.byType(GridView),
      matchesGoldenFile('goldens/folders_grid_light.png'),
    );
  });
}
