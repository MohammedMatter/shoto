import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/subscription/data/data_sources/revenue_cat_data_source.dart';
import 'package:shoto/features/subscription/data/repositories_impl/subscription_repository_impl.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';

/// Pins the one decision every paid feature in the app depends on.
///
/// Worth a test of its own because this gate has been written backwards twice
/// already in this codebase — the paywall was shown to subscribers while free
/// users walked straight in, and static analysis is perfectly happy either
/// way. `getStatus()` is the single answer `ensurePremium`, the screenshot
/// cap, the folder cap and the settings card all read.
///
/// The RevenueCat data source here is real but unconfigured, which is exactly
/// the situation on a device today: no API key, so `getCustomerInfo()` returns
/// null without touching a platform channel. That makes the developer switch
/// the only thing that can grant premium — the case being tested.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  SubscriptionRepositoryImpl repositoryWith(DevAccess devAccess) {
    return SubscriptionRepositoryImpl(
      RevenueCatDataSource(),
      _StubAuthRepository(),
      devAccess,
    );
  }

  test('locked means free, so the paywall still appears', () async {
    final SubscriptionStatus status = await repositoryWith(
      DevAccess(),
    ).getStatus();

    expect(status.isPremium, isFalse);
    expect(status.isTesterAccess, isFalse);
  });

  test('unlocked grants premium to every gate', () async {
    final DevAccess devAccess = DevAccess();
    await devAccess.unlock(DevAccess.unlockCode);

    final SubscriptionStatus status = await repositoryWith(
      devAccess,
    ).getStatus();

    expect(status.isPremium, isTrue);
    expect(
      status.isTesterAccess,
      isTrue,
      reason: 'the UI has to be able to say this was not a real purchase',
    );
  });

  test('turning it off puts the paywall back', () async {
    final DevAccess devAccess = DevAccess();
    final SubscriptionRepositoryImpl repository = repositoryWith(devAccess);

    await devAccess.unlock(DevAccess.unlockCode);
    expect((await repository.getStatus()).isPremium, isTrue);

    await devAccess.lock();
    expect(
      (await repository.getStatus()).isPremium,
      isFalse,
      reason: 'otherwise the free tier can never be tested again',
    );
  });

  test('a wrong code never opens the gate', () async {
    final DevAccess devAccess = DevAccess();
    await devAccess.unlock('1111');

    expect((await repositoryWith(devAccess).getStatus()).isPremium, isFalse);
  });
}

class _StubAuthRepository implements AuthRepository {
  @override
  UserEntity? get currentUser => null;

  @override
  String get userId => 'local:test';

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  Future<UserEntity> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<UserEntity> signInWithApple() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
