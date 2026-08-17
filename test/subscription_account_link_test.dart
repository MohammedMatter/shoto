import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/services/dev_access.dart';
import 'package:shoto/core/services/pro_status.dart';
import 'package:shoto/features/auth/domain/entities/user_entity.dart';
import 'package:shoto/features/auth/domain/repositories/auth_repository.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_apple_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_in_with_google_use_case.dart';
import 'package:shoto/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_event.dart';
import 'package:shoto/features/auth/presentation/bloc/auth_state.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_package_info.dart';
import 'package:shoto/features/subscription/domain/entities/subscription_status.dart';
import 'package:shoto/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:shoto/features/subscription/domain/use_cases/attach_subscription_account_use_case.dart';
import 'package:shoto/features/subscription/domain/use_cases/detach_subscription_account_use_case.dart';

/// The only thing signing in does for the user.
///
/// **This is a regression test for a feature that was written and then never
/// called.** `attachAccount` existed all the way down to `Purchases.logIn`,
/// with comments explaining precisely which dead end it solves, and no caller
/// anywhere in `lib/`. The app asked every user for a Google account before
/// showing them anything and handed back a name on the settings card.
///
/// Nothing about that was visible: the code compiled, the sign-in worked, the
/// settings screen looked right. The only way to catch it is to assert that
/// the call actually happens, which is what this does.
///
/// The dead end itself: Google does not move a subscription between Google
/// accounts. Buy Pro, change phone *and* change Google account, and "Restore
/// purchases" asks the store about somebody it has never heard of. Attaching
/// the entitlement to a Shoto account puts it somewhere the store does not
/// own.
class _RecordingSubscriptionRepository implements SubscriptionRepository {
  final List<String> attached = <String>[];
  int detachCalls = 0;

  /// When true, both calls throw — the store being briefly unreachable.
  bool isFailing = false;

  @override
  Future<SubscriptionStatus> attachAccount(String accountId) async {
    if (isFailing) throw Exception('RevenueCat unreachable');
    attached.add(accountId);
    return SubscriptionStatus.free;
  }

  @override
  Future<SubscriptionStatus> detachAccount() async {
    if (isFailing) throw Exception('RevenueCat unreachable');
    detachCalls++;
    return SubscriptionStatus.free;
  }

  @override
  Future<SubscriptionStatus> getStatus() async => SubscriptionStatus.free;

  @override
  Stream<SubscriptionStatus> get statusChanges => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<SubscriptionPackageInfo>> getOfferings() async => const [];

  @override
  Future<SubscriptionStatus> purchase(SubscriptionPackageInfo package) async =>
      SubscriptionStatus.free;

  @override
  Future<SubscriptionStatus> restorePurchases() async =>
      SubscriptionStatus.free;
}

/// Signs in as one fixed person, or refuses to.
class _FakeAuthRepository implements AuthRepository {
  static const UserEntity person = UserEntity(
    id: 'shoto-account-42',
    email: 'someone@example.com',
  );

  bool signInFails = false;
  int signOutCalls = 0;

  @override
  Future<UserEntity> signInWithGoogle() async {
    if (signInFails) throw Exception('sign-in refused');
    return person;
  }

  @override
  Future<UserEntity> signInWithApple() async => person;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  UserEntity? get currentUser => person;

  @override
  String get userId => 'local:test-device';
}

void main() {
  late _RecordingSubscriptionRepository subscriptions;
  late _FakeAuthRepository auth;
  late AuthBloc bloc;

  setUp(() {
    subscriptions = _RecordingSubscriptionRepository();
    auth = _FakeAuthRepository();
    bloc = AuthBloc(
      signInWithGoogleUseCase: SignInWithGoogleUseCase(auth),
      signInWithAppleUseCase: SignInWithAppleUseCase(auth),
      signOutUseCase: SignOutUseCase(auth),
      attachSubscriptionAccountUseCase: AttachSubscriptionAccountUseCase(
        subscriptions,
      ),
      detachSubscriptionAccountUseCase: DetachSubscriptionAccountUseCase(
        subscriptions,
      ),
      proStatus: ProStatus(subscriptions, DevAccess()),
    );
  });

  tearDown(() async => bloc.close());

  test('signing in hands the entitlement to the account', () async {
    bloc.add(SignInWithGoogleEvent());
    await bloc.stream.firstWhere((AuthState s) => s is! AuthLoadingState);

    // The account id, not the device id — the whole point is an identity the
    // store does not own.
    expect(subscriptions.attached, <String>['shoto-account-42']);
  });

  test('signing in with Apple does the same', () async {
    bloc.add(SignInWithAppleEvent());
    await bloc.stream.firstWhere((AuthState s) => s is! AuthLoadingState);

    expect(subscriptions.attached, <String>['shoto-account-42']);
  });

  test('signing out leaves the device anonymous again', () async {
    bloc.add(SignOutRequestedEvent());
    await bloc.stream.firstWhere((AuthState s) => s is AuthSignedOutState);

    // Without this the next person to sign in on the same phone inherits the
    // previous account's Pro.
    expect(subscriptions.detachCalls, 1);
    expect(auth.signOutCalls, 1);
  });

  test('a store that will not answer does not fail the sign-in', () async {
    subscriptions.isFailing = true;

    bloc.add(SignInWithGoogleEvent());
    final AuthState state = await bloc.stream.firstWhere(
      (AuthState s) => s is! AuthLoadingState,
    );

    // Sign-in is the gate in front of the whole app. Reporting a failure here
    // would mean RevenueCat being unreachable for a moment locks somebody out
    // of their own screenshots, over something they cannot act on and would
    // not understand.
    expect(state, isA<AuthSuccessState>());
  });

  test('a store that will not answer does not trap the user signed in', () async {
    subscriptions.isFailing = true;

    bloc.add(SignOutRequestedEvent());
    final AuthState state = await bloc.stream.firstWhere(
      (AuthState s) => s is! AuthLoadingState,
    );

    expect(state, isA<AuthSignedOutState>());
  });

  test('a refused sign-in attaches nothing', () async {
    auth.signInFails = true;

    bloc.add(SignInWithGoogleEvent());
    await bloc.stream.firstWhere((AuthState s) => s is! AuthLoadingState);

    expect(subscriptions.attached, isEmpty);
  });
}
