import 'package:flutter_test/flutter_test.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/repositories/screenshot_repository.dart';
import 'package:shoto/features/screenshots/domain/use_cases/create_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_custom_intents_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_intent_ids_by_recent_use_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/update_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/presentation/bloc/intent_catalog.dart';

/// **The picker does not rearrange itself, for any reason a tap can give it.**
///
/// The front row is ordered by what this person reaches for most, which is a
/// property of their history — not of the tap they just made. Selecting the
/// third chip used to move it to first and slide the other four sideways,
/// under the finger that had only just pressed it. Two costs, both real: the
/// row appears to lose your place, and the *next* tap lands on a different
/// verb than the one the eye had already chosen.
///
/// Picking a folder does not reorder the folders. This is the same kind of
/// choice, and it now behaves the same way.
void main() {
  IntentCatalog build(_FakeRepository repository) => IntentCatalog(
    getCustomIntentsUseCase: GetCustomIntentsUseCase(repository),
    getIntentIdsByRecentUseUseCase: GetIntentIdsByRecentUseUseCase(repository),
    createCustomIntentUseCase: CreateCustomIntentUseCase(repository),
    updateCustomIntentUseCase: UpdateCustomIntentUseCase(repository),
    deleteCustomIntentUseCase: DeleteCustomIntentUseCase(repository),
  );

  test('the row is the same list however it is asked', () async {
    // The signature is the assertion here: `frontRow` takes nothing, so there
    // is no selection for it to react to and no way to reintroduce one without
    // this test being rewritten on purpose.
    final IntentCatalog catalog = build(_FakeRepository());
    await catalog.load();

    final List<IntentRef> first = catalog.frontRow();
    final List<IntentRef> again = catalog.frontRow();

    expect(first, again);
    expect(first.length, IntentCatalog.frontRowSize);
  });

  test('the row follows history, and history alone', () async {
    // Recency is the one thing allowed to order this. Asserted with an
    // out-of-the-way verb pushed to the front by use, which is exactly the
    // move a *selection* must no longer be able to make.
    final ScreenshotIntent recent = ScreenshotIntent.values.last;
    final IntentCatalog catalog = build(
      _FakeRepository(recentIds: <String>[recent.id]),
    );
    await catalog.load();

    expect(catalog.frontRow().first, BuiltInIntent(recent));
  });

  test('every chip on the row is one the full picker also lists', () async {
    // Guards against the row inventing an entry — the old promotion inserted
    // one by hand, and this is what stops the next shortcut from doing so.
    final IntentCatalog catalog = build(_FakeRepository());
    await catalog.load();

    for (final IntentRef ref in catalog.frontRow()) {
      expect(catalog.all, contains(ref));
    }
  });
}

/// No custom intents, and whatever history the test asks for.
class _FakeRepository implements ScreenshotRepository {
  final List<String> recentIds;

  _FakeRepository({this.recentIds = const <String>[]});

  @override
  Future<List<CustomIntent>> getCustomIntents() async => const <CustomIntent>[];

  @override
  Future<List<String>> getIntentIdsByRecentUse() async => recentIds;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'ScreenshotRepository.${invocation.memberName} was not expected here',
  );
}
