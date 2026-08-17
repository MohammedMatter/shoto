import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';

/// **A badge is a claim, and this one is about money.**
///
/// The yearly card read a literal "Save 73%". That is true of the two preview
/// figures typed into `SubscriptionConstants` and of nothing else: the moment
/// a real product exists, prices come from App Store Connect and Play Console
/// in the user's own currency, and a percentage sitting in the source has no
/// way of knowing what they say. Nobody would have noticed — the number looks
/// plausible whatever the prices are, which is exactly what makes it dangerous.
///
/// It is calculated now, and the interesting half of the calculation is when
/// it refuses to produce anything. Silence is a fine thing for a badge to say;
/// a wrong discount is not.
SubscriptionPackageInfo _plan({
  required double amount,
  required bool isYearly,
}) => SubscriptionPackageInfo(
  // The package itself is never read by the arithmetic under test.
  package: Package(
    'p',
    PackageType.custom,
    StoreProduct('id', '', 'title', amount, '', ''),
    const PresentedOfferingContext('o', null, null),
  ),
  priceString: '',
  amount: amount,
  isYearly: isYearly,
);

void main() {
  group('the yearly saving', () {
    test('is worked out from the two prices', () {
      // 23 against 12 × 7 = 84, which is 72.6% — and rounds to the 73 that
      // used to be typed in by hand. The point is that it is now derived: the
      // same code produces a different number the moment a store does.
      final int? percent = _plan(
        amount: 23,
        isYearly: true,
      ).savingAgainst(_plan(amount: 7, isYearly: false));

      expect(percent, 73);
    });

    test('follows the prices rather than a constant', () {
      // Halve the yearly price and the badge must move. A hardcoded 73 would
      // have sat here unchanged, on a card advertising something else.
      final int? percent = _plan(
        amount: 42,
        isYearly: true,
      ).savingAgainst(_plan(amount: 7, isYearly: false));

      expect(percent, 50);
    });

    test('says nothing when there is no monthly plan to compare against', () {
      expect(_plan(amount: 23, isYearly: true).savingAgainst(null), isNull);
    });

    test('says nothing when the yearly plan is not actually cheaper', () {
      // A store misconfiguration, or a promotion on the monthly plan. Either
      // way "Save -8%" is not a thing to print, and "Save 0%" is worse than
      // no badge at all.
      expect(
        _plan(
          amount: 90,
          isYearly: true,
        ).savingAgainst(_plan(amount: 7, isYearly: false)),
        isNull,
      );
      expect(
        _plan(
          amount: 84,
          isYearly: true,
        ).savingAgainst(_plan(amount: 7, isYearly: false)),
        isNull,
      );
    });

    test('says nothing about a free or unpriced product', () {
      expect(
        _plan(
          amount: 23,
          isYearly: true,
        ).savingAgainst(_plan(amount: 0, isYearly: false)),
        isNull,
      );
      expect(
        _plan(
          amount: 0,
          isYearly: true,
        ).savingAgainst(_plan(amount: 7, isYearly: false)),
        isNull,
      );
    });

    test('is only ever claimed by the yearly card', () {
      // The monthly plan is the thing being compared against; a saving on it
      // would be a comparison with itself.
      expect(
        _plan(
          amount: 7,
          isYearly: false,
        ).savingAgainst(_plan(amount: 7, isYearly: false)),
        isNull,
      );
    });
  });

  group('a year costs the same however it is billed', () {
    test('a monthly plan is twelve of itself', () {
      expect(_plan(amount: 7, isYearly: false).yearlyEquivalent, 84);
    });

    test('a yearly plan is already a year', () {
      expect(_plan(amount: 23, isYearly: true).yearlyEquivalent, 23);
    });
  });
}
