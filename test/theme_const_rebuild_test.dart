import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/app_locales.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_theme.dart';

/// The regression gate for the bug that shipped twice.
///
/// The palette used to be static getters over a mutable brightness flag, and a
/// `const` widget is identical across rebuilds — so Flutter's reconciliation
/// skipped its subtree, its `build` never re-ran, and its colours stayed at
/// whatever mode was active when it was first inflated. Dark mode not
/// applying, a frozen theme after a hot reload and stale subtrees under a
/// rebuilt parent were all the same fault wearing different clothes. It is
/// also why `prefer_const_constructors` was off across 45k lines.
///
/// Reading through the theme is what fixes it: a widget that calls
/// `Theme.of(context)` becomes a dependent of an `InheritedWidget`, and a
/// dependent is rebuilt when that widget changes **whether or not it is
/// const**. This test asserts exactly that, with a `const` child deliberately
/// placed under a parent that does not change — the shape the old code got
/// wrong.
void main() {
  testWidgets('a const subtree follows a theme change', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
      ThemeMode.light,
    );
    addTearDown(mode.dispose);

    // ScreenUtilInit, because building the app's `ThemeData` means building
    // its `TextTheme`, and every size in that scale is a `.sp`.
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (BuildContext context, Widget? _) =>
            ValueListenableBuilder<ThemeMode>(
              valueListenable: mode,
              builder:
                  (BuildContext context, ThemeMode value, Widget? child) =>
                      MaterialApp(
                        theme: AppTheme.light(AppLanguage.english),
                        darkTheme: AppTheme.dark(AppLanguage.english),
                        themeMode: value,
                        // `child` is built outside this builder and handed
                        // back unchanged on every rebuild — the closest a test
                        // can get to the real thing, which is a const widget
                        // somewhere down a page.
                        home: child,
                      ),
              child: const _Swatch(),
            ),
      ),
    );

    Color painted() => tester
        .widget<ColoredBox>(find.byKey(const ValueKey<String>('swatch')))
        .color;
    Color? labelColour() => tester
        .widget<Text>(find.byKey(const ValueKey<String>('label')))
        .style
        ?.color;

    expect(painted(), AppPalette.light.background);
    expect(labelColour(), AppPalette.light.textPrimary);

    mode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    expect(
      painted(),
      AppPalette.dark.background,
      reason: 'a const subtree stopped following the palette',
    );
    expect(
      labelColour(),
      AppPalette.dark.textPrimary,
      reason: 'a const subtree stopped following the type scale',
    );
  });

  test('the two palettes are compile-time constants', () {
    // Not a formality. `const` is what lets one frame's ThemeData compare
    // equal to the next one's, so an unchanged theme notifies nobody — and it
    // is what makes `AppPalette.light` usable as a default in a const context.
    const AppPalette light = AppPalette.light;
    const AppPalette dark = AppPalette.dark;
    expect(identical(light, AppPalette.light), isTrue);
    expect(light.isDark, isFalse);
    expect(dark.isDark, isTrue);
    expect(light.background, isNot(dark.background));
  });
}

/// Const, with no key argument and nothing to rebuild it — if this repaints,
/// it is because the theme told it to.
class _Swatch extends StatelessWidget {
  const _Swatch();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey<String>('swatch'),
      color: context.colors.background,
      child: Text(
        'shoto',
        key: const ValueKey<String>('label'),
        style: context.text.bodyLarge,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
