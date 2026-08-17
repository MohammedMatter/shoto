import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/routes/fade_slide_page_route.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/core/theme/app_icon.dart';
import 'package:shoto/core/theme/app_icon_controller.dart';
import 'package:shoto/core/theme/app_tint.dart';
import 'package:shoto/core/theme/folder_appearance_controller.dart';
import 'package:shoto/core/theme/grid_density_controller.dart';
import 'package:shoto/core/theme/theme_controller.dart';
import 'package:shoto/core/theme/tint_controller.dart';
import 'package:shoto/core/widgets/grid_density_selector.dart';
import 'package:shoto/core/widgets/header_icon_button.dart';
import 'package:shoto/core/widgets/premium_gate.dart';
import 'package:shoto/core/widgets/pro_badge.dart';
import 'package:shoto/features/settings/presentation/widgets/app_icon_picker.dart';
import 'package:shoto/features/settings/presentation/widgets/appearance_card.dart';
import 'package:shoto/features/settings/presentation/widgets/theme_card_selector.dart';
import 'package:shoto/features/settings/presentation/widgets/tint_picker.dart';

/// Everything about how the app *looks*, on one page.
///
/// **Why it left Settings.** Theme and grid density were two rows near the top
/// of Settings, each with a compact segmented control pinned to its trailing
/// edge — a shape `settings_tiles.dart` records as the fix for those two
/// controls having taken about a third of the page between them when they were
/// full width. That fix was right for a page that had somewhere better to
/// spend the room. This page does not: it is *about* those controls, so they
/// get their labels back and the room they were denied.
///
/// The accent is what made a page necessary. Sixteen swatches do not belong in
/// a list of switches, and the alternative — putting the whole thing in a
/// sheet — is the wrong container for something the user will sit and try four
/// of: a sheet covers the app it is recolouring, which is the one thing this
/// must not do. Everything here changes the screen it is standing on, and that
/// is why it is a screen rather than a modal.
///
/// The one sheet on this page is the overflow of the other ten colours, and it
/// earns the exception for the opposite reason: it covers half the screen, so
/// the app is still visible behind it while the grid is open.
Future<void> openAppearancePage(BuildContext context) => Navigator.of(
  context,
).push<void>(FadeSlidePageRoute(builder: (_) => const AppearancePage()));

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  /// **Returning to the app's own colour is never gated.**
  ///
  /// A subscription that lapses stops selling *new* choices; it does not
  /// repossess the one already made — see [TintController.isCustom]. But a
  /// lapsed user who wants their app plain again would then be stuck with the
  /// accent they can no longer change, which turns a preference into a
  /// souvenir of a cancelled subscription. Teal is always free to pick.
  ///
  /// Returns whether the accent is now what was asked for, which the overflow
  /// sheet needs in order not to light a ring on a declined paywall. See
  /// [TintSelected].
  Future<bool> _select(BuildContext context, AppTint tint) async {
    final TintController controller = sl<TintController>();
    if (tint == controller.tint) return true;

    if (tint != AppTint.fallback && !await ensurePremium(context)) return false;

    await controller.setTint(tint);
    return true;
  }

  /// The same rule as [_select], for the same reason: the original mark is
  /// always free to go back to, so a lapsed subscriber is never stuck with a
  /// coloured icon they can no longer change.
  Future<bool> _selectIcon(BuildContext context, AppIcon icon) async {
    final AppIconController controller = sl<AppIconController>();
    if (icon == controller.icon) return true;

    if (icon != AppIcon.fallback && !await ensurePremium(context)) return false;

    return controller.setIcon(icon);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Every control on this page is backed by one of these, and all four
      // repaint the same screen — merged rather than nested for the reason
      // `MyApp` gives about rebuilding once per change.
      listenable: Listenable.merge(<Listenable>[
        sl<ThemeController>(),
        sl<TintController>(),
        sl<GridDensityController>(),
        sl<FolderAppearanceController>(),
        sl<AppIconController>(),
        sl<ProStatus>(),
      ]),
      builder: (BuildContext context, _) {
        final bool showProBadge = !sl<ProStatus>().isPro;
        final FolderAppearanceController folders =
            sl<FolderAppearanceController>();

        return Scaffold(
          backgroundColor: context.colors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                // **A fixed bar, not a title that scrolls away.**
                //
                // Settings and Library both put their heading in the list and
                // let it leave, because both are long pages you read down.
                // This one is three controls and a person coming back from a
                // colour they did not like wants the way out where they left
                // it — and the back button is the way out.
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
                  child: Row(
                    children: <Widget>[
                      HeaderIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: context.l10n.commonBack,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      // Centred by giving the title the whole row and letting
                      // the button sit on top of it, rather than by balancing
                      // it with an invisible second button — a spacer sized to
                      // match a control is a layout that breaks the day the
                      // control changes size.
                      Expanded(
                        child: Text(
                          context.l10n.settingsAppearance,
                          textAlign: TextAlign.center,
                          style: context.text.titleLarge,
                        ),
                      ),
                      SizedBox(width: HeaderIconButton.size),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 40.h),
                    children: <Widget>[
                      // **Theme first, because the accent is drawn differently
                      // in each mode.** A tint solves to one shade for light
                      // and another for dark, and the swatches below paint
                      // whichever is currently in force — so somebody who sets
                      // the mode first sees true colours when they get there,
                      // and somebody who does it the other way round watches
                      // the grid restate itself, which is the same lesson
                      // arriving late.
                      _SectionLabel(context.l10n.settingsTheme),
                      ThemeCardSelector(
                        value: sl<ThemeController>().themeMode,
                        onChanged: (ThemeMode mode) =>
                            sl<ThemeController>().setThemeMode(mode),
                      ),

                      _SectionLabel(
                        context.l10n.appearanceTint,
                        caption: context.l10n.appearanceTintHint,
                        trailing: showProBadge ? const ProBadge() : null,
                      ),
                      TintSection(
                        value: sl<TintController>().tint,
                        onSelect: (AppTint tint) => _select(context, tint),
                      ),

                      // **Below the accent, because it is the same choice made
                      // twice** — the five colours here are the same solves
                      // the swatches above offer, so somebody who has already
                      // picked plum arrives here knowing what they want.
                      //
                      // The warning is a caption rather than a dialog: it is
                      // true, mild and only worth reading once, and a
                      // confirmation step in front of a colour swap is the
                      // kind of friction that makes a feature feel dangerous
                      // when it is merely slow.
                      _SectionLabel(
                        context.l10n.appIcon,
                        caption: context.l10n.appIconHint,
                        trailing: showProBadge ? const ProBadge() : null,
                      ),
                      AppearanceCard(
                        divided: false,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: AppIconPicker(
                              value: sl<AppIconController>().icon,
                              isBusy: sl<AppIconController>().isChanging,
                              onSelect: (AppIcon icon) =>
                                  _selectIcon(context, icon),
                            ),
                          ),
                        ],
                      ),

                      _SectionLabel(context.l10n.appearanceLibrary),
                      AppearanceCard(
                        children: <Widget>[
                          AppearanceRow(
                            label: context.l10n.settingsGridDensity,
                            trailing: GridDensitySelector(
                              compact: true,
                              value: sl<GridDensityController>().columns,
                              onChanged: (int columns) =>
                                  sl<GridDensityController>().setColumns(
                                    columns,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      // **Only what a folder actually knows about itself.**
                      //
                      // The layout this follows offers a description and a
                      // modification date as well; `FolderEntity` has neither.
                      // A switch that reveals a field which does not exist can
                      // only ever do nothing, and one labelled "modified" over
                      // a created date is worse — it is wrong rather than
                      // absent. See [FolderAppearanceController].
                      _SectionLabel(context.l10n.appearanceFolders),
                      AppearanceCard(
                        children: <Widget>[
                          AppearanceRow(
                            label: context.l10n.appearanceFolderSize,
                            trailing: GridDensitySelector(
                              compact: true,
                              value: folders.columns,
                              onChanged: folders.setColumns,
                            ),
                          ),
                          AppearanceSwitchRow(
                            label: context.l10n.appearanceFolderCount,
                            value: folders.showCount,
                            onChanged: folders.setShowCount,
                          ),
                          AppearanceSwitchRow(
                            label: context.l10n.appearanceFolderDate,
                            value: folders.showCreated,
                            onChanged: folders.setShowCreated,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The heading over each block.
///
/// Written here rather than reusing [SettingsGroup] because that widget's job
/// is a *list of rows* — it draws a hairline between every child, which is
/// right for switches and wrong for a swatch grid. What is shared is the shape
/// of the heading itself: same `sectionLabel` style, same 32 above and 10
/// below, so the two pages read as one app even though they are built
/// differently. It tracks that widget deliberately — the two were allowed to
/// drift into small caps here and sentence case there once, and the join
/// between the pages was the thing that showed it.
class _SectionLabel extends StatelessWidget {
  final String title;
  final String? caption;
  final Widget? trailing;

  const _SectionLabel(this.title, {this.caption, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h, bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(title, style: context.text.sectionLabel.asMedium),
              ),
              if (trailing != null) ...<Widget>[
                SizedBox(width: 10.w),
                trailing!,
              ],
            ],
          ),
          if (caption != null) ...<Widget>[
            SizedBox(height: 4.h),
            Text(caption!, style: context.text.caption),
          ],
        ],
      ),
    );
  }
}
