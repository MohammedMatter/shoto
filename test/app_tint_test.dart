import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_tint.dart';

/// **The contract behind the accent picker, checked rather than asserted in
/// prose.**
///
/// `app_colors.dart` spends several hundred lines establishing that every hue
/// in this app is solved against a luminance target, and `app_tint.dart`
/// claims to extend that to eight colours a user can choose. That claim is
/// only worth anything if something checks it: the failure it prevents — a
/// bright accent carrying near-white text — is invisible in light mode, which
/// is the mode this kind of thing gets looked at in.
/// How far apart two colours are, in the units they are actually stored in.
///
/// **Not `((a.r - b.r) * 255).abs()`**, which is the obvious way to write this
/// and reports `1.0000000000000107` for two colours one step apart: `Color`
/// holds its channels as doubles, and neither `168/255` nor the arithmetic
/// that produced it is exact in binary. That overshoot failed a `<= 1` bound
/// on a pair of colours that were, by any meaning of the word, identical to
/// within one step.
///
/// Rounding to the eight bits each channel is written to first makes the
/// comparison exact, and asks the question that actually matters: will these
/// two paint the same pixel, or one value apart?
int _stepsApart(Color a, Color b) {
  int channel(double x, double y) => ((x * 255).round() - (y * 255).round()).abs();
  return <int>[
    channel(a.r, b.r),
    channel(a.g, b.g),
    channel(a.b, b.b),
  ].reduce((int x, int y) => x > y ? x : y);
}

