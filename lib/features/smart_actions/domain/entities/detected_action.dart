import 'package:shoto/features/smart_actions/domain/entities/action_details.dart';

/// The kinds of thing SHOTO can pull out of a screenshot and act on.
///
/// Deliberately narrow. Each entry here is something that can be recognised
/// with near-certainty and that has an obvious, single next step — that is
/// what makes an action worth surfacing. An action the user has to
/// double-check is worse than no action at all.
///
/// The first four are *intents* rather than entities, and that distinction is
/// the point. A phone number is a thing on the screen; an invitation is
/// something the user is about to have to do. Finding the thing is easy and
/// finding the intent is what saves them the four taps — so the intents lead
/// the enum, because **declaration order is display order**: the list is
/// sorted by `kind.index`, and the row somebody actually came for has to be
/// the row they see first.
enum DetectedActionKind {
  event('event'),
  place('place'),
  wifi('wifi'),
  tracking('tracking'),
  phone('phone'),
  email('email'),
  link('link'),
  code('code'),
  iban('iban');

  const DetectedActionKind(this.id);
  final String id;
}

class DetectedAction {
  final DetectedActionKind kind;

  /// Cleaned-up form used to actually perform the action — a phone number
  /// stripped of spaces and dashes, a link with its scheme filled in.
  ///
  /// It doubles as the identity of the detection (see [operator ==]), so for
  /// the intent kinds it is whatever makes two of them genuinely different:
  /// the start instant for an event, the network name for a Wi-Fi card.
  final String value;

  /// What the user sees, kept close to how it appeared in the screenshot so
  /// it's recognisable.
  final String display;

  /// The parsed extras, for kinds that need them. Null for everything that
  /// doesn't — the five original kinds carry no details and never will.
  final ActionDetails? details;

  const DetectedAction({
    required this.kind,
    required this.value,
    required this.display,
    this.details,
  });

  @override
  bool operator ==(Object other) =>
      other is DetectedAction && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => '${kind.id}:$value';
}
