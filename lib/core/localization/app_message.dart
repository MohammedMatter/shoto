import 'package:flutter/widgets.dart';
import 'package:shoto/core/localization/l10n.dart';

/// A message **chosen** somewhere that has no `BuildContext`, and **resolved**
/// somewhere that does.
///
/// This is the piece the app was missing, and the reason a third of its
/// user-facing text was stuck in English no matter which language was picked.
///
/// Blocs, repositories and services are where failures are detected, and none
/// of them has a `BuildContext` — so every one of them did the only thing it
/// could and emitted a literal:
///
/// ```dart
/// emit(FoldersErrorState('Could not load your folders.'));
/// ```
///
/// The translation for that exact sentence already existed, in all six
/// languages, under `errorLoadFolders`. It had simply never been reachable
/// from the place that needed it. Sixteen keys were in that state: written,
/// translated, shipped, and dead.
///
/// So the layer that *detects* a failure now names it, and the layer that
/// *draws* it looks it up:
///
/// ```dart
/// emit(FoldersErrorState(AppMessage.loadFolders));   // no context needed
/// Text(state.message.resolve(context));              // has one
/// ```
///
/// The shape is borrowed from [PremiumFeature], which solved the same problem
/// for the paywall's feature list by storing `String Function(BuildContext)`
/// rather than a `String` — this is that idea given a name and made reusable.
///
/// **Parameters go in the factory, not at the call site.** [stitchTooMany]
/// takes the number and closes over it, so the widget resolving the message
/// never has to know that this particular one interpolates anything.
@immutable
class AppMessage {
  final String Function(AppLocalizations) _lookup;

  const AppMessage._(this._lookup);

  /// Called from `build`, where the locale is known.
  String resolve(BuildContext context) => _lookup(context.l10n);

  // ------------------------------------------------------------- loading

  static const AppMessage loadScreenshots = AppMessage._(_loadScreenshots);
  static const AppMessage loadFolders = AppMessage._(_loadFolders);

  // -------------------------------------------------------- folder writes
  //
  // Separate from [loadFolders] because they are drawn differently and have
  // to be: a failed *read* leaves nothing on screen, so it takes over the
  // page. A failed *write* happens behind a grid that is still perfectly
  // good, and replacing that grid with an error panel would lose every folder
  // the user has over one that could not be made.

  static const AppMessage saveFolder = AppMessage._(_saveFolder);
  static const AppMessage deleteFolder = AppMessage._(_deleteFolder);
  static const AppMessage scanDuplicates = AppMessage._(_scanDuplicates);
  static const AppMessage deleteSelected = AppMessage._(_deleteSelected);
  static const AppMessage onboarding = AppMessage._(_onboarding);

  // -------------------------------------------------------------- signing in

  static const AppMessage signInCancelled = AppMessage._(_signInCancelled);
  static const AppMessage signInInterrupted = AppMessage._(_signInInterrupted);
  static const AppMessage network = AppMessage._(_network);
  static const AppMessage generic = AppMessage._(_generic);

  // ------------------------------------------------------------ subscription

  static const AppMessage plans = AppMessage._(_plans);
  static const AppMessage purchase = AppMessage._(_purchase);
  static const AppMessage noSubscription = AppMessage._(_noSubscription);
  static const AppMessage restore = AppMessage._(_restore);

  // ----------------------------------------------------------------- merging
  //
  // The stitcher is the one feature that fails in genuinely different ways,
  // and each one tells the user something different about what to do next —
  // "these are different widths" and "these do not overlap" are not the same
  // advice. Collapsing them into one generic failure would be the easy way to
  // localize this feature and would throw away the only thing that makes its
  // errors useful.

  static const AppMessage stitchFailed = AppMessage._(_stitchFailed);
  static const AppMessage stitchSave = AppMessage._(_stitchSave);
  static const AppMessage stitchTooFew = AppMessage._(_stitchTooFew);
  static const AppMessage stitchUnreadable = AppMessage._(_stitchUnreadable);
  static const AppMessage stitchWidths = AppMessage._(_stitchWidths);
  static const AppMessage stitchNoOverlap = AppMessage._(_stitchNoOverlap);
  static const AppMessage stitchOverlap = AppMessage._(_stitchOverlap);
  static const AppMessage stitchTooTall = AppMessage._(_stitchTooTall);
  static const AppMessage stitchEncode = AppMessage._(_stitchEncode);

  /// Carries the cap with it, so the sentence can put the number wherever that
  /// language puts it.
  static AppMessage stitchTooMany(int count) =>
      AppMessage._((AppLocalizations l) => l.errorStitchTooMany(count));

  // ------------------------------------------------------------- safe share

  static const AppMessage redactionSave = AppMessage._(_redactionSave);

  // ------------------------------------------------------------------ saving

  static AppMessage savedCount(int count) =>
      AppMessage._((AppLocalizations l) => l.shareSavedCount(count));
}

// Top-level functions rather than closures, so every message above can be
// `const` — a closure cannot be, and without this each one would allocate on
// every emit.

String _loadScreenshots(AppLocalizations l) => l.errorLoadScreenshots;
String _loadFolders(AppLocalizations l) => l.errorLoadFolders;
String _saveFolder(AppLocalizations l) => l.errorSaveFolder;
String _deleteFolder(AppLocalizations l) => l.errorDeleteFolder;
String _scanDuplicates(AppLocalizations l) => l.errorScanDuplicates;
String _deleteSelected(AppLocalizations l) => l.errorDeleteSelected;
String _onboarding(AppLocalizations l) => l.errorOnboarding;

String _signInCancelled(AppLocalizations l) => l.errorSignInCancelled;
String _signInInterrupted(AppLocalizations l) => l.errorSignInInterrupted;
String _network(AppLocalizations l) => l.errorNetwork;
String _generic(AppLocalizations l) => l.errorGeneric;

String _plans(AppLocalizations l) => l.errorPlans;
String _purchase(AppLocalizations l) => l.errorPurchase;
String _noSubscription(AppLocalizations l) => l.errorNoSubscription;
String _restore(AppLocalizations l) => l.errorRestore;

String _stitchFailed(AppLocalizations l) => l.errorStitchFailed;
String _stitchSave(AppLocalizations l) => l.errorStitchSave;
String _stitchTooFew(AppLocalizations l) => l.errorStitchTooFew;
String _stitchUnreadable(AppLocalizations l) => l.errorStitchUnreadable;
String _stitchWidths(AppLocalizations l) => l.errorStitchWidths;
String _stitchNoOverlap(AppLocalizations l) => l.errorStitchNoOverlap;
String _stitchOverlap(AppLocalizations l) => l.errorStitchOverlap;
String _stitchTooTall(AppLocalizations l) => l.errorStitchTooTall;
String _stitchEncode(AppLocalizations l) => l.errorStitchEncode;

String _redactionSave(AppLocalizations l) => l.errorRedactionSave;