void main() {
  /// WCAG contrast between two colours.
  double contrast(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  group('every tint is solved, not picked', () {
    // The two values the palette already ships, which the solver has to
    // reproduce for the rest of its output to mean anything.
    test('teal reproduces the shipped accent to within one step', () {
      final Color light = AppTint.teal.accent(isDark: false);
      final Color dark = AppTint.teal.accent(isDark: true);

      // Not an exact equality: the shipped values were arrived at by hand in
      // hex, and the solver arrives at them from the luminance definition, so
      // agreement to a single 8-bit step is the strongest honest claim. It is
      // also a far better test than equality would be — equality could be
      // satisfied by hard-coding, and this cannot.
      expect(
        _stepsApart(light, AppPalette.light.marker),
        lessThanOrEqualTo(1),
        reason: 'the light accent drifted from the shipped one',
      );
      expect(
        _stepsApart(dark, AppPalette.dark.marker),
        lessThanOrEqualTo(1),
        reason: 'the dark accent drifted from the shipped one',
      );
    });

    test('slate reproduces the palette secondary it was named after', () {
      // `app_colors.dart` documents `secondary` as "hsl(216, 43%, 35%)", and
      // AppTint.slate is declared as hue 216 at 43%. Two files agreeing is
      // worth one test.
      expect(
        _stepsApart(
          AppTint.slate.accent(isDark: false),
          AppPalette.light.secondary,
        ),
        lessThanOrEqualTo(1),
      );
    });

    test('all eight land on the same luminance in each mode', () {
      for (final AppTint tint in AppTint.all) {
        // The tolerance is one 8-bit step's worth of luminance, not a
        // percentage: the solver is exact and the only error left is the
        // rounding to a channel value.
        expect(
          tint.accent(isDark: false).computeLuminance(),
          closeTo(AppPalette.light.marker.computeLuminance(), 0.004),
          reason: '${tint.id} light',
        );
        expect(
          tint.accent(isDark: true).computeLuminance(),
          closeTo(AppPalette.dark.marker.computeLuminance(), 0.004),
          reason: '${tint.id} dark',
        );
      }
    });

    test('the hand-written colour maths matches the framework', () {
      // `AppTint` writes out its own HSL conversion and its own luminance
      // rather than calling `HSLColor` and `computeLuminance`, because the
      // search runs both forty times per solve. That is only safe while the
      // two implementations agree.
      //
      // So the same problem is solved twice: once by the code under test, and
      // once here by a bisection built entirely on the framework's versions.
      // Every tint, both modes, both targets. If the private maths had drifted
      // — a wrong sector in the hue wheel, the sRGB knee at the wrong place —
      // the two answers would part company.
      for (final AppTint tint in AppTint.all) {
        for (final bool isDark in <bool>[false, true]) {
          final _TintProbe probe = _TintProbe(
            hue: tint.hue,
            saturation: isDark ? tint.saturationDark : tint.saturationLight,
          );
          // The targets are private, and they do not need to be public: they
          // are by definition the luminance of the shipped accent and variant,
          // which are readable right here.
          final AppPalette shipped = isDark ? AppPalette.dark : AppPalette.light;

          for (final (String role, Color ours, Color theirs) in <(
            String,
            Color,
            Color,
          )>[
            (
              'accent',
              tint.accent(isDark: isDark),
              probe.solve(shipped.marker.computeLuminance()),
            ),
            (
              'variant',
              tint.variant(isDark: isDark),
              probe.solve(shipped.primaryVariant.computeLuminance()),
            ),
          ]) {
            expect(
              _stepsApart(ours, theirs),
              lessThanOrEqualTo(1),
              reason: '${tint.id} ${isDark ? 'dark' : 'light'} $role',
            );
          }
        }
      }
    });
  });

  group('every tint survives every surface it lands on', () {
    // 4.5:1 is the AA floor for body text, and the accent is used as text —
    // an active label, a link, a checkmark, roughly forty call sites — not
    // only as a fill.
    const double aa = 4.5;

    test('as text, on every surface of its own mode', () {
      for (final AppTint tint in AppTint.all) {
        for (final bool isDark in <bool>[false, true]) {
          final AppPalette palette = AppPalette.tinted(tint, isDark: isDark);
          final Color accent = palette.primary;

          for (final (String name, Color surface) in <(String, Color)>[
            ('background', palette.background),
            ('surface', palette.surface),
            // The tightest one the accent ever lands on, and the value the
            // dark target was chosen from in the first place.
            ('surfaceVariant', palette.surfaceVariant),
          ]) {
            expect(
              contrast(accent, surface),
              greaterThanOrEqualTo(aa),
              reason:
                  '${tint.id} ${isDark ? 'dark' : 'light'} on $name '
                  'measured ${contrast(accent, surface).toStringAsFixed(2)}',
            );
          }
        }
      }
    });

    test('as a fill, carrying the palette\'s one foreground', () {
      // The whole reason the tints are solved rather than picked: one
      // `onPrimary` has to be correct on all eight of them. This is the test
      // that a raw-hex picker fails — white on a saturated yellow measures
      // about 1.4:1.
      for (final AppTint tint in AppTint.all) {
        for (final bool isDark in <bool>[false, true]) {
          final AppPalette palette = AppPalette.tinted(tint, isDark: isDark);
          expect(
            contrast(palette.onPrimary, palette.primary),
            greaterThanOrEqualTo(aa),
            reason: '${tint.id} ${isDark ? 'dark' : 'light'} fill',
          );
        }
      }
    });

    test('the pressed variant stays darker than the accent, and keeps hue', () {
      for (final AppTint tint in AppTint.all) {
        for (final bool isDark in <bool>[false, true]) {
          final AppPalette palette = AppPalette.tinted(tint, isDark: isDark);
          expect(
            palette.primaryVariant.computeLuminance(),
            lessThan(palette.primary.computeLuminance()),
            reason: '${tint.id} variant must be a step down, not up',
          );
          // A blend toward black would have gone grey; solving at a lower
          // target keeps the chroma. Checked as "not achromatic" rather than
          // by hue, which is the property that actually matters.
          final Color variant = palette.primaryVariant;
          final double spread =
              <double>[
                variant.r,
                variant.g,
                variant.b,
              ].reduce((double a, double b) => a > b ? a : b) -
              <double>[
                variant.r,
                variant.g,
                variant.b,
              ].reduce((double a, double b) => a < b ? a : b);
          expect(
            spread,
            greaterThan(0.02),
            reason: '${tint.id} variant went grey',
          );
        }
      }
    });
  });

  group('the palette cache', () {
    test('the default tint returns the const palettes untouched', () {
      // `theme_const_rebuild_test.dart` depends on this identity, and so does
      // every unchanged frame in the app: a new instance here would make
      // ThemeData compare unequal on every rebuild.
      expect(
        identical(AppPalette.tinted(AppTint.teal, isDark: false),
            AppPalette.light),
        isTrue,
      );
      expect(
        identical(AppPalette.tinted(AppTint.teal, isDark: true),
            AppPalette.dark),
        isTrue,
      );
    });

    test('a tinted palette is the same instance every time', () {
      expect(
        identical(
          AppPalette.tinted(AppTint.plum, isDark: true),
          AppPalette.tinted(AppTint.plum, isDark: true),
        ),
        isTrue,
        reason: 'without this every rebuild repaints the whole app',
      );
      expect(
        identical(
          AppPalette.tinted(AppTint.plum, isDark: true),
          AppPalette.tinted(AppTint.plum, isDark: false),
        ),
        isFalse,
        reason: 'the two modes are different colours and must not share a key',
      );
    });

    test('only the accent moves', () {
      final AppPalette base = AppPalette.dark;
      final AppPalette tinted = AppPalette.tinted(AppTint.amber, isDark: true);

      // A user choosing amber has not asked for an amber error state. The
      // semantic hues, the neutrals and the secondary all stay exactly where
      // they were.
      expect(tinted.alert, base.alert);
      expect(tinted.success, base.success);
      expect(tinted.warning, base.warning);
      expect(tinted.secondary, base.secondary);
      expect(tinted.background, base.background);
      expect(tinted.surface, base.surface);
      expect(tinted.textPrimary, base.textPrimary);
      expect(tinted.onPrimary, base.onPrimary);
      expect(tinted.primary, isNot(base.primary));
    });
  });

  group('an unknown id never breaks the first frame', () {
    test('falls back rather than throwing', () {
      // An id dropped in a later version is still sitting in somebody's
      // preferences; the app has to open in a colour rather than crash.
      expect(AppTint.byId(null), AppTint.fallback);
      expect(AppTint.byId('chartreuse'), AppTint.fallback);
      expect(AppTint.byId(''), AppTint.fallback);
    });

    test('every shipped id round-trips', () {
      for (final AppTint tint in AppTint.all) {
        expect(AppTint.byId(tint.id), tint);
      }
    });

    test('the ids are unique', () {
      final Set<String> ids = AppTint.all.map((AppTint t) => t.id).toSet();
      expect(ids.length, AppTint.all.length);
    });
  });
}

/// The same search as [AppTint], written entirely in framework calls.
///
/// This is a *second implementation*, not a helper — it exists to disagree
/// with the first one if the first one is wrong. Where `AppTint` converts HSL
/// and computes luminance by hand for speed, this asks `HSLColor` and
/// `Color.computeLuminance` for both, so the only thing the two share is the
/// bisection itself and the targets they are pointed at.
class _TintProbe {
  final double hue;
  final double saturation;

  const _TintProbe({required this.hue, required this.saturation});

  Color solve(double targetLuminance) {
    // Bisection, mirroring the one under test, but built entirely on the
    // framework's own HSL and luminance. If the two implementations agree on
    // every hue, saturation and lightness sampled above, the hand-written one
    // is a faithful copy.
    double low = 0;
    double high = 1;
    for (int i = 0; i < 40; i++) {
      final double mid = (low + high) / 2;
      final double luminance = HSLColor.fromAHSL(1, hue, saturation, mid)
          .toColor()
          .computeLuminance();
      if (luminance < targetLuminance) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return HSLColor.fromAHSL(1, hue, saturation, (low + high) / 2).toColor();
  }
}
