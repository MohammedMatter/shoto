import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/cache_service.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/widgets/app_switch.dart';
import 'package:shoto/core/widgets/pro_badge.dart';

/// The glyph at the head of a settings row.
///
/// **One tone for all seventeen, and this is the second attempt at that.**
///
/// The first attempt gave every row a hue off the [AppTint] wheel on a pale
/// plate — sixteen colours walking the wheel down the page, each one solved and
/// contrast-checked by machinery the app already had. Every individual piece of
/// that was defensible and the whole thing was wrong, which is the same lesson
/// `app_colors.dart` records about the paywall card: *a component can obey
/// every token in the system and still be the wrong thing to put on the
/// screen.* Seventeen coloured squares do not read as an index. They read as
/// decoration applied to a list, and decoration applied evenly to every item in
/// a list carries no information at all — if everything is marked, nothing is.
///
/// It also broke the rule that actually matters here, which is not about
/// contrast: **colour in this app means something.** Red is destructive, green
/// is done, amber is attention. Spending the whole wheel on "this is the
/// haptics row" spends the vocabulary on nothing and leaves the four hues that
/// do mean something competing with sixteen that do not.
///
/// So the glyphs are quiet, and the work they were being asked to do — telling
/// one row from another at a glance — is done by the two things that were
/// always better at it: **shorter rows, and headings with air above them.**
/// [AppPalette.textSecondary] rather than `textPrimary`, so the glyph sits a
/// step behind the label it belongs to instead of competing with it.
class SettingsGlyph extends StatelessWidget {
  final IconData icon;

  /// Overrides the tone — the alert red on a destructive row, the disabled
  /// grey on one that cannot be tapped.
  final Color? tone;

  const SettingsGlyph({super.key, required this.icon, this.tone});

  /// The column the glyph occupies. Fixed rather than measured, so every row's
  /// text starts in the same place whatever glyph is in it.
  static double get size => 22.w;

  /// Where a row's text begins, measured from the edge of the group's card.
  /// Read by [SettingsDivider] so the hairline starts where the labels do
  /// rather than at a number copied by hand and left behind.
  static double get textInset => 16.w + size + 14.w;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    child: Icon(icon, size: 20.sp, color: tone ?? context.colors.textSecondary),
  );
}

/// The shape every row on this page is: a glyph, a label, and the answer on
/// the trailing edge.
///
/// Private and shared rather than copied into the two public tiles below,
/// because the one thing a settings page cannot survive is its rows disagreeing
/// about their own metrics — a switch row two pixels taller than the nav row
/// above it is the sort of wrongness nobody can name and everybody feels.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? glyphTone;
  final String label;
  final Color labelColor;

  /// The line under the label.
  ///
  /// **Most rows no longer have one.** Every row on this page used to carry a
  /// sentence, which turned Settings into seventeen paragraphs stacked on top
  /// of each other — twice the height it needed and nothing on it leading. A
  /// description now has to earn its line by saying something the label does
  /// not: what a switch will actually change, or a fact like an address or a
  /// size. "Watch the opening sequence again" under "Replay the introduction"
  /// is not information, it is the label written twice.
  final String? description;

  /// **The row's current answer, on the trailing edge.**
  ///
  /// A setting that already has a value should say it where the eye goes
  /// looking for it, which is the same place a switch would be — so a row can
  /// be read without being opened. Putting it in [description] instead is what
  /// made "Language" a two-line row to hold one word.
  final String? value;

  final List<Widget> trailing;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.labelColor,
    this.glyphTone,
    this.description,
    this.value,
    this.trailing = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // **A floor rather than a fixed height.** The rows are deliberately no
      // longer all the same height — some have a second line and most do not —
      // and without a minimum the one-line ones collapse to something too
      // small to hit comfortably, which is the price a page usually pays for
      // being tightened.
      constraints: BoxConstraints(minHeight: 56.h),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: <Widget>[
            SettingsGlyph(icon: icon, tone: glyphTone),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    // A half step of weight on the label, and none on the line
                    // under it. That is the whole hierarchy of a row: with both
                    // at the same weight the eye has to read the sentence to
                    // find out it was not the title.
                    style: context.text.bodyLarge.asMedium.copyWith(
                      color: labelColor,
                    ),
                  ),
                  if (description != null) ...<Widget>[
                    SizedBox(height: 2.h),
                    Text(description!, style: context.text.caption),
                  ],
                ],
              ),
            ),
            if (value != null) ...<Widget>[
              SizedBox(width: 12.w),
              // Bounded so a long answer — a language endonym, a formatted
              // size — ellipsises instead of pushing the chevron off the card.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 130.w),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: context.text.bodyMedium,
                ),
              ),
            ],
            for (final Widget widget in trailing) ...<Widget>[
              SizedBox(width: 10.w),
              widget,
            ],
          ],
        ),
      ),
    );
  }
}

