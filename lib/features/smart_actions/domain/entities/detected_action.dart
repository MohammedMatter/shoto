/// The kinds of thing SHOTO can pull out of a screenshot and act on.
///
/// Deliberately narrow. Each entry here is something that can be recognised
/// with near-certainty and that has an obvious, single next step — that is
/// what makes an action worth surfacing. Fuzzy extractions (postal addresses,
/// ambiguous dates) are left out on purpose: an action the user has to
/// double-check is worse than no action at all.
enum DetectedActionKind {
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
  final String value;

  /// What the user sees, kept close to how it appeared in the screenshot so
  /// it's recognisable.
  final String display;

  const DetectedAction({
    required this.kind,
    required this.value,
    required this.display,
  });

  @override
  bool operator ==(Object other) =>
      other is DetectedAction && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);

  @override
  String toString() => '${kind.id}:$value';
}
