import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/l10n/app_localizations.dart';

/// Guards the one property the app cannot check for itself: that picking a
/// language actually changes **everything**.
///
/// A missing translation does not crash and does not fail a build — it simply
/// falls back to English, in one corner of one screen, and nobody notices until
/// somebody using the app in Arabic hits it. These tests turn that into a red
/// test instead.
void main() {
  const List<String> locales = ['en', 'ar', 'es', 'fr', 'hi', 'ur'];

  Map<String, Object?> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, Object?>;

  /// Real message keys — the `@`-prefixed entries are placeholder metadata,
  /// and `@@locale` is the header.
  Set<String> keysOf(String locale) =>
      arb(locale).keys.where((String k) => !k.startsWith('@')).toSet();

  /// **Every locale defines every key.**
  ///
  /// English is the template because it is the one `l10n.yaml` generates the
  /// interface from: a key missing from `app_ar.arb` still compiles, still
  /// runs, and silently serves the English sentence to somebody who chose
  /// Arabic.
  test('every locale defines exactly the same keys as English', () {
    final Set<String> english = keysOf('en');
    expect(english, isNotEmpty);

    for (final String locale in locales.where((String l) => l != 'en')) {
      final Set<String> theirs = keysOf(locale);

      expect(
        english.difference(theirs),
        isEmpty,
        reason:
            'app_$locale.arb is missing keys that English defines — those '
            'strings will silently render in English.',
      );
      expect(
        theirs.difference(english),
        isEmpty,
        reason:
            'app_$locale.arb defines keys English does not, so nothing '
            'generates an accessor for them and they can never be shown.',
      );
    }
  });

  /// **No locale left a value in English by accident.**
  ///
  /// Only checks the handful of keys that are plain prose in every language.
  /// Brand words (`SHOTO`, `PRO`, `Pro`) and short shared loanwords are
  /// legitimately identical across locales, so a blanket "must differ" rule
  /// would be noise; these six are sentences, and a sentence identical to the
  /// English one is a translation that never happened.
  test('translated sentences are not left as the English text', () {
    const List<String> prose = [
      'errorLoadFolders',
      'errorNetwork',
      'errorGeneric',
      'foldersEmptyMessage',
      'proWelcomeBody',
      'subPremiumBody',
    ];

    final Map<String, Object?> english = arb('en');

    for (final String locale in locales.where((String l) => l != 'en')) {
      final Map<String, Object?> theirs = arb(locale);
      for (final String key in prose) {
        expect(
          theirs[key],
          isNot(equals(english[key])),
          reason: '$key is still the English sentence in app_$locale.arb',
        );
      }
    }
  });

  /// **Every [AppMessage] resolves, in every language.**
  ///
  /// The blocs name a message and the widgets look it up, so a message wired to
  /// a key that does not exist is a runtime failure on an error screen — the
  /// screen somebody only reaches when something has *already* gone wrong, and
  /// therefore the one least likely to be exercised by hand.
  testWidgets('every AppMessage resolves in every language', (
    WidgetTester tester,
  ) async {
    final List<AppMessage> all = <AppMessage>[
      AppMessage.loadScreenshots,
      AppMessage.loadFolders,
      AppMessage.scanDuplicates,
      AppMessage.deleteSelected,
      AppMessage.onboarding,
      AppMessage.signInCancelled,
      AppMessage.signInInterrupted,
      AppMessage.network,
      AppMessage.generic,
      AppMessage.plans,
      AppMessage.purchase,
      AppMessage.noSubscription,
      AppMessage.restore,
      AppMessage.stitchFailed,
      AppMessage.stitchSave,
      AppMessage.stitchTooFew,
      AppMessage.stitchUnreadable,
      AppMessage.stitchWidths,
      AppMessage.stitchNoOverlap,
      AppMessage.stitchOverlap,
      AppMessage.stitchTooTall,
      AppMessage.stitchEncode,
      AppMessage.redactionSave,
      AppMessage.stitchTooMany(4),
      AppMessage.savedCount(3),
    ];

    for (final String locale in locales) {
      final List<String> resolved = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              for (final AppMessage message in all) {
                resolved.add(message.resolve(context));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'threw in $locale');
      expect(resolved, hasLength(all.length));
      for (final String text in resolved) {
        expect(text.trim(), isNotEmpty, reason: 'blank message in $locale');
      }
    }
  });

  /// **Blocs may not emit sentences.**
  ///
  /// This is the rule the whole [AppMessage] type exists to enforce, and it is
  /// worth enforcing mechanically because the failure mode is so quiet: a bloc
  /// has no `BuildContext`, so writing the English inline is the path of least
  /// resistance and the result looks completely fine in English.
  test('no bloc emits a bare string into an error state', () {
    final RegExp offender = RegExp(
      r"(Error|Failed)State\(\s*'",
      caseSensitive: true,
    );

    final List<String> offenders = <String>[];
    for (final FileSystemEntity entity in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_bloc.dart')) continue;
      final String source = entity.readAsStringSync();
      if (offender.hasMatch(source)) offenders.add(entity.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These blocs pass a literal string to an error state. Add a key to '
          'the .arb files and name it through AppMessage instead — a bloc has '
          'no BuildContext, so a literal here can never be translated.',
    );
  });
}
