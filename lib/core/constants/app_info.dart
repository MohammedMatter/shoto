/// Facts about this build that more than one screen needs to agree on.
abstract class AppInfo {
  AppInfo._();

  /// Kept in step with `version:` in pubspec.yaml by hand.
  ///
  /// Deliberately a constant rather than a package_info_plus lookup: it is
  /// read while building a settings row and inside a mailto body, neither of
  /// which is a place to await a platform channel, and a whole dependency to
  /// avoid retyping one number when the version changes is a poor trade.
  static const String version = '1.0.0';

  /// Where "Contact support" writes to.
  static const String supportEmail = 'shotoapp.official@gmail.com';
}
