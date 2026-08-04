import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

ScreenshotEntity _shot(
  String id, {
  ScreenshotIntent? intent,
  DateTime? doneAt,
  DateTime? taken,
}) {
  return ScreenshotEntity(
    asset: AssetEntity(
      id: id,
      typeInt: 1,
      width: 100,
      height: 200,
      createDateSecond:
          (taken ?? DateTime.utc(2026, 1, 1)).millisecondsSinceEpoch ~/ 1000,
    ),
    isFavorite: false,
    folderId: null,
    intent: intent == null
        ? null
        : IntentState(intent: intent, doneAt: doneAt),
  );
}

ScreenshotsLoadedState _state(List<ScreenshotEntity> shots) =>
    ScreenshotsLoadedState(screenshots: shots);

void main() {
  group('ids are permanent', () {
    // These strings are written into every user's database. Renaming one
    // silently orphans every screenshot already marked with it.
    test('the stored ids are exactly these', () {
      expect(
        ScreenshotIntent.values.map((ScreenshotIntent i) => i.id),
        <String>['buy', 'read', 'reply', 'try', 'visit'],
      );
    });

    test('tryIt stores "try", not its Dart name', () {
      // `tryIt` exists only because `try` is a keyword; that accident must not
      // reach the column.
      expect(ScreenshotIntent.tryIt.id, 'try');
    });

    test('every id round trips', () {
      for (final ScreenshotIntent intent in ScreenshotIntent.values) {
        expect(ScreenshotIntent.fromId(intent.id), intent);
      }
    });

    test('an unknown id yields nothing rather than a guess', () {
      // A value written by a newer build has to read as "no intent" here, not
      // as whichever constant happens to be first.
      expect(ScreenshotIntent.fromId('teleport'), isNull);
      expect(ScreenshotIntent.fromId(''), isNull);
      expect(ScreenshotIntent.fromId(null), isNull);
    });
  });

  group('waiting and done', () {
    test('an intent with no timestamp is waiting', () {
      expect(
        const IntentState(intent: ScreenshotIntent.buy).isWaiting,
        isTrue,
      );
    });

    test('a timestamp means finished', () {
      final IntentState done = IntentState(
        intent: ScreenshotIntent.buy,
        doneAt: DateTime(2026),
      );
      expect(done.isDone, isTrue);
      expect(done.isWaiting, isFalse);
    });

    test('a screenshot with no intent is not waiting for anything', () {
      expect(_shot('a').isWaiting, isFalse);
    });
  });

  group('counts', () {
    final ScreenshotsLoadedState state = _state(<ScreenshotEntity>[
      _shot('buy-1', intent: ScreenshotIntent.buy),
      _shot('buy-2', intent: ScreenshotIntent.buy),
      _shot('buy-done', intent: ScreenshotIntent.buy, doneAt: DateTime(2026)),
      _shot('read-1', intent: ScreenshotIntent.read),
      _shot('plain'),
    ]);

    test('waitingFor counts only what is still waiting', () {
      expect(state.waitingFor(ScreenshotIntent.buy).length, 2);
      expect(state.waitingFor(ScreenshotIntent.read).length, 1);
      expect(state.waitingFor(ScreenshotIntent.visit), isEmpty);
    });

    test('doneFor counts only what is finished', () {
      expect(state.doneFor(ScreenshotIntent.buy), 1);
      expect(state.doneFor(ScreenshotIntent.read), 0);
    });

    test('an intent nobody has used is absent, not zero', () {
      // Home renders from this map, and a permanent row of zeroes would be
      // five reminders that a feature exists rather than a list of work.
      expect(state.waitingByIntent.keys, <ScreenshotIntent>[
        ScreenshotIntent.buy,
        ScreenshotIntent.read,
      ]);
      expect(state.waitingByIntent[ScreenshotIntent.buy], 2);
    });

    test('the total is the app one shrinking number', () {
      expect(state.waitingCount, 3);
    });

    test('everything finished leaves nothing to show', () {
      final ScreenshotsLoadedState allDone = _state(<ScreenshotEntity>[
        _shot('a', intent: ScreenshotIntent.buy, doneAt: DateTime(2026)),
      ]);
      expect(allDone.waitingByIntent, isEmpty);
      expect(allDone.waitingCount, 0);
      expect(allDone.doneFor(ScreenshotIntent.buy), 1);
    });
  });

  test('the waiting list is oldest first', () {
    // Against every other list in the app, and on purpose: a library is a
    // record you read from the top, a waiting list is a debt and the thing
    // owed longest belongs first.
    final ScreenshotsLoadedState state = _state(<ScreenshotEntity>[
      _shot('new', intent: ScreenshotIntent.read, taken: DateTime.utc(2026, 6)),
      _shot('old', intent: ScreenshotIntent.read, taken: DateTime.utc(2026, 1)),
      _shot('mid', intent: ScreenshotIntent.read, taken: DateTime.utc(2026, 3)),
    ]);
    expect(
      state.waitingFor(ScreenshotIntent.read).map((ScreenshotEntity s) => s.id),
      <String>['old', 'mid', 'new'],
    );
  });

  test('changing the intent drops any completion with it', () {
    // Having ticked off "reply" says nothing about whether the thing has been
    // bought, so the entity must not carry the old timestamp across.
    final ScreenshotEntity done = _shot(
      'a',
      intent: ScreenshotIntent.reply,
      doneAt: DateTime(2026),
    );
    final ScreenshotEntity changed = done.copyWith(
      intent: const IntentState(intent: ScreenshotIntent.buy),
    );
    expect(changed.intent!.intent, ScreenshotIntent.buy);
    expect(changed.intent!.isWaiting, isTrue);
  });

  test('clearing the intent leaves none', () {
    final ScreenshotEntity cleared = _shot(
      'a',
      intent: ScreenshotIntent.buy,
    ).copyWith(clearIntent: true);
    expect(cleared.intent, isNull);
    expect(cleared.isWaiting, isFalse);
  });
}