/// The cache row, which has to measure before it can label itself.
class SettingsClearCacheTile extends StatefulWidget {
  const SettingsClearCacheTile({super.key});

  @override
  State<SettingsClearCacheTile> createState() => _SettingsClearCacheTileState();
}

class _SettingsClearCacheTileState extends State<SettingsClearCacheTile> {
  late Future<int> _sizeFuture = sl<CacheService>().getCacheSizeBytes();

  Future<void> _clear() async {
    await sl<CacheService>().clearCache();
    if (!mounted) return;
    // Block body, not an arrow: an arrow returns the assigned value, which
    // here is a Future, and Flutter asserts that a setState callback never
    // returns one. Same mistake that used to crash the Upgrade button.
    setState(() {
      _sizeFuture = sl<CacheService>().getCacheSizeBytes();
    });
  }

  /// A size, wrapped so it survives being dropped into an Arabic sentence.
  ///
  /// Without the isolate this renders **"MB 6.1"** on an RTL screen, which is
  /// not a size. The reason is the bidi algorithm and not the translation: in
  /// an RTL paragraph, `6.1` resolves as a weak left-to-right number and `MB`
  /// as strong left-to-right text, and the neutral space between them takes
  /// the *paragraph's* direction rather than theirs. That splits one value
  /// into two runs and lays them out right to left.
  ///
  /// U+2066 (left-to-right isolate) and U+2069 (pop directional isolate) fence
  /// the whole thing off as one left-to-right run, so the number keeps its
  /// unit and the Arabic around it keeps its own direction. Any measurement
  /// with a unit needs this — see also the format strings in `app_ar.arb`.
  String _format(int bytes) {
    final String value;
    if (bytes < 1024) {
      value = '$bytes B';
    } else if (bytes < 1024 * 1024) {
      value = '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      value = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '\u2066$value\u2069';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _sizeFuture,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int bytes = snapshot.data ?? 0;
        return SettingsNavTile(
          icon: Icons.cleaning_services_outlined,
          label: context.l10n.settingsClearCache,
          // **The size is the answer, so it goes where the answers go** — and
          // the sentence that used to carry it ("12.4 MB of thumbnails") goes
          // with it, because a row that says the same number twice reads as a
          // rendering fault rather than as emphasis.
          value: snapshot.hasData
              ? _format(bytes)
              : context.l10n.settingsCacheMeasuring,
          onTap: bytes == 0 ? null : _clear,
        );
      },
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;

  /// What this setting currently says, drawn on the trailing edge — see
  /// [_SettingsRow.value].
  final String? value;

  final VoidCallback? onTap;
  final bool isDestructive;

  /// Whether to mark this row with the PRO tag.
  ///
  /// Named for what it *does* rather than for what the feature is, because the
  /// answer is not a property of the row: it is "this is a paid feature **and**
  /// you have not paid yet". A subscriber's own settings page labelling the
  /// things they just bought as locked is the bug this spells out.
  ///
  /// Decided by the page and passed down, deliberately. Having the row work it
  /// out for itself meant every tile reaching into the service locator for
  /// [ProStatus], which turned a plain presentational widget into one that
  /// could not be built in a widget test at all.
  final bool showProBadge;

  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.description,
    this.value,
    this.isDestructive = false,
    this.showProBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null && !isDestructive;
    final Color tone = isDestructive
        ? context.colors.error
        : disabled
        ? context.colors.textDisabled
        : context.colors.textPrimary;

    return PressableScale(
      // A tint, not a shrink. This row is full-bleed inside a scrolling page,
      // and a full-width row that scales makes the whole page look like it
      // shuddered every time a finger rests on it before dragging. See
      // PressFeedback.
      feedback: PressFeedback.highlight,
      onTap: onTap,
      child: _SettingsRow(
        icon: icon,
        // The glyph follows the label only where the label has left the
        // ordinary case — red on a destructive row, grey on a dead one.
        // Everywhere else it stays a step behind, which is the whole point of
        // it being one tone.
        glyphTone: isDestructive || disabled ? tone : null,
        label: label,
        labelColor: tone,
        description: description,
        value: value,
        trailing: <Widget>[
          if (showProBadge) const ProBadge(),
          if (onTap != null && !isDestructive)
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textDisabled,
              size: 20.sp,
            ),
        ],
      ),
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      icon: icon,
      label: label,
      labelColor: context.colors.textPrimary,
      description: description,
      trailing: <Widget>[AppSwitch(value: value, onChanged: onChanged)],
    );
  }
}
