import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders the accent doing every job it actually has, in both modes.
///
/// A palette change is exactly the kind of edit an assertion cannot review:
/// the question is never "is the hex right", it is "can you still read the
/// label on the button". Running with `--update-goldens` writes real PNGs,
/// which is the only honest way to check that without a device.
///
/// It is not a regression gate — there is no committed baseline — so it never
/// fails a normal `flutter test` run.
void main() {
  Future<void> renderBoard(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    final AppTypography type = testTypography(brightness);
    final AppPalette palette = testPalette(brightness);

    tester.view.physicalSize = const Size(1080, 1500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          theme: testTheme(brightness),
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: palette.background,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  Text('SHOTO', style: type.displayLarge),
                  Text(
                    'The accent, doing every job it has',
                    style: type.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // The most exposed pairing in the app: accent fill carrying
                  // a label. If anything is going to be unreadable it is this.
                  PrimaryButton(label: 'Filed', onPressed: () {}),
                  const SizedBox(height: 16),

                  // Selected vs unselected, side by side — the accent's real
                  // job is telling those two apart at a glance. Drawn here
                  // rather than pulled in from the library screen so the board
                  // stays about colour and needs no bloc, locale or locator.
                  const Row(
                    children: [
                      _Pill(label: 'All  128', isActive: true),
                      SizedBox(width: 8),
                      _Pill(label: 'Favorites', isActive: false),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // The three hues that survived, so it is visible whether
                  // they now shout next to a colourless accent.
                  Wrap(
                    spacing: 4,
                    runSpacing: 8,
                    children: [
                      _Dot(color: palette.primary, label: 'accent'),
                      _Dot(color: palette.secondary, label: 'move'),
                      _Dot(color: palette.success, label: 'done'),
                      _Dot(color: palette.alert, label: 'delete'),
                      const _Dot(color: AppPalette.graphite, label: 'muted'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // A tinted wash and a tinted border — the accent at 8% and
                  // 25%, which is how half the app uses it.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: palette.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      'A tinted panel, the way rules and quick save draw one.',
                      style: type.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Surface steps, so the accent can be judged against what it
                  // actually sits on rather than against the canvas alone.
                  for (final (Color c, String name) in <(Color, String)>[
                    (palette.surface, 'surface'),
                    (palette.surfaceVariant, 'surfaceVariant'),
                    (palette.surfaceElevated, 'surfaceElevated'),
                  ])
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Text(name, style: type.bodyMedium),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'PRO',
                              style: type.caption.copyWith(
                                color: palette.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('palette — light', (WidgetTester tester) async {
    await renderBoard(tester, Brightness.light);
    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('goldens/palette_light.png'),
    );
  }, skip: !autoUpdateGoldenFiles);

  testWidgets('palette — dark', (WidgetTester tester) async {
    await renderBoard(tester, Brightness.dark);
    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('goldens/palette_dark.png'),
    );
  }, skip: !autoUpdateGoldenFiles);
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isActive;

  const _Pill({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isActive ? Colors.transparent : context.colors.border,
        ),
      ),
      child: Text(
        label,
        style: context.text.bodySmall.copyWith(
          color: isActive
              ? context.colors.onPrimary
              : context.colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;

  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Text(label, style: context.text.caption),
        ],
      ),
    );
  }
}
