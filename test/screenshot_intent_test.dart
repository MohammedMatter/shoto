import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/entities/screenshot_entity.dart';
import 'package:shoto/features/screenshots/presentation/bloc/screenshots_state.dart';

const IntentRef _buy = BuiltInIntent(ScreenshotIntent.buy);
const IntentRef _read = BuiltInIntent(ScreenshotIntent.read);
const IntentRef _reply = BuiltInIntent(ScreenshotIntent.reply);
const IntentRef _visit = BuiltInIntent(ScreenshotIntent.visit);

CustomIntent _custom(String id, {String label = 'Return it', int order = 0}) =>
    CustomIntent(
      id: '${IntentRef.customPrefix}$id',
      label: label,
      iconKey: 'flag',
      sortOrder: order,
    );

ScreenshotEntity _shot(
  String id, {
  IntentRef? intent,
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
    intent: intent == null ? null : IntentState(ref: intent, doneAt: doneAt),
  );
}

ScreenshotsLoadedState _state(List<ScreenshotEntity> shots) =>
    ScreenshotsLoadedState(screenshots: shots);

void main() {
  group('ids are permanent', () {
    // These strings are written into every user's database. Renaming one
    // silently orphans every screenshot already marked with it.
    test('the stored ids are exactly these', () {
      expect(ScreenshotIntent.values.map((ScreenshotIntent i) => i.id), <String>[
        'buy',
        'read',
        'reply',
        'try',
        'visit',
        'watch',
        'listen',
        'cook',
        'book',
        'pay',
        'send',
        'download',
        'apply',
        'compare',
        'fix',
      ]);
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

    test('no built-in id could ever be mistaken for a custom one', () {
      // The two share one column. If a shipped verb ever started with the
      // custom prefix, loading it would send the repository looking for a row
      // that does not exist and the screenshot would come back blank.
      for (final ScreenshotIntent intent in ScreenshotIntent.values) {
        expect(IntentRef.isCustomId(intent.id), isFalse);
      }
    });
  });

  group('intent references', () {
    test('two references to the same verb are the same intent', () {
      // Equality is on the id because the id is what the database stores and
      // what every count is keyed by.
      expect(const BuiltInIntent(ScreenshotIntent.buy), _buy);
      expect(
        const BuiltInIntent(ScreenshotIntent.buy).hashCode,
        _buy.hashCode,
      );
    });

    test('a custom intent mid-rename is still the same intent', () {
      final CustomIntent before = _custom('1', label: 'Retrun it');
      final CustomIntent after = _custom('1', label: 'Return it');
      expect(before, after);
    });

    test('a custom id is never equal to a built-in one', () {
      expect(_custom('1') == _buy, isFalse);
    });
  });

  group('waiting and done', () {
    test('an intent with no timestamp is waiting', () {
      expect(const IntentState(ref: _buy).isWaiting, isTrue);
    });

    test('a timestamp means finished', () {
      final IntentState done = IntentState(ref: _buy, doneAt: DateTime(2026));
      expect(done.isDone, isTrue);
      expect(done.isWaiting, isFalse);
    });

    test('a screenshot with no intent is not waiting for anything', () {
      expect(_shot('a').isWaiting, isFalse);
    });

    test('a custom intent waits exactly like a built-in one', () {
      // The whole point of one type for both: a verb the user wrote is not a
      // lesser citizen anywhere downstream of here.
      expect(_shot('a', intent: _custom('1')).isWaiting, isTrue);
    });
  });

  group('counts', () {
    final ScreenshotsLoadedState state = _state(<ScreenshotEntity>[
      _shot('buy-1', intent: _buy),
      _shot('buy-2', intent: _buy),
      _shot('buy-done', intent: _buy, doneAt: DateTime(2026)),
      _shot('read-1', intent: _read),
      _shot('plain'),
    ]);

    test('waitingFor counts only what is still waiting', () {
      expect(state.waitingFor(_buy).length, 2);
      expect(state.waitingFor(_read).length, 1);
      expect(state.waitingFor(_visit), isEmpty);
    });

    test('doneFor counts only what is finished', () {
      expect(state.doneFor(_buy), 1);
      expect(state.doneFor(_read), 0);
    });

    test('an intent nobody has used is absent, not zero', () {
      // Home renders from this map, and a permanent row of zeroes would be
      // fifteen reminders that a feature exists rather than a list of work.
      expect(state.waitingByIntent.keys, <IntentRef>[_buy, _read]);
      expect(state.waitingByIntent[_buy], 2);
    });

    test('the total is the app one shrinking number', () {
      expect(state.waitingCount, 3);
    });

    test('everything finished leaves nothing to show', () {
      final ScreenshotsLoadedState allDone = _state(<ScreenshotEntity>[
        _shot('a', intent: _buy, doneAt: DateTime(2026)),
      ]);
      expect(allDone.waitingByIntent, isEmpty);
      expect(allDone.waitingCount, 0);
      expect(allDone.doneFor(_buy), 1);
    });

    test('custom intents are counted, and sort after the built-in ones', () {
      // Home reads the order straight off this map, so it has to be stable
      // rather than whatever order the library happened to be loaded in.
      final CustomIntent mine = _custom('1');
      final CustomIntent other = _custom('2', label: 'Chase them', order: 1);
      final ScreenshotsLoadedState mixed = _state(<ScreenshotEntity>[
        _shot('c2', intent: other),
        _shot('c1', intent: mine),
        _shot('b', intent: _read),
      ]);
      expect(mixed.waitingByIntent.keys, <IntentRef>[_read, mine, other]);
      expect(mixed.waitingFor(mine).length, 1);
    });
  });

  test('the waiting list is oldest first', () {
    // Against every other list in the app, and on purpose: a library is a
    // record you read from the top, a waiting list is a debt and the thing
    // owed longest belongs first.
    final ScreenshotsLoadedState state = _state(<ScreenshotEntity>[
      _shot('new', intent: _read, taken: DateTime.utc(2026, 6)),
      _shot('old', intent: _read, taken: DateTime.utc(2026, 1)),
      _shot('mid', intent: _read, taken: DateTime.utc(2026, 3)),
    ]);
    expect(
      state.waitingFor(_read).map((ScreenshotEntity s) => s.id),
      <String>['old', 'mid', 'new'],
    );
  });

  test('changing the intent drops any completion with it', () {
    // Having ticked off "reply" says nothing about whether the thing has been
    // bought, so the entity must not carry the old timestamp across.
    final ScreenshotEntity done = _shot(
      'a',
      intent: _reply,
      doneAt: DateTime(2026),
    );
    final ScreenshotEntity changed = done.copyWith(
      intent: const IntentState(ref: _buy),
    );
    expect(changed.intent!.ref, _buy);
    expect(changed.intent!.isWaiting, isTrue);
  });

  test('clearing the intent leaves none', () {
    final ScreenshotEntity cleared = _shot(
      'a',
      intent: _buy,
    ).copyWith(clearIntent: true);
    expect(cleared.intent, isNull);
    expect(cleared.isWaiting, isFalse);
  });
}
