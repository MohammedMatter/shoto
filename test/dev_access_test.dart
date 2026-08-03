import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';

/// The developer unlock hands out every paid feature, so the two things worth
/// pinning are that only the right code opens it and that turning it off
/// actually turns it off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts locked', () async {
    final DevAccess access = DevAccess();
    await access.load();
    expect(access.isUnlocked, isFalse);
  });

  test('the right code unlocks', () async {
    final DevAccess access = DevAccess();
    expect(await access.unlock(DevAccess.unlockCode), isTrue);
    expect(access.isUnlocked, isTrue);
  });

  test('a wrong code changes nothing', () async {
    final DevAccess access = DevAccess();
    for (final String wrong in ['', '1234', '258', '25801', 'abcd', '0852']) {
      expect(await access.unlock(wrong), isFalse, reason: wrong);
      expect(access.isUnlocked, isFalse, reason: wrong);
    }
  });

  test('a wrong code cannot revoke an unlock already granted', () async {
    final DevAccess access = DevAccess();
    await access.unlock(DevAccess.unlockCode);
    expect(await access.unlock('0000'), isFalse);
    expect(access.isUnlocked, isTrue);
  });

  test('surrounding whitespace is forgiven', () async {
    final DevAccess access = DevAccess();
    expect(await access.unlock('  ${DevAccess.unlockCode} '), isTrue);
  });

  test('survives a restart', () async {
    await DevAccess().unlock(DevAccess.unlockCode);

    final DevAccess afterRestart = DevAccess();
    await afterRestart.load();
    expect(afterRestart.isUnlocked, isTrue);
  });

  test('locking again is persisted too', () async {
    final DevAccess access = DevAccess();
    await access.unlock(DevAccess.unlockCode);
    await access.lock();
    expect(access.isUnlocked, isFalse);

    final DevAccess afterRestart = DevAccess();
    await afterRestart.load();
    expect(
      afterRestart.isUnlocked,
      isFalse,
      reason: 'a stale "true" on disk would silently re-enable premium',
    );
  });

  test('notifies listeners so the settings card can re-ask', () async {
    final DevAccess access = DevAccess();
    int notifications = 0;
    access.addListener(() => notifications++);

    await access.unlock(DevAccess.unlockCode);
    await access.lock();

    expect(notifications, 2);
  });

  test('the code is four digits, as the prompt promises', () {
    expect(DevAccess.unlockCode, matches(RegExp(r'^\d{4}$')));
  });
}
