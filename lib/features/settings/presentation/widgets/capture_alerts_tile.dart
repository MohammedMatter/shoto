import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shoto/core/di/dependency_injection.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/core/services/capture_alerts.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/theme/app_motion.dart';
import 'package:shoto/core/theme/app_text_styles.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';

/// The switch for "offer to file each screenshot as I take it", **and a line
/// underneath saying whether that is actually happening.**
///
/// The second half is not decoration. This feature rests on a scheduled job
/// that Android cancels on a reboot, drops on a force-stop, and throttles for
/// apps the user rarely opens — and on some skins, MIUI among them, a battery
/// optimiser can end it without telling anybody. Every one of those failures
/// leaves the switch sitting there, on, while nothing appears.
///
/// A switch that claims to be on while the thing is off is worse than no
/// switch: the user concludes the app is broken and has no way to find out
/// otherwise. So the control reports the *request* and the line reports the
/// *reality*, and where they disagree it says which way.
class CaptureAlertsTile extends StatefulWidget {
  const CaptureAlertsTile({super.key});

  @override
  State<CaptureAlertsTile> createState() => _CaptureAlertsTileState();
}

class _CaptureAlertsTileState extends State<CaptureAlertsTile>
    with WidgetsBindingObserver {
  CaptureAlertsStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// **Both fixes for the same blind spot: the answer arrives somewhere else.**
  ///
  /// Granting the notification permission happens in Android's own dialog,
  /// which is a separate activity — and going to fix a muted app happens in
  /// the system settings app. Neither tells Shoto anything, so without this
  /// the line underneath the switch would still be reading "notifications are
  /// off" a minute after the user turned them on, which is the exact failure
  /// this row exists to prevent, wearing the opposite sign.
  ///
  /// Also covers the honest direction: somebody who revokes notifications
  /// while Shoto sits in the background comes back to a warning rather than to
  /// a tick that is no longer true.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final CaptureAlertsStatus status = await CaptureAlerts.status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _set(bool value) async {
    await sl<AppPreferences>().setCaptureAlerts(value);
    final CaptureAlertsStatus status = value
        ? await CaptureAlerts.enable()
        : await CaptureAlerts.disable();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (!CaptureAlerts.isSupportedPlatform) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: sl<AppPreferences>(),
      builder: (BuildContext context, Widget? child) {
        final bool wanted = sl<AppPreferences>().captureAlerts;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SettingsSwitchTile(
              icon: Icons.notifications_active_outlined,
              label: context.l10n.settingsCaptureAlerts,
              description: context.l10n.settingsCaptureAlertsHint,
              value: wanted,
              onChanged: _set,
            ),
            if (wanted) _health(context),
          ],
        );
      },
    );
  }

  /// Only ever drawn under a switch that is on — there is nothing to report
  /// about a feature nobody asked for, and a warning under an off switch is
  /// just noise with an icon.
  Widget _health(BuildContext context) {
    final CaptureAlertsStatus? status = _status;
    if (status == null) return const SizedBox.shrink();

    final bool healthy = status.healthy;
    // Notifications first when both are wrong: it is the one the user can
    // actually fix, and fixing it is a different screen from anything Shoto
    // can offer.
    final String message = !status.notificationsAllowed
        ? context.l10n.settingsCaptureAlertsMuted
        : !status.armed
        ? context.l10n.settingsCaptureAlertsStopped
        : status.lastRun == null
        ? context.l10n.settingsCaptureAlertsWaiting
        : context.l10n.settingsCaptureAlertsLastRun(
            _ago(context, status.lastRun!),
          );

    // **The muted case is the only one with somewhere to go.** A stopped job
    // is fixed by opening Shoto, which the reader is already doing; blocked
    // notifications are fixed on a system screen this app can name but the
    // user would otherwise have to hunt for. So that one line becomes a
    // button and the others stay as statements — an underline on a sentence
    // that leads nowhere is worse than no underline at all.
    final bool actionable = !status.notificationsAllowed;

    final Widget line = Padding(
      // Aligned to the label above it rather than to a number of its own —
      // this line is a footnote on that switch, and a footnote that starts in
      // a different column reads as a separate row.
      padding: EdgeInsetsDirectional.fromSTEB(
        SettingsGlyph.textInset,
        0,
        16.w,
        12.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            healthy
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 14.sp,
            color: healthy ? context.colors.success : context.colors.warning,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: context.text.caption.copyWith(
                color: healthy
                    ? context.colors.textSecondary
                    : context.colors.warning,
                decoration: actionable ? TextDecoration.underline : null,
                decorationColor: context.colors.warning,
              ),
            ),
          ),
          if (actionable) ...[
            SizedBox(width: 4.w),
            Icon(
              Icons.open_in_new_rounded,
              size: 13.sp,
              color: context.colors.warning,
            ),
          ],
        ],
      ),
    );

    if (!actionable) return line;
    return PressableScale(
      feedback: PressFeedback.highlight,
      onTap: CaptureAlerts.openNotificationSettings,
      child: line,
    );
  }

  /// Deliberately coarse. The exact minute is not the question anybody is
  /// asking here — "recently" versus "days ago" is, because only the second
  /// one means something has gone wrong.
  String _ago(BuildContext context, DateTime moment) {
    final Duration since = DateTime.now().difference(moment);
    if (since.inMinutes < 60) {
      return context.l10n.timeAgoMinutes(since.inMinutes);
    }
    if (since.inHours < 24) return context.l10n.timeAgoHours(since.inHours);
    return context.l10n.timeAgoDays(since.inDays);
  }
}
