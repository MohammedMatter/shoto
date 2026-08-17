import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/l10n/app_localizations.dart';
import 'package:shoto/l10n/app_localizations_de.dart';
import 'package:shoto/l10n/app_localizations_en.dart';

/// The backup screen reports counts, and counts need grammar.
///
/// These shipped once reading "Backed up 18 screenshots and 1 folders", which
/// is the kind of thing nobody files a bug about and everybody notices. The
/// strings are ICU plurals now; this is the guard that keeps them that way,
/// because the plain-interpolation version passes every other test in the
/// suite and fails only in front of a user.
void main() {
  group('English counts read as English', () {
    final AppLocalizations l10n = AppLocalizationsEn();

    test('one of a thing is singular', () {
      expect(l10n.backupDone(1, 1), 'Backed up 1 screenshot and 1 folder');
      expect(l10n.restoreDone(1, 1), 'Restored 1 screenshot and 1 folder');
    });

    test('a singular count beside a plural one', () {
      // The case that was actually wrong on the device: many screenshots, one
      // folder. Each count has to be decided on its own.
      expect(l10n.backupDone(18, 1), 'Backed up 18 screenshots and 1 folder');
      expect(l10n.backupDone(1, 4), 'Backed up 1 screenshot and 4 folders');
    });

    test('none is plural, not singular', () {
      expect(l10n.backupDone(0, 0), 'Backed up 0 screenshots and 0 folders');
    });

    test('the skipped counts agree with their verbs', () {
      expect(
        l10n.backupDoneWithSkips(9, 1),
        'Backed up 9 screenshots. 1 could not be read.',
      );
      expect(
        l10n.restoreDoneWithSkips(1, 3),
        'Restored 1 screenshot. 3 were skipped.',
      );
    });
  });

  /// The same guard in a second language, because the bug this file exists for
  /// is not an English one.
  ///
  /// It was Arabic here until Arabic stopped shipping — a better test, since
  /// Arabic has four plural forms and catches a one/other assumption three
  /// ways. German has the same two forms as English, so this can only catch
  /// the *structural* mistake: a translator collapsing the two independent
  /// counts into one plural decision. That is exactly what went wrong on the
  /// device, so it is still worth holding.
  group('German counts decide each number on its own', () {
    final AppLocalizations l10n = AppLocalizationsDe();

    test('each count picks its own form', () {
      final String oneOne = l10n.backupDone(1, 1);
      final String manyOne = l10n.backupDone(18, 1);
      final String oneMany = l10n.backupDone(1, 4);

      // Singular and plural must differ for *each* count independently. A
      // translation that reads the same either way has collapsed them.
      expect(oneOne, isNot(manyOne));
      expect(oneOne, isNot(oneMany));
      expect(manyOne, isNot(oneMany));

      // And the number itself has to survive into the sentence.
      expect(manyOne, contains('18'));
      expect(oneMany, contains('4'));
    });

    test('the skipped counts agree with their verbs', () {
      expect(l10n.backupDoneWithSkips(9, 1), isNot(l10n.backupDoneWithSkips(9, 3)));
      expect(l10n.restoreDoneWithSkips(1, 3), contains('3'));
    });
  });
}
