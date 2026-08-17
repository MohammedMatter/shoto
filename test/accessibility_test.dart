import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/features/screenshots/presentation/widgets/screenshot_thumbnail.dart';

/// What a screen reader is told.
///
/// The app had no semantics of its own at all — no `Semantics`, no
/// `semanticLabel`, and a tap primitive built on a bare `GestureDetector`,
/// which contributes the tap *action* and neither a role nor a name. So every
/// control in the app was an anonymous node, and the icon-only ones announced
/// nothing whatsoever.
///
/// These are the two claims worth pinning: a control says what it is, and a
/// picture says which picture it is.
void main() {
  Widget wrap(Widget child) => ScreenUtilInit(
    designSize: const Size(360, 690),
    builder: (context, _) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('PressableScale', () {
    testWidgets('announces itself as a button, by name', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          PressableScale(
            semanticLabel: 'Find duplicates',
            onTap: () {},
            child: const Icon(Icons.copy_all_rounded),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PressableScale)),
        matchesSemantics(
          label: 'Find duplicates',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('carries the selected state when it is one of a set', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          PressableScale(
            semanticLabel: 'Teal',
            selected: true,
            onTap: () {},
            child: const SizedBox.square(dimension: 40),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(PressableScale)),
        matchesSemantics(
          label: 'Teal',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('adds nothing when it is only wrapping decoration', (
      tester,
    ) async {
      // A PressableScale with no tap and no label is not a control, and an
      // empty node in the tree is one more thing to swipe past.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(const PressableScale(child: Text('Just words'))),
      );

      expect(
        tester.getSemantics(find.text('Just words')),
        matchesSemantics(label: 'Just words'),
      );

      handle.dispose();
    });
  });

  group('a screenshot in the grid', () {
    AssetEntity asset(DateTime taken) => AssetEntity(
      id: '1',
      typeInt: AssetType.image.index,
      width: 1080,
      height: 2340,
      createDateSecond: taken.millisecondsSinceEpoch ~/ 1000,
    );

    testWidgets('is named by the day it was taken', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          SizedBox.square(
            dimension: 120,
            child: ScreenshotThumbnail(
              asset: asset(DateTime(2026, 3, 14)),
              isFavorite: false,
              isSelected: false,
              selectionMode: false,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      // The tile's entrance animations hold timers; let them finish or the
      // binding complains at teardown rather than about anything under test.
      await tester.pump(const Duration(milliseconds: 600));

      final SemanticsNode node = tester.getSemantics(
        find.byType(ScreenshotThumbnail),
      );
      expect(node.label, contains('Screenshot'));
      // The year in particular: a library holds several, and two tiles twelve
      // months apart must not be announced identically.
      expect(node.label, contains('2026'));
      expect(node.label, contains('March 14'));

      handle.dispose();
    });

    testWidgets('says so when it is a favourite', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          SizedBox.square(
            dimension: 120,
            child: ScreenshotThumbnail(
              asset: asset(DateTime(2026, 3, 14)),
              isFavorite: true,
              isSelected: false,
              selectionMode: false,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(ScreenshotThumbnail)).label,
        contains('favorite'),
      );

      handle.dispose();
    });

    testWidgets('claims a selected state only while choosing', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      Widget tile({required bool selectionMode}) => SizedBox.square(
        dimension: 120,
        child: ScreenshotThumbnail(
          asset: asset(DateTime(2026, 3, 14)),
          isFavorite: false,
          isSelected: false,
          selectionMode: selectionMode,
          onTap: () {},
          onLongPress: () {},
        ),
      );

      // `Tristate.none` is the engine's way of saying the node claims no
      // selected state at all, which is the distinction under test — not
      // "selected" versus "not selected", but "a choice" versus "not one".
      await tester.pumpWidget(wrap(tile(selectionMode: false)));
      expect(
        tester
            .getSemantics(find.byType(ScreenshotThumbnail))
            .flagsCollection
            .isSelected,
        Tristate.none,
        reason: 'a library being browsed is not a set of choices',
      );

      await tester.pumpWidget(wrap(tile(selectionMode: true)));
      expect(
        tester
            .getSemantics(find.byType(ScreenshotThumbnail))
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
        reason: 'in selection mode an unpicked tile is a choice not yet made',
      );

      handle.dispose();
    });
  });
}
