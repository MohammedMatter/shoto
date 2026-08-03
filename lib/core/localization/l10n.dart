import 'package:flutter/widgets.dart';
import 'package:shoto/l10n/app_localizations.dart';

export 'package:shoto/l10n/app_localizations.dart';

/// `context.l10n.someString` instead of `AppLocalizations.of(context)!`.
///
/// Worth the two lines: the long form appears in roughly four hundred places
/// in this app, and at that density the shorter call is the difference
/// between translated strings being the obvious thing to reach for and being
/// the annoying thing people skip.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
