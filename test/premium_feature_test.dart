import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/features/subscription/domain/entities/premium_feature.dart';
import 'package:shoto/l10n/app_localizations.dart';

/// The paywall is where somebody decides to pay, so what it lists has to be
/// true and it has to be readable in every language the app ships in.
///
/// This exists because it was neither. The filing-rules feature was deleted
/// but its entry stayed at the top of [PremiumFeature.all], so the first line
/// on the paywall promised something no longer in the app.
void main() {
  /// Pumps a real localisation for [locale] and hands back a context, because
  /// every string on a [PremiumFeature] is a `String Function(BuildContext)`
  /// and cannot be read without one.
  Future<BuildContext> contextFor(WidgetTester tester, Locale locale) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('every advertised feature reads in all six languages', (
    WidgetTester tester,
  ) async {
    for (final Locale locale in AppLocalizations.supportedLocales) {
      final BuildContext context = await contextFor(tester, locale);

      for (final PremiumFeature feature in PremiumFeature.all) {
        final String title = feature.title(context);
        expect(
          title.trim(),
          isNotEmpty,
          reason: 'empty title in ${locale.languageCode}',
        );
        expect(
          feature.description(context).trim(),
          isNotEmpty,
          reason: 'empty description for "$title" in ${locale.languageCode}',
        );
        expect(
          feature.how(context).trim(),
          isNotEmpty,
          reason: 'empty how for "$title" in ${locale.languageCode}',
        );

        // Three checkable specifics is the contract in the class doc — the
        // "What is included" screen lays them out expecting exactly that.
        expect(
          feature.points,
          hasLength(3),
          reason: '"$title" does not carry three points',
        );
        for (final String Function(BuildContext) point in feature.points) {
          expect(
            point(context).trim(),
            isNotEmpty,
            reason: 'empty point for "$title" in ${locale.languageCode}',
          );
        }
      }
    }
  });

  testWidgets('nothing advertises a feature that was removed', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await contextFor(
      tester,
      const Locale('en'),
    );
    final List<String> titles = PremiumFeature.all
        .map((PremiumFeature f) => f.title(context).toLowerCase())
        .toList();

    // Filing rules were deleted from the app; their paywall entry outlived
    // them by several commits. A named check is crude but it is the only kind
    // that would have caught this, and it costs nothing.
    expect(
      titles.any((String t) => t.contains('rule')),
      isFalse,
      reason: 'the filing-rules entry is back on the paywall',
    );
  });

  testWidgets('the list is not empty and has no duplicates', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await contextFor(tester, const Locale('en'));
    final List<String> titles = PremiumFeature.all
        .map((PremiumFeature f) => f.title(context))
        .toList();

    expect(titles, isNotEmpty);
    expect(titles.toSet(), hasLength(titles.length));
  });
}
