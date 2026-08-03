import 'package:flutter/material.dart';
import 'package:shoto/core/theme/app_colors.dart';

/// The only switch in the app.
///
/// It exists because Material's defaults are actively wrong for this palette,
/// and because writing the correction by hand at each call site has already
/// failed once.
///
/// **What goes wrong.** The accent here is achromatic and inverts between
/// modes — near-black `#262626` on paper, bone `#EBEBEB` on near-black. A
/// [Switch] left to itself takes its active track from
/// `colorScheme.primary`, which `AppTheme` sets to exactly that accent. So a
/// call site that reaches for the accent to make the switch look "on" —
/// the obvious thing to write — sets the **thumb** to the same colour the
/// track already is, and the control becomes a uniform slab with no thumb in
/// it. On is indistinguishable from on.
///
/// That is what the create-folder sheet shipped: `activeThumbColor:
/// AppColors.primary` and nothing else, so the one switch in the app guarding
/// a security decision was the one switch you could not read. The settings
/// tiles and the rules page had already been fixed, each with its own copy of
/// the five properties below and its own comment explaining them — which is
/// the real lesson. A five-line correction that must be remembered at every
/// call site is not a correction, it is a trap with a delay on it.
///
/// **The rule for "on".** The accent is the *track*; [AppColors.onPrimary] —
/// the token whose whole job is "whatever reads on the accent" — is the thumb.
/// That relationship is what inverts correctly, in both modes, without anyone
/// having to think about which mode they are in.
///
/// ---
///
/// **The rule for "off", which is the harder half.**
///
/// The first version of this widget took the five properties the settings
/// tiles had been using, and they carried a second bug of their own: the
/// inactive track was [AppColors.surfaceVariant] and its outline was
/// [AppColors.border]. Those are the *same tokens the rows themselves are
/// built from* — so on a row filled with `surfaceVariant` (the create-folder
/// sheet) the track was literally the colour of the thing behind it, and the
/// outline was four points away from both. Switched off, the control was a
/// dim thumb floating in nothing, which is not a switch; it is a smudge that
/// happens to be tappable.
///
/// So the off state is built from tokens that are a step away from *any*
/// surface this can be dropped onto, rather than from the one surface it
/// happened to be tested on:
///
/// * [AppColors.surfaceElevated] for the track — the palette defines it in as
///   many words as "for chips and inputs sitting *on* a surface where
///   surfaceVariant would disappear against it". This is that case exactly.
/// * [AppColors.textDisabled] as a real hairline, because on near-black a
///   10-point step between two greys is not enough on its own. The outline is
///   what states "there is a control here" before any state is read off it.
/// * [AppColors.textSecondary] for the thumb — a mid grey, legible on the
///   track without being the white that would make an *off* switch the
///   brightest thing in the row.
///
/// The outline is dropped when the switch is on. Off, it is the only thing
/// giving the control an edge; on, the track is a solid slab of accent and a
/// grey ring around it reads as dirt.
class AppSwitch extends StatelessWidget {
  final bool value;

  /// Null disables the control, same as [Switch].
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      // Deliberately no haptic here. The haptics *setting* is itself one of
      // these, and it plays its own confirming buzz on the way on so the thing
      // being switched on demonstrates itself — a second buzz fired from
      // inside the control would double it.
      activeThumbColor: AppColors.onPrimary,
      activeTrackColor: AppColors.primary,
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: AppColors.surfaceElevated,
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.textDisabled,
      ),
      // Material's own default here is 2px, which at this size reads as a
      // drawn border rather than as the edge of a control.
      trackOutlineWidth: const WidgetStatePropertyAll<double>(1.5),
    );
  }
}
