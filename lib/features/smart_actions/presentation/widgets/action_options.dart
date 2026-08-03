import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';
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
    DetectedActionKind.event => Icons.event_rounded,
    DetectedActionKind.place => Icons.place_rounded,
    DetectedActionKind.wifi => Icons.wifi_rounded,
    DetectedActionKind.tracking => Icons.local_shipping_rounded,
    DetectedActionKind.phone => Icons.call_rounded,
    DetectedActionKind.email => Icons.alternate_email_rounded,
    DetectedActionKind.link => Icons.link_rounded,
    DetectedActionKind.code => Icons.password_rounded,
    DetectedActionKind.iban => Icons.account_balance_rounded,
  };

  /// Takes a context rather than being a getter: these are translated, and
  /// there is nowhere else in an extension to read the language from.
  String kindLabel(BuildContext context) => switch (kind) {
    DetectedActionKind.event => context.l10n.kindEvent,
    DetectedActionKind.place => context.l10n.kindPlace,
    DetectedActionKind.wifi => context.l10n.kindWifi,
    DetectedActionKind.tracking => context.l10n.kindTracking,
    DetectedActionKind.phone => context.l10n.kindPhone,
    DetectedActionKind.email => context.l10n.kindEmail,
    DetectedActionKind.link => context.l10n.kindLink,
    DetectedActionKind.code => context.l10n.kindCode,
    DetectedActionKind.iban => context.l10n.kindIban,
  };

  /// The headline of the row.
  ///
  /// Identical to [display] for everything except an event, whose headline is
  /// what the thing is *called* — the date belongs on the second line, where
  /// [subtitle] renders it properly formatted for the reader's language
  /// instead of however OCR happened to find it.
  String displayText(BuildContext context) {
    final ActionDetails? extra = details;
    if (extra is EventDetails) {
      final String? title = extra.title?.trim();
      return title == null || title.isEmpty
          ? context.l10n.actionEventUntitled
          : title;
    }
    return display;
  }

  /// The quiet second line, or null for the kinds that have nothing to add.
  ///
  /// This is where the parsed value goes when it is more trustworthy than the
  /// raw one — an event's date rendered in the reader's own calendar
  /// conventions, the network a password belongs to, the carrier holding a
  /// parcel.
  String? subtitle(BuildContext context) {
    final ActionDetails? extra = details;
    return switch (extra) {
      EventDetails() => _formatEvent(context, extra),
      WifiDetails() => extra.network,
      TrackingDetails() => extra.carrier?.label,
      PlaceDetails() => null,
      null => null,
    };
  }

  /// What Copy and Share put on the clipboard.
  ///
  /// Not always [value]: an event's value is an ISO timestamp used only to
  /// tell two detections apart, and a place's is case-folded for the same
  /// reason. Copying either would hand the user a string they never saw.
  String copyText(BuildContext context) {
    final ActionDetails? extra = details;
    return switch (extra) {
      EventDetails() =>
        '${displayText(context)} — ${_formatEvent(context, extra)}',
      PlaceDetails() => extra.query,
      WifiDetails() => extra.password,
      TrackingDetails() => extra.number,
      null => value,
    };
  }

  List<ActionOption> options(BuildContext context) => [
    ...switch (kind) {
      DetectedActionKind.event => <ActionOption>[
        ActionOption(
          icon: Icons.calendar_month_rounded,
          label: context.l10n.actionAddToCalendar,
          // A pre-filled template rather than a written event. Everything on
          // the way here involved a judgement call — which number was the
          // month, whether 3:00 meant the afternoon — and a form the user
          // reads before saving is what makes those calls safe to make at
          // all. It also needs no calendar permission and no extra package.
          run: () => _open(
            calendarUriFor(details! as EventDetails, displayText(context)),
            external: true,
          ),
        ),
      ],
      DetectedActionKind.place => <ActionOption>[
        ActionOption(
          icon: Icons.map_rounded,
          label: context.l10n.actionOpenMaps,
          run: () => _open(
            mapsUriFor('/maps/search/', 'query', details! as PlaceDetails),
            external: true,
          ),
        ),
        ActionOption(
          icon: Icons.directions_rounded,
          label: context.l10n.actionDirections,
          run: () => _open(
            mapsUriFor('/maps/dir/', 'destination', details! as PlaceDetails),
            external: true,
          ),
        ),
      ],
      DetectedActionKind.wifi => <ActionOption>[
        // Joining the network outright is not offered, and not because it was
        // forgotten: it needs the platform's Wi-Fi suggestion APIs, a native
        // channel on both sides, and a location permission on Android. The
        // password on the clipboard is the ninety-percent of that, at none of
        // the cost.
        if ((details! as WifiDetails).network != null)
          ActionOption(
            icon: Icons.wifi_rounded,
            label: context.l10n.actionCopyNetwork,
            run: () async {
              await Clipboard.setData(
                ClipboardData(text: (details! as WifiDetails).network!),
              );
              return true;
            },
          ),
      ],
      DetectedActionKind.tracking => <ActionOption>[
        // No carrier means no button. Sending a number to a tracking page that
        // has never seen it is worse than leaving the user to copy it.
        if ((details! as TrackingDetails).carrier != null)
          ActionOption(
            icon: Icons.local_shipping_rounded,
            label: context.l10n.actionTrack,
            run: () {
              final TrackingDetails parcel = details! as TrackingDetails;
              return _open(
                parcel.carrier!.trackingUrl(parcel.number),
                external: true,
              );
            },
          ),
      ],
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
        await Clipboard.setData(ClipboardData(text: copyText(context)));
        return true;
      },
    ),
    ActionOption(
      icon: Icons.ios_share_rounded,
      label: context.l10n.commonShare,
      run: () async {
        await SharePlus.instance.share(ShareParams(text: copyText(context)));
        return true;
      },
    ),
  ];
}

