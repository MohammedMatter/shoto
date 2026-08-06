import 'package:flutter/material.dart';
import 'package:shoto/core/localization/l10n.dart';
import 'package:shoto/core/theme/app_colors.dart';
import 'package:shoto/core/utils/content_traits.dart';

/// How each [ContentTrait] looks and reads.
///
/// An extension in the presentation layer rather than fields on the enum,
/// following `category_visuals.dart`'s precedent: the enum stays free of
/// Flutter and of `BuildContext`, so the pure-Dart derivation in
/// `core/utils/content_traits.dart` remains unit-testable without a widget
/// binding, and a translation is looked up at the moment it is drawn.
extension ContentTraitVisuals on ContentTrait {
  IconData get icon => switch (this) {
    ContentTrait.sensitive => Icons.shield_rounded,
    ContentTrait.link => Icons.link_rounded,
    ContentTrait.contact => Icons.alternate_email_rounded,
    ContentTrait.code => Icons.pin_rounded,
    ContentTrait.event => Icons.event_rounded,
  };

  String label(BuildContext context) => switch (this) {
    ContentTrait.sensitive => context.l10n.libraryTraitSensitive,
    ContentTrait.link => context.l10n.libraryTraitLink,
    ContentTrait.contact => context.l10n.libraryTraitContact,
    ContentTrait.code => context.l10n.libraryTraitCode,
    ContentTrait.event => context.l10n.libraryTraitEvent,
  };

  /// The fill this chip takes when it is the active lens.
  ///
  /// Only one trait departs from the shared accent, and it departs for a
  /// reason rather than for variety: `sensitive` is the one lens somebody
  /// opens because something is *at risk*, and the app already spends rose on
  /// exactly that meaning everywhere else. Colour here is a claim about
  /// severity, so the other four share one neutral accent instead of being
  /// handed a rainbow that would imply differences between them that do not
  /// exist.
  Color accent(BuildContext context) => this == ContentTrait.sensitive
      ? context.colors.error
      : context.colors.secondary;

  /// One line saying where this trait's answer came from.
  ///
  /// Shown whenever the lens is on. The app has been burned once by a feature
  /// that presented a guess with the same confidence as a fact — Smart Albums
  /// was deleted over it — so a filter that cannot be verified by looking has
  /// to state its own basis. `RuleSummary.describe` earns trust the same way.
  String certaintyNote(BuildContext context) => switch (certainty) {
    TraitCertainty.verified => context.l10n.libraryCertaintyVerified,
    TraitCertainty.read => context.l10n.libraryCertaintyRead,
  };

  IconData get certaintyIcon => switch (certainty) {
    TraitCertainty.verified => Icons.verified_rounded,
    TraitCertainty.read => Icons.text_fields_rounded,
  };
}
