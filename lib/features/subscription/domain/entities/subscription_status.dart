class SubscriptionStatus {
  final bool isPremium;
  final DateTime? expirationDate;

  /// True when [isPremium] comes from the on-device tester switch rather than
  /// a real purchase. Kept distinct so the UI can say so plainly — a screen
  /// that claims a paid subscription when nothing was bought is how a
  /// developer ends up testing against a state no real user can be in, and
  /// how a paywall ships without anyone having seen it complete.
  ///
  /// Named "tester" rather than "developer" because the phrase reaches the
  /// screen: this is the state the app is in during a demo, and "Developer
  /// unlock" is a label for the person who wrote it rather than for the person
  /// looking at it.
  final bool isTesterAccess;

  const SubscriptionStatus({
    required this.isPremium,
    this.expirationDate,
    this.isTesterAccess = false,
  });

  static const SubscriptionStatus free = SubscriptionStatus(isPremium: false);

  static const SubscriptionStatus tester = SubscriptionStatus(
    isPremium: true,
    isTesterAccess: true,
  );
}