/// A Google Calendar event template with every field SHOTO managed to read.
///
/// `dates` is written as a floating local stamp with no `Z` and no offset,
/// which Google reads in the calendar's own timezone. That is exactly right
/// for a screenshot: an invitation saying 3:00 PM means three in the
/// afternoon, and pinning it to UTC would move the appointment by however
/// many hours the phone is from Greenwich.
@visibleForTesting
Uri calendarUriFor(EventDetails event, String title) {
  final DateTime end = _endOf(event);
  return Uri.https('calendar.google.com', '/calendar/render', {
    'action': 'TEMPLATE',
    'text': title,
    'dates': event.allDay
        ? '${_calendarDay(event.start)}/${_calendarDay(end)}'
        : '${_calendarStamp(event.start)}/${_calendarStamp(end)}',
    if (event.location != null) 'location': event.location!,
    if (event.notes != null) 'details': event.notes!,
  });
}

/// The finish time, invented when the screenshot did not give one.
///
/// An hour for a timed event and a day for an all-day one, which is what every
/// calendar app assumes anyway. The `isAfter` guard catches the one real case
/// where the parsed end is not usable: a range that crosses midnight, where
/// "11:00 PM – 1:00 AM" parses both ends onto the same calendar day and the
/// finish lands two hours *before* the start.
DateTime _endOf(EventDetails event) {
  if (event.allDay) {
    // Google reads an all-day range's end as exclusive, so a one-day event
    // finishes on the following date.
    return (event.end ?? event.start).add(const Duration(days: 1));
  }
  final DateTime? parsed = event.end;
  if (parsed != null && parsed.isAfter(event.start)) return parsed;
  if (parsed != null) return parsed.add(const Duration(days: 1));
  return event.start.add(const Duration(hours: 1));
}

String _calendarDay(DateTime at) =>
    '${_pad(at.year, 4)}${_pad(at.month, 2)}${_pad(at.day, 2)}';

String _calendarStamp(DateTime at) =>
    '${_calendarDay(at)}T${_pad(at.hour, 2)}${_pad(at.minute, 2)}00';

String _pad(int value, int width) => value.toString().padLeft(width, '0');

/// Maps' universal cross-platform URL. It resolves to the Google Maps app when
/// one is installed and to the web map when it is not, on both platforms —
/// which a `geo:` URI does not.
@visibleForTesting
Uri mapsUriFor(String path, String parameter, PlaceDetails place) =>
    Uri.https('www.google.com', path, {'api': '1', parameter: place.query});

/// The event's date and time in the reader's own conventions.
///
/// Falls back to the default locale rather than throwing: `DateFormat` raises
/// if the app is running in a language whose date symbols were never loaded,
/// and losing a whole row to a formatting detail would be absurd.
String _formatEvent(BuildContext context, EventDetails event) {
  final String locale = Localizations.localeOf(context).toLanguageTag();
  DateFormat day;
  DateFormat clock;
  try {
    day = DateFormat.yMMMEd(locale);
    clock = DateFormat.jm(locale);
  } catch (_) {
    day = DateFormat.yMMMEd();
    clock = DateFormat.jm();
  }

  if (event.allDay) return day.format(event.start);

  final String start = '${day.format(event.start)} · ${clock.format(event.start)}';
  final DateTime? end = event.end;
  if (end == null || !end.isAfter(event.start)) return start;
  return '$start – ${clock.format(end)}';
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
