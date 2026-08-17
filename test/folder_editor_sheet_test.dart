import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/biometric_auth_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/widgets/primary_button.dart';
import 'package:shoto/features/folders/domain/entities/folder_entity.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_colors.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_editor_sheet.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_icons.dart';
import 'package:shoto/features/folders/presentation/widgets/folder_name_limit.dart';
import 'package:shoto/l10n/app_localizations.dart';

import 'support/test_theme.dart';

/// The sheet that names a folder, colours it and gives it a glyph — what it
/// hands back, and what it refuses to.
///
/// The golden file next door checks how it *looks*. This checks the four
/// decisions it makes that no screenshot can show: that an empty name is not a
/// folder, that a name is trimmed and capped before it reaches the database,
/// that opening it on an existing folder starts from that folder rather than
/// from the defaults, and that the lock is offered on creation only.
void main() {
  setUpAll(() {
    // `PressableScale` buzzes on tap and reads the haptics preference out of
    // the locator; the sheet asks the biometric service, in `initState`, which
    // modality this phone offers so the switch can name it. The real service
    // is safe here — with no platform channel to talk to it reports none.
    if (!sl.isRegistered<AppPreferences>()) {
      sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
    }
    if (!sl.isRegistered<BiometricAuthService>()) {
      sl.registerLazySingleton<BiometricAuthService>(
        () => BiometricAuthService(),
      );
    }
  });

  /// What the sheet handed back, or null if it never did.
  ({String name, int color, String? iconKey, bool isPrivate})? saved;

  setUp(() => saved = null);

  Future<void> openSheet(
    WidgetTester tester, {
    FolderEntity? existing,

    /// The window this sheet is opening into. Defaulted rather than fixed
    /// because how much of the sheet fits *is* what several of these tests are
    /// about — and a helper that quietly resized the view back to its own
    /// default would have made those tests pass on a screen nobody owns.
    Size physicalSize = const Size(1080, 1920),
    double devicePixelRatio = 3,
    FakeViewPadding padding = const FakeViewPadding(),
  }) async {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = padding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: testTheme(Brightness.dark),
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showFolderEditorSheet(
                    context,
                    existing: existing,
                    onSave:
                        (
                          String name,
                          int color,
                          String? iconKey,
                          bool isPrivate,
                        ) => saved = (
                          name: name,
                          color: color,
                          iconKey: iconKey,
                          isPrivate: isPrivate,
                        ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The one text field on the sheet.
  final Finder nameField = find.byType(TextField);

  /// The confirm button, whichever of its two labels it is wearing.
  Future<void> submit(WidgetTester tester) async {
    final Finder button = find.text('Create folder').evaluate().isNotEmpty
        ? find.text('Create folder')
        : find.text('Save');
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// A swatch in the colour row, found by the colour it is painted.
  Finder swatch(int value) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is AnimatedContainer &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
        (widget.decoration as BoxDecoration).color == Color(value),
  );

  group('what the sheet shows when it opens', () {
    /// The user's own phone: 1080×2400 at 2.75, so 393×873 logical.
    Future<void> openOnAPhone(WidgetTester tester) => openSheet(
      tester,
      physicalSize: const Size(1080, 2400),
      devicePixelRatio: 2.75,
      padding: const FakeViewPadding(top: 24 * 2.75, bottom: 12 * 2.75),
    );

    testWidgets('it does not raise the keyboard', (WidgetTester tester) async {
      // **The whole sheet is below the keyboard.** Measured at this size: the
      // header — preview card, field, swatches, lock row — is about 444dp, and
      // a keyboard leaves 416dp above the Create button. Focusing the field on
      // open therefore did not merely crop the glyph picker, it kept the
      // picker's slivers from ever being built, so the first folder somebody
      // made was named and coloured on a sheet that never admitted it had
      // ninety-eight pictures to choose from.
      await openOnAPhone(tester);

      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('the glyphs are on screen from the first frame', (
      WidgetTester tester,
    ) async {
      await openOnAPhone(tester);

      // Not "somewhere in the tree" — actually inside the window. A sliver
      // that has not been reached builds nothing, which is exactly how this
      // failed, so a `findsWidgets` here would have passed throughout.
      final Finder tile = find.byIcon(Icons.star_rounded);
      expect(tile, findsOneWidget);
      expect(
        tester.getRect(tile).bottom,
        lessThan(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
    });

    testWidgets('enough of them to read as a grid, not as a last row', (
      WidgetTester tester,
    ) async {
      // **One row is not an affordance.** Before the sheet was rearranged the
      // picker got 135dp of a 456dp scroll region — the first group's six
      // tiles, then a ragged two-tile row half-clipped, then the button. That
      // reads as the bottom of the sheet, and nobody scrolls past what looks
      // finished. Twelve is comfortably two full rows and the start of a
      // third; below that the picker is announcing itself by accident.
      await openOnAPhone(tester);

      final double screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final int visible = find
          .byType(FolderGlyph)
          .evaluate()
          .map(
            (Element e) =>
                tester.getRect(find.byElementPredicate((Element x) => x == e)),
          )
          .where((Rect r) => r.top >= 0 && r.bottom <= screen)
          .length;

      // Minus the one in the preview card, which is not a tile.
      expect(visible - 1, greaterThanOrEqualTo(12));
    });

    testWidgets('a second section starts before the edge of the sheet', (
      WidgetTester tester,
    ) async {
      // The strongest "this continues" a scroll region has: not a row cut in
      // half, which could be the last row, but a *new labelled section*
      // beginning. Getting the fold to land inside the tiles under that
      // heading rather than between them and it took the sheet's own ceiling
      // from 0.88 of the screen to 0.92, and six points off each heading.
      await openOnAPhone(tester);

      final double screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(find.text('Basics'), findsOneWidget);
      // The second group is the apps a screenshot came from — the section
      // people arrive looking for.
      final Finder second = find.text('Social');
      expect(second, findsOneWidget);
      expect(tester.getRect(second).bottom, lessThan(screen));
    });

    testWidgets('and so is everything else there is to choose', (
      WidgetTester tester,
    ) async {
      // The four decisions this sheet asks for, all legible without scrolling
      // or dismissing anything.
      await openOnAPhone(tester);

      expect(find.byType(TextField), findsOneWidget); // the name
      expect(swatch(kFolderColors.first), findsOneWidget); // the colours
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget); // the lock
      expect(find.byIcon(Icons.star_rounded), findsOneWidget); // the glyphs
    });

    testWidgets('tapping the field is what brings the keyboard up', (
      WidgetTester tester,
    ) async {
      await openOnAPhone(tester);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
    });
  });

  group('the confirm button', () {
    /// The fill the button is actually painted with, once the change between
    /// its two states has finished travelling.
    LinearGradient fill(WidgetTester tester) {
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(PrimaryButton),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).gradient != null,
          ),
        ),
      );
      return (box.decoration as BoxDecoration).gradient! as LinearGradient;
    }

    Color labelColour(WidgetTester tester) =>
        tester.widget<Text>(find.text('Create folder')).style!.color!;

    VoidCallback? handler(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed;

    final AppPalette palette = testPalette(Brightness.dark);

    testWidgets('is off until the folder has a name', (
      WidgetTester tester,
    ) async {
      // The refusal was always there — `_save` returns on an empty name — and
      // it was invisible: the button looked exactly as it does when it works,
      // so pressing it did nothing and explained nothing.
      await openSheet(tester);

      expect(handler(tester), isNull);
      expect(fill(tester).colors.first, palette.surfaceVariant);
      expect(labelColour(tester), palette.textDisabled);
    });

    testWidgets('lights up on the first character', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(nameField, 'R');
      await tester.pumpAndSettle();

      expect(handler(tester), isNotNull);
      expect(fill(tester).colors.first, palette.primary);
      expect(labelColour(tester), palette.onPrimary);
    });

    testWidgets('goes off again if the name is taken back', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(nameField, 'Recipes');
      await tester.pumpAndSettle();

      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      expect(handler(tester), isNull);
      expect(fill(tester).colors.first, palette.surfaceVariant);
    });

    testWidgets('spaces alone do not light it', (WidgetTester tester) async {
      // The name is trimmed on its way into the preview, so the button is
      // reading the same string the save handler would refuse.
      await openSheet(tester);

      await tester.enterText(nameField, '    ');
      await tester.pumpAndSettle();

      expect(handler(tester), isNull);
    });

    testWidgets('editing a folder opens with it already lit', (
      WidgetTester tester,
    ) async {
      // It arrives with a name, so there is nothing to wait for.
      await openSheet(
        tester,
        existing: FolderEntity(
          id: 3,
          name: 'Recipes',
          color: 0xFFF5883C,
          createdAt: DateTime(2026),
        ),
      );

      expect(handler(tester), isNotNull);
      expect(fill(tester).colors.first, palette.primary);
    });
  });

  group('naming', () {
    testWidgets('a folder with no name is not made', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await submit(tester);

      expect(saved, isNull);
      // And the sheet is still there, because there is nothing else it could
      // do — dismissing on a refusal would look like the folder was made.
      expect(nameField, findsOneWidget);
    });

    testWidgets('a name of only spaces is no name at all', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(nameField, '     ');
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved, isNull);
      expect(nameField, findsOneWidget);
    });

    testWidgets('the name is trimmed before it is handed over', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      await tester.enterText(nameField, '  Recipes  ');
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved?.name, 'Recipes');
    });

    testWidgets('the name cannot exceed the cap the card is built for', (
      WidgetTester tester,
    ) async {
      // 32, and the cap exists for the places the name is quoted — the Quick
      // Save button, a chip in a strip — rather than for the database.
      await openSheet(tester);

      await tester.enterText(nameField, 'x' * 60);
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved?.name.length, kMaxFolderNameLength);
    });

    testWidgets('the preview carries the name as it is typed', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);

      // Before anything is typed the card shows the field's own label, so the
      // preview is never a blank pocket.
      expect(find.text('Folder name'), findsOneWidget);

      await tester.enterText(nameField, 'Boarding passes');
      await tester.pumpAndSettle();

      expect(find.text('Boarding passes'), findsWidgets);
      expect(find.text('Folder name'), findsNothing);
    });
  });

  group('making one', () {
    testWidgets(
      'the defaults are the first colour, the first glyph, unlocked',
      (WidgetTester tester) async {
        await openSheet(tester);

        await tester.enterText(nameField, 'Recipes');
        await tester.pumpAndSettle();
        await submit(tester);

        expect(saved?.color, kFolderColors.first);
        expect(saved?.iconKey, FolderIcons.keys.first);
        expect(saved?.isPrivate, isFalse);
      },
    );

    testWidgets('a chosen colour is the one that is saved', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(nameField, 'Recipes');
      await tester.pumpAndSettle();

      await tester.tap(swatch(kFolderColors[1]));
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved?.color, kFolderColors[1]);
    });

    testWidgets('a chosen glyph is the one that is saved', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(nameField, 'Favourites');
      await tester.pumpAndSettle();

      // The picker is below roughly 500dp of fixed content, so it is scrolled
      // to the way a user reaches it. Dragging also puts the keyboard away,
      // which is the point of `onDrag` on that scroll view.
      await tester.dragUntilVisible(
        find.byIcon(Icons.star_rounded),
        find.byType(CustomScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.star_rounded));
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved?.iconKey, 'star');
    });

    testWidgets('the lock is offered, and carried when it is set', (
      WidgetTester tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(nameField, 'Bank');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lock_open_rounded));
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved?.isPrivate, isTrue);
    });

    testWidgets('the sheet is gone by the time the folder is made', (
      WidgetTester tester,
    ) async {
      // Dismiss first, write after: the tallest sheet in the app is sliding a
      // phone's height off screen, and the database write plus the grid
      // rebuild must not land on those frames.
      await openSheet(tester);

      await tester.enterText(nameField, 'Recipes');
      await tester.pumpAndSettle();
      await submit(tester);

      expect(find.byType(TextField), findsNothing);
      expect(saved, isNotNull);
    });
  });

  group('editing one', () {
    FolderEntity existing({
      String name = 'Recipes',
      int color = 0xFFF5883C,
      String? iconKey = 'food',
      bool isPrivate = false,
    }) => FolderEntity(
      id: 3,
      name: name,
      color: color,
      createdAt: DateTime(2026),
      screenshotCount: 8,
      isPrivate: isPrivate,
      iconKey: iconKey,
    );

    testWidgets('it opens on the folder rather than on the defaults', (
      WidgetTester tester,
    ) async {
      await openSheet(tester, existing: existing());

      expect(find.text('Edit folder'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(tester.widget<TextField>(nameField).controller?.text, 'Recipes');
    });

    testWidgets('saving without touching anything changes nothing', (
      WidgetTester tester,
    ) async {
      // The failure this guards against is silent: an editor that starts from
      // the defaults instead of from the folder re-colours and re-draws a
      // folder somebody only opened to rename.
      await openSheet(tester, existing: existing());

      await submit(tester);

      expect(saved?.name, 'Recipes');
      expect(saved?.color, 0xFFF5883C);
      expect(saved?.iconKey, 'food');
    });

    testWidgets('the lock is not on this sheet', (WidgetTester tester) async {
      // Turning it *off* is a removal of protection and should cost a
      // fingerprint; quietly putting the switch here would be doing that
      // badly. Neither state of the row may appear.
      await openSheet(tester, existing: existing(isPrivate: true));

      expect(find.byIcon(Icons.lock_open_rounded), findsNothing);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('a colour no longer offered is kept, not silently replaced', (
      WidgetTester tester,
    ) async {
      // `kFolderColors` has been edited twice — a clay and two blues have come
      // and gone. A folder tagged with a retired colour must survive being
      // renamed, so the editor has to start from the saved value even when no
      // swatch matches it.
      const int retiredClay = 0xFFB08968;
      expect(kFolderColors, isNot(contains(retiredClay)));

      await openSheet(tester, existing: existing(color: retiredClay));
      await submit(tester);

      expect(saved?.color, retiredClay);
    });

    testWidgets('a folder that never had a glyph is given the plain one', (
      WidgetTester tester,
    ) async {
      // Folders made before the icon column existed carry no key. The editor
      // cannot show "no selection", so it starts on the first key — which is
      // 'folder', the same picture those folders were already drawn with. The
      // stored value changes; what the user sees does not.
      await openSheet(tester, existing: existing(iconKey: null));

      await submit(tester);

      expect(saved?.iconKey, FolderIcons.keys.first);
      expect(FolderIcons.resolve(saved?.iconKey), FolderIcons.fallback);
    });

    testWidgets('clearing the name refuses to save the folder', (
      WidgetTester tester,
    ) async {
      // The one way an existing folder could be left nameless.
      await openSheet(tester, existing: existing());

      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();
      await submit(tester);

      expect(saved, isNull);
      expect(find.text('Edit folder'), findsOneWidget);
    });
  });
}
