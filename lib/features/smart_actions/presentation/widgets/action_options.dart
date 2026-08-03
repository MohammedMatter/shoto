import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/smart_actions/domain/entities/detected_action.dart';
import 'package:url_launcher/url_launcher.dart';

/// One thing the user can do with a detected item.
class ActionOption {
  final IconData icon;
  final String label;

  /// Returns false when the device has nothing that can handle it, so the
  /// caller can say so instead of the tap doing nothing at all.
  final Future<bool> Function() run;

  const ActionOption({
    required this.icon,
    required this.label,
    required this.run,
  });
}

/// What can be done with a given detection.
///
/// Copy is offered for everything and always listed last: it is the one
/// option that cannot fail, so it stays available as a fallback when the
/// device has no dialler, no mail client, or no browser.
extension DetectedActionOptions on DetectedAction {
  IconData get icon => switch (kind) {
    DetectedActionKind.phone => Icons.call_rounded,
    DetectedActionKind.email => Icons.alternate_email_rounded,
    DetectedActionKind.link => Icons.link_rounded,
    DetectedActionKind.code => Icons.password_rounded,
    DetectedActionKind.iban => Icons.account_balance_rounded,
  };

  /// Takes a context rather than being a getter: these are translated, and
  /// there is nowhere else in an extension to read the language from.
  String kindLabel(BuildContext context) => switch (kind) {
    DetectedActionKind.phone => context.l10n.kindPhone,
    DetectedActionKind.email => context.l10n.kindEmail,
    DetectedActionKind.link => context.l10n.kindLink,
    DetectedActionKind.code => context.l10n.kindCode,
    DetectedActionKind.iban => context.l10n.kindIban,
  };

  List<ActionOption> options(BuildContext context) => [
    ...switch (kind) {
      DetectedActionKind.phone => [
        ActionOption(
          icon: Icons.call_rounded,
          label: context.l10n.actionCall,
          // DIAL rather than CALL: it opens the dialler with the number
          // filled in, so a misread digit can never place a real call by
          // itself. It also needs no extra permission.
          run: () => _open(Uri(scheme: 'tel', path: value)),
        ),
        ActionOption(
          icon: Icons.chat_rounded,
          label: context.l10n.actionWhatsapp,
          run: () => _open(
            Uri.parse('https://wa.me/${value.replaceAll(RegExp(r'\D'), '')}'),
          ),
        ),
        ActionOption(
          icon: Icons.sms_rounded,
          label: context.l10n.actionSms,
          run: () => _open(Uri(scheme: 'sms', path: value)),
        ),
      ],
      DetectedActionKind.email => [
        ActionOption(
          icon: Icons.send_rounded,
          label: context.l10n.actionEmailAction,
          run: () => _open(Uri(scheme: 'mailto', path: value)),
        ),
      ],
      DetectedActionKind.link => [
        ActionOption(
          icon: Icons.open_in_new_rounded,
          label: context.l10n.actionOpen,
          run: () => _open(Uri.parse(value), external: true),
        ),
      ],
      DetectedActionKind.code => const [],
      DetectedActionKind.iban => const [],
    },
    ActionOption(
      icon: Icons.copy_rounded,
      label: context.l10n.actionsCopy,
      run: () async {
        await Clipboard.setData(ClipboardData(text: value));
        return true;
      },
    ),
    ActionOption(
      icon: Icons.ios_share_rounded,
      label: context.l10n.commonShare,
      run: () async {
        await SharePlus.instance.share(ShareParams(text: value));
        return true;
      },
    ),
  ];
}

Future<bool> _open(Uri uri, {bool external = false}) async {
  try {
    return await launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
  } catch (_) {
    // launchUrl throws rather than returning false when nothing can handle
    // the scheme; either way the caller just needs to know it didn't work.
    return false;
  }
}
