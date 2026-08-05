import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/l10n/app_localizations.dart';
import 'package:shoto/l10n/app_localizations_ar.dart';
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

  group('Arabic counts use the forms Arabic actually has', () {
    final AppLocalizations l10n = AppLocalizationsAr();

    test('one, two, and few are each their own form', () {
      // Arabic does not simply split at one. Two is dual and 3-10 takes the
      // broken plural, so a one/other pair — which is all English needs —
      // would be wrong here three times over.
      final String one = l10n.backupDone(1, 1);
      final String two = l10n.backupDone(2, 2);
      final String few = l10n.backupDone(5, 5);
      final String many = l10n.backupDone(30, 30);

      expect(one, contains('لقطة وحدة'));
      expect(two, contains('لقطتين'));
      expect(few, contains('5 لقطات'));
      expect(many, contains('30 لقطة'));

      expect(<String>{one, two, few, many}, hasLength(4));
    });
  });
}
