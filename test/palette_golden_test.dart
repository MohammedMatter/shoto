import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_shapes.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/primary_button.dart';

import 'support/test_fonts.dart';
import 'support/test_theme.dart';

/// Renders the whole colour system doing every job it actually has, in both
/// modes: type hierarchy, button hierarchy, status hues, inputs, interaction
/// states and the surface steps.
///
/// A palette change is exactly the kind of edit an assertion cannot review:
/// the question is never "is the hex right", it is "can you still read the
/// label on the button", and "does the warning still look like a warning next
/// to the accent". `--update-goldens` writes real PNGs, which is the only
/// honest way to check that without a device.
///
/// **It is a regression gate.** An earlier version of this comment claimed
/// there was no committed baseline and that it could never fail a normal run;
/// both halves were wrong, and the baselines are in `goldens/`. Regenerate it
/// deliberately after a palette change and then *look at the PNG* — a golden
/// that passes after being regenerated has proven nothing at all.
void main() {
  Future<void> renderBoard(WidgetTester tester, Brightness brightness) async {
    await loadTestFonts();
    final AppTypography type = testTypography(brightness);
    final AppPalette palette = testPalette(brightness);

    tester.view.physicalSize = const Size(1080, 3100);
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
                  Text('Shoto', style: type.displayLarge),
                  Text(
                    'The colour system, doing every job it has',
                    style: type.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // Type hierarchy first, because everything below is judged
                  // against it: a filled control must not out-weigh the words
                  // it supports, and that is only visible with the words next
                  // to it. `textSecondary` is the value that was under AA.
                  _Section(
                    'text',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Primary — the screenshot you filed on Tuesday',
                          style: type.bodyMedium.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                        Text(
                          'Secondary — 128 screenshots, 3 folders',
                          style: type.bodyMedium.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        Text(
                          'Disabled — nothing to sort',
                          style: type.bodyMedium.copyWith(
                            color: palette.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Button hierarchy. The point of the board: these five must
                  // rank at a glance, and the destructive one must not be the
                  // loudest thing on the screen.
                  _Section(
                    'buttons',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Btn(
                          'Primary',
                          fill: palette.primary,
                          fg: palette.onPrimary,
                        ),
                        _Btn(
                          'Secondary',
                          fill: palette.surfaceVariant,
                          fg: palette.textPrimary,
                          border: palette.border,
                        ),
                        _Btn('Text', fill: null, fg: palette.primary),
                        _Btn(
                          'Delete',
                          fill: palette.error,
                          fg: palette.onError,
                        ),
                        _Btn(
                          'Disabled',
                          fill: palette.disabledFill,
                          fg: palette.textDisabled,
                        ),
                      ],
                    ),
                  ),

                  // Status hues, each carrying its own foreground. They are
                  // solved to one luminance, so the test is whether any of
                  // them jumps out of the row — if one does, the family broke.
                  _Section(
                    'status',
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Btn(
                          'Filed',
                          fill: palette.success,
                          fg: palette.onSuccess,
                        ),
                        _Btn(
                          'Nearly full',
                          fill: palette.warning,
                          fg: palette.onWarning,
                        ),
                        _Btn(
                          'Failed',
                          fill: palette.error,
                          fg: palette.onError,
                        ),
                        _Btn(
                          'Moving',
                          fill: palette.info,
                          fg: palette.onPrimary,
                        ),
                      ],
                    ),
                  ),

                  // Inputs. The resting field is unchanged; the focused and
                  // error rings are new, and the whole reason they are here is
                  // that focus used to look identical to rest.
                  _Section(
                    'inputs',
                    Column(
                      children: [
                        _Field(
                          'Folder name',
                          fill: palette.surfaceVariant,
                          hint: palette.textDisabled,
                        ),
                        const SizedBox(height: 8),
                        _Field(
                          'Receipts',
                          fill: palette.surfaceVariant,
                          hint: palette.textPrimary,
                          ring: palette.focus,
                        ),
                        const SizedBox(height: 8),
                        _Field(
                          'Receipts',
                          fill: palette.surfaceVariant,
                          hint: palette.textPrimary,
                          ring: palette.error,
                          error: 'That name is already taken',
                          errorColor: palette.error,
                        ),
                      ],
                    ),
                  ),

                  // Interaction states, which are the ones a still image is
                  // otherwise the worst way to review — so they are drawn
                  // side by side against the surface they modify.
                  _Section(
                    'states',
                    Column(
                      children: [
                        _StateRow('Resting', palette.surface, palette),
                        _StateRow(
                          'Selected',
                          palette.surfaceSelected,
                          palette,
                          trailing: true,
                        ),
                        _StateRow(
                          'Pressed',
                          Color.alphaBlend(
                            palette.pressedOverlay,
                            palette.surface,
                          ),
                          palette,
                        ),
                      ],
                    ),
                  ),

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

                  // Every hue in the palette on one line. All five are solved
                  // to the same luminance, so they should read as a set rather
                  // than as a ranking — the previous teal failed exactly here,
                  // sitting a third brighter than everything beside it.
                  Wrap(
                    spacing: 4,
                    runSpacing: 8,
                    children: [
                      _Dot(color: palette.primary, label: 'accent'),
                      _Dot(color: palette.secondary, label: 'move'),
                      _Dot(color: palette.success, label: 'done'),
                      _Dot(color: palette.warning, label: 'careful'),
                      _Dot(color: palette.alert, label: 'delete'),
                      _Dot(color: palette.textSecondary, label: 'muted'),
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
  });

  testWidgets('palette — dark', (WidgetTester tester) async {
    await renderBoard(tester, Brightness.dark);
    await expectLater(
      find.byType(ListView),
      matchesGoldenFile('goldens/palette_dark.png'),
    );
  });
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

/// A labelled band, so the board reads as a specimen sheet rather than as a
/// screen — the sections are not a UI, they are the argument being checked.
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section(this.title, this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: context.text.overline.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color? fill;
  final Color fg;
  final Color? border;

  const _Btn(this.label, {required this.fill, required this.fg, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Text(label, style: context.text.button.copyWith(color: fg)),
    );
  }
}

class _Field extends StatelessWidget {
  final String text;
  final Color fill;
  final Color hint;
  final Color? ring;
  final String? error;
  final Color? errorColor;

  const _Field(
    this.text, {
    required this.fill,
    required this.hint,
    this.ring,
    this.error,
    this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: ring == null ? null : Border.all(color: ring!, width: 1.5),
          ),
          child: Text(
            text,
            style: context.text.bodyLarge.copyWith(color: hint),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: errorColor),
                const SizedBox(width: 5),
                Text(
                  error!,
                  style: context.text.caption.copyWith(color: errorColor),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StateRow extends StatelessWidget {
  final String label;
  final Color fill;
  final AppPalette palette;
  final bool trailing;

  const _StateRow(this.label, this.fill, this.palette, {this.trailing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: trailing ? palette.borderSelected : palette.border,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 18, color: palette.iconSecondary),
          const SizedBox(width: 10),
          Text(label, style: context.text.bodyMedium),
          const Spacer(),
          if (trailing)
            Icon(Icons.check_rounded, size: 18, color: palette.primary),
        ],
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
