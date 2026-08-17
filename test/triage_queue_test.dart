import 'package:flutter_test/flutter_test.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/app_preferences.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_new_captures_use_case.dart';

/// The two rules that make reading the device's Screenshots album defensible.
///
/// Both of them are one `if` away from being wrong, in a feature whose whole
/// justification is that it does exactly what it says:
///
/// 1. **Nothing is read until the user says so.** A regression here is not a
///    bug, it is the app doing the one thing its own privacy note promises it
///    does not do.
/// 2. **The watermark only ever moves forward.** It is what stops a decided
///    capture from coming back, and a queue that re-asks is a queue people
///    learn to ignore.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing is read while the queue is switched off', () async {
    final AppPreferences preferences = AppPreferences();
    await preferences.load();

    final _RecordingRepository repository = _RecordingRepository();
    final List<AssetEntity> captures = await GetNewCapturesUseCase(
      repository,
      preferences,
    )();

    expect(captures, isEmpty);
    expect(
      repository.reads,
      0,
      reason: 'the gallery was read without the user having asked for it',
    );
  });

  test('the queue is read once it is switched on', () async {
    final AppPreferences preferences = AppPreferences();
    await preferences.load();
    await preferences.setTriageEnabled(true);

    final _RecordingRepository repository = _RecordingRepository();
    await GetNewCapturesUseCase(repository, preferences)();

    expect(repository.reads, 1);
  });

  test('answering the question records that it was asked', () async {
    final AppPreferences preferences = AppPreferences();
    await preferences.load();
    expect(preferences.triageAsked, isFalse);

    // Declining has to count as an answer, or the invitation comes back on
    // the next launch and the app is nagging.
    await preferences.setTriageEnabled(false);
    expect(preferences.triageAsked, isTrue);
    expect(preferences.triageEnabled, isFalse);
  });

  test('the watermark never moves backwards', () async {
    final AppPreferences preferences = AppPreferences();
    await preferences.load();

    // Compared in milliseconds because that is the resolution the watermark
    // is stored at — `DateTime.now()` carries microseconds a preference key
    // full of integers cannot.
    final DateTime later = DateTime.now().add(const Duration(hours: 2));
    await preferences.advanceTriageSince(later);
    expect(
      preferences.triageSince.millisecondsSinceEpoch,
      later.millisecondsSinceEpoch,
    );

    await preferences.advanceTriageSince(
      later.subtract(const Duration(hours: 1)),
    );
    expect(
      preferences.triageSince.millisecondsSinceEpoch,
      later.millisecondsSinceEpoch,
      reason: 'a decided capture would be offered again',
    );
  });

  test('the watermark starts at now, not at the beginning of time', () async {
    final DateTime before = DateTime.now();
    final AppPreferences preferences = AppPreferences();
    await preferences.load();

    expect(
      preferences.triageSince.isBefore(before.subtract(const Duration(days: 1))),
      isFalse,
      reason: 'switching this on would offer every screenshot ever taken',
    );
  });
}

/// Counts reads instead of touching a gallery. `implements` rather than
/// `extends` so none of the real collaborators have to exist.
class _RecordingRepository implements ScreenshotRepository {
  int reads = 0;

  @override
  Future<List<AssetEntity>> getNewCaptures({required DateTime since}) async {
    reads++;
    return const [];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
