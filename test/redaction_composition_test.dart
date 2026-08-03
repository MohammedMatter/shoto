import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/sensitive_data.dart';
import 'package:shoto/features/safe_share/data/services/redaction_service.dart';
import 'package:shoto/features/safe_share/domain/entities/sensitive_region.dart';

/// The place where a bug leaves a real card number in an image that the
/// review list swore was handled.
///
/// Everything else in Safe Share fails loudly — a missed detection shows up
/// as a shorter list, a badly placed block is visible in the preview. This
/// one fails *silently*: the list says the value was covered, the exported
/// file still shows it, and nobody finds out until the screenshot is sent.
void main() {
  SensitiveRegion region({
    required String runId,
    required Rect bounds,
    String runText = '4111 1111 1111 1111',
    SensitiveKind kind = SensitiveKind.card,
    RegionTreatment treatment = RegionTreatment.cover,
  }) => SensitiveRegion(
    kind: kind,
    bounds: bounds,
    runId: runId,
    runText: runText,
    localStart: 0,
    localEnd: runText.length,
    original: runText,
    isRtl: false,
    treatment: treatment,
  );

  group('what actually gets painted', () {
    test('a covered finding produces a rectangle', () {
      final List<Rect> areas = RedactionService.coveredAreas(<SensitiveRegion>[
        region(runId: 'a', bounds: const Rect.fromLTWH(10, 20, 100, 30)),
      ]).toList();

      expect(areas, hasLength(1));
      expect(areas.single, const Rect.fromLTWH(10, 20, 100, 30));
    });

    test('a kept finding produces nothing', () {
      // The one treatment that leaves a real value in the picture. If this
      // ever painted, "keep" would be a lie.
      expect(
        RedactionService.coveredAreas(<SensitiveRegion>[
          region(
            runId: 'a',
            bounds: const Rect.fromLTWH(10, 20, 100, 30),
            treatment: RegionTreatment.keep,
          ),
        ]),
        isEmpty,
      );
    });

    test('two findings in one run become one rectangle covering both', () {
      // A name and the phone number printed against it, when OCR read them
      // as a single run. Two rows in the review list, one piece of image —
      // and the block has to reach both or half the run stays readable.
      final List<Rect> areas = RedactionService.coveredAreas(<SensitiveRegion>[
        region(
          runId: 'line-3',
          bounds: const Rect.fromLTWH(10, 20, 60, 30),
          kind: SensitiveKind.personName,
        ),
        region(
          runId: 'line-3',
          bounds: const Rect.fromLTWH(80, 20, 50, 30),
          kind: SensitiveKind.phone,
        ),
      ]).toList();

      expect(areas, hasLength(1));
      expect(areas.single.left, 10);
      expect(areas.single.right, 130);
    });

    test('separate runs stay separate', () {
      expect(
        RedactionService.coveredAreas(<SensitiveRegion>[
          region(runId: 'line-1', bounds: const Rect.fromLTWH(0, 0, 50, 20)),
          region(runId: 'line-9', bounds: const Rect.fromLTWH(0, 400, 50, 20)),
        ]),
        hasLength(2),
      );
    });

    test('a kept finding does not shrink the block over its neighbour', () {
      // Same run: one value the user chose to keep, one to cover. The kept
      // one must not widen the rectangle, and the covered one must still get
      // its own.
      final List<Rect> areas = RedactionService.coveredAreas(<SensitiveRegion>[
        region(
          runId: 'line-3',
          bounds: const Rect.fromLTWH(10, 20, 60, 30),
          treatment: RegionTreatment.keep,
        ),
        region(
          runId: 'line-3',
          bounds: const Rect.fromLTWH(80, 20, 50, 30),
          kind: SensitiveKind.phone,
        ),
      ]).toList();

      expect(areas, hasLength(1));
      expect(areas.single, const Rect.fromLTWH(80, 20, 50, 30));
    });
  });

  group('what the plan reports', () {
    test('kept findings are not counted as handled', () {
      final RedactionPlan plan = RedactionPlan(
        imageSize: const Size(1080, 2400),
        regions: <SensitiveRegion>[
          region(runId: 'a', bounds: const Rect.fromLTWH(0, 0, 50, 20)),
          region(
            runId: 'b',
            bounds: const Rect.fromLTWH(0, 40, 50, 20),
            runText: '0559876543',
            kind: SensitiveKind.phone,
            treatment: RegionTreatment.keep,
          ),
        ],
      );

      expect(plan.regions.length, 2);
      expect(plan.handledCount, 1);
    });

    test('the summary lists kinds most damaging first', () {
      final RedactionPlan plan = RedactionPlan(
        imageSize: const Size(1080, 2400),
        regions: <SensitiveRegion>[
          region(
            runId: 'a',
            bounds: const Rect.fromLTWH(0, 0, 50, 20),
            runText: 'ali@example.com',
            kind: SensitiveKind.email,
          ),
          region(runId: 'b', bounds: const Rect.fromLTWH(0, 40, 50, 20)),
          region(
            runId: 'c',
            bounds: const Rect.fromLTWH(0, 80, 50, 20),
            runText: 'sara@example.com',
            kind: SensitiveKind.email,
          ),
        ],
      );

      expect(plan.countsByKind.keys.toList(), <SensitiveKind>[
        SensitiveKind.card,
        SensitiveKind.email,
      ]);
      expect(plan.countsByKind[SensitiveKind.email], 2);
    });
  });

  group('what the review list shows', () {
    test('a card number is masked to its last four', () {
      final SensitiveRegion card = region(
        runId: 'a',
        bounds: const Rect.fromLTWH(0, 0, 50, 20),
        runText: '4111 1111 1111 1234',
      );

      expect(card.maskedOriginal, '•••• 1234');
    });

    test('a name is shown as it is', () {
      // Nothing is unlocked by knowing a name, and a row the user cannot
      // read is a row they cannot correct.
      final SensitiveRegion name = region(
        runId: 'a',
        bounds: const Rect.fromLTWH(0, 0, 50, 20),
        runText: 'Mohammed Aqel',
        kind: SensitiveKind.personName,
      );

      expect(name.maskedOriginal, 'Mohammed Aqel');
    });
  });

  group('the default', () {
    test('a region is covered unless something says otherwise', () {
      // Covering is what an untouched finding does. Somebody who taps
      // straight through to share gets every finding blocked out.
      final SensitiveRegion fresh = SensitiveRegion(
        kind: SensitiveKind.card,
        bounds: const Rect.fromLTWH(0, 0, 50, 20),
        runId: 'a',
        runText: '4111111111111111',
        localStart: 0,
        localEnd: 16,
        original: '4111111111111111',
        isRtl: false,
      );

      expect(fresh.treatment, RegionTreatment.cover);
    });
  });
}
