import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shoto/core/constants/app_info.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/widgets/app_snack_bar.dart';
import 'package:shoto/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Contact support" — hands the address to whatever mail app the phone has.
///
/// A `mailto:` link rather than an in-app form on purpose. The form would need
/// a server, would give the user no copy of what they sent, and would leave
/// them with nothing to reply to. A mailto opens Gmail (or whatever they
/// actually use), puts the message in their Sent folder, and turns support
/// into an ordinary email thread.
class ContactSupportTile extends StatelessWidget {
  const ContactSupportTile({super.key});

  Future<void> _contact(BuildContext context) async {
    // A greeting and a blank line, and nothing else.
    //
    // The body is not empty on purpose: a message with a subject and no words
    // at all is one of the things spam filters weigh, and support mail was
    // landing in the junk folder while this was blank. One human sentence is
    // enough to stop looking machine-sent.
    //
    // It is a greeting rather than an instruction because mail apps put the
    // cursor at the end of a prefilled body and give no way to move it — so
    // whatever goes here has to be something the user writes *after*, and
    // something harmless if they send it untouched.
    final Uri uri = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      query: _query(<String, String>{
        'subject': context.l10n.supportSubject,
        'body': '${context.l10n.supportGreeting}\n\n',
      }),
    );

    bool opened;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      // launchUrl throws rather than returning false when nothing can handle
      // the scheme, which is the common case on a phone with no mail app set
      // up at all.
      opened = false;
    }
    if (opened || !context.mounted) return;

    // Never a dead end. If there is no mail app, the address itself is the
    // useful thing, so it goes to the clipboard and the user is told where it
    // went — rather than a tap that appears to do nothing.
    await Clipboard.setData(const ClipboardData(text: AppInfo.supportEmail));
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      context.l10n.supportNoMailApp,
      kind: SnackKind.neutral,
    );
  }

  /// `Uri(queryParameters:)` encodes spaces as `+`, which is right for a web
  /// form and wrong here — mail apps show the pluses literally in the subject
  /// line. Percent-encoding is what a mailto wants.
  static String _query(Map<String, String> parameters) => parameters.entries
      .map(
        (MapEntry<String, String> e) =>
            '${e.key}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');

  @override
  Widget build(BuildContext context) {
    return SettingsNavTile(
      icon: Icons.mail_outline_rounded,
      label: context.l10n.settingsContactSupport,
      // The address is shown rather than hidden behind the tap: somebody who
      // would rather write from their laptop can read it here, and it makes
      // plain where the tap is about to take them.
      description: AppInfo.supportEmail,
      onTap: () => _contact(context),
    );
  }
}
