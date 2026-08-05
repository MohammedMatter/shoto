import 'package:flutter/foundation.dart';
import 'package:shoto/core/utils/screenshot_intent.dart';
import 'package:shoto/features/screenshots/domain/use_cases/create_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/delete_custom_intent_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_custom_intents_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/get_intent_ids_by_recent_use_use_case.dart';
import 'package:shoto/features/screenshots/domain/use_cases/update_custom_intent_use_case.dart';

/// Every verb available to this account, and the order they belong in.
///
/// **A `ChangeNotifier` in the service locator rather than state on a bloc,
/// because the picker outlives any one bloc.** The same row of chips appears
/// on the quick-save sheet — which is reached from the share sheet, from a
/// notification and from the widget, none of which have a `ScreenshotsBloc`
/// above them — and inside the library, which does. Hanging the catalog off
/// the bloc would mean the save sheet either loses custom intents or grows a
/// second, divergent copy of this logic.
///
/// Loaded once and then held. There are at most a couple of dozen rows here
/// and they change only when the user edits them, so re-reading the table
/// every time a sheet opens buys nothing and costs a visible flash of five
/// built-in chips before the user's own arrive.
class IntentCatalog extends ChangeNotifier {
  final GetCustomIntentsUseCase _getCustomIntents;
  final GetIntentIdsByRecentUseUseCase _getIntentIdsByRecentUse;
  final CreateCustomIntentUseCase _createCustomIntent;
  final UpdateCustomIntentUseCase _updateCustomIntent;
  final DeleteCustomIntentUseCase _deleteCustomIntent;

  IntentCatalog({
    required GetCustomIntentsUseCase getCustomIntentsUseCase,
    required GetIntentIdsByRecentUseUseCase getIntentIdsByRecentUseUseCase,
    required CreateCustomIntentUseCase createCustomIntentUseCase,
    required UpdateCustomIntentUseCase updateCustomIntentUseCase,
    required DeleteCustomIntentUseCase deleteCustomIntentUseCase,
  }) : _getCustomIntents = getCustomIntentsUseCase,
       _getIntentIdsByRecentUse = getIntentIdsByRecentUseUseCase,
       _createCustomIntent = createCustomIntentUseCase,
       _updateCustomIntent = updateCustomIntentUseCase,
       _deleteCustomIntent = deleteCustomIntentUseCase;

  /// How many chips the compact row shows before `+`.
  ///
  /// Five is not a design preference, it is the number that fits a narrow
  /// phone in the longest supported language without the row having to scroll
  /// — and a row you must scroll to see the rest of is a row whose rest does
  /// not exist.
  static const int frontRowSize = 5;

  /// Bumped every time a custom intent is deleted.
  ///
  /// Separate from [notifyListeners] because deletion is the only edit that
  /// reaches *outside* this catalog: it clears the intent off every screenshot
  /// that carried it, inside the database, under whatever library state is
  /// currently loaded. Renaming and creating touch nothing but this list, and
  /// making the library reload for those would spend a full gallery read on a
  /// typo correction — the loaded state is already correct, since a rename
  /// changes the label the chips read from and nothing else.
  final ValueNotifier<int> deletions = ValueNotifier<int>(0);

  List<CustomIntent> _customIntents = const <CustomIntent>[];
  List<String> _recentIds = const <String>[];
  bool _isLoaded = false;

  List<CustomIntent> get customIntents => _customIntents;

  /// False until the first read finishes. The picker shows the built-in front
  /// row meanwhile, which is what a new account would see anyway.
  bool get isLoaded => _isLoaded;

  /// Everything, in the order the full picker lists it: the verbs SHOTO ships
  /// first, then the user's own. Not the front row's order — see [frontRow].
  List<IntentRef> get all => <IntentRef>[
    for (final ScreenshotIntent intent in ScreenshotIntent.values)
      BuiltInIntent(intent),
    ..._customIntents,
  ];

  /// The chips worth showing without asking for another tap.
  ///
  /// Ordered by when this person last used each one, so the row becomes theirs
  /// within a few days of use without a settings screen ever mentioning it. A
  /// fresh account has no history and gets the first five built-ins, which is
  /// exactly the row that shipped before custom intents existed.
  ///
  /// [selected] is always present, even if it has not been used in months:
  /// a picker that hides the answer currently showing would read as having
  /// lost it.
  List<IntentRef> frontRow({IntentRef? selected}) {
    final Map<String, IntentRef> available = <String, IntentRef>{
      for (final IntentRef ref in all) ref.id: ref,
    };

    final List<IntentRef> ordered = <IntentRef>[
      // Ids that no longer resolve — a deleted custom intent still named in
      // the history — are skipped rather than shown as a blank chip.
      for (final String id in _recentIds)
        if (available.remove(id) case final IntentRef ref) ref,
      ...available.values,
    ];

    if (selected != null) {
      ordered
        ..removeWhere((IntentRef ref) => ref == selected)
        ..insert(0, selected);
    }

    return ordered.take(frontRowSize).toList();
  }

  /// The intent with this id, or null once it has been deleted.
  IntentRef? resolve(String id) {
    for (final IntentRef ref in all) {
      if (ref.id == id) return ref;
    }
    return null;
  }

  /// Reads the table. Safe to call from every `initState` that needs the
  /// catalog — after the first success it does nothing.
  Future<void> load() async {
    if (_isLoaded) return;
    await refresh();
  }

  /// Re-reads unconditionally, after the user has changed something or after
  /// enough intents have been set that the front row's order is stale.
  Future<void> refresh() async {
    try {
      final List<CustomIntent> custom = await _getCustomIntents();
      final List<String> recent = await _getIntentIdsByRecentUse();
      _customIntents = custom;
      _recentIds = recent;
      _isLoaded = true;
      notifyListeners();
    } catch (error) {
      // No account signed in yet, or the database is not open. The built-in
      // row is a complete, working picker on its own, so this is a degraded
      // catalog rather than a broken screen — and the next call will retry,
      // since nothing was marked loaded.
      debugPrint('SHOTO: intent catalog not loaded — $error');
    }
  }

  Future<CustomIntent> create({
    required String label,
    required String iconKey,
  }) async {
    final CustomIntent created = await _createCustomIntent(
      label: label,
      iconKey: iconKey,
    );
    // Appended locally rather than re-read: the row is already known exactly,
    // and a full refresh here would drop the new chip for a frame right as the
    // user is looking at it.
    _customIntents = <CustomIntent>[..._customIntents, created];
    notifyListeners();
    return created;
  }

  Future<void> update({
    required String id,
    required String label,
    required String iconKey,
  }) async {
    await _updateCustomIntent(id: id, label: label, iconKey: iconKey);
    _customIntents = <CustomIntent>[
      for (final CustomIntent intent in _customIntents)
        if (intent.id == id)
          CustomIntent(
            id: intent.id,
            label: label,
            iconKey: iconKey,
            sortOrder: intent.sortOrder,
          )
        else
          intent,
    ];
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _deleteCustomIntent(id);
    _customIntents = _customIntents
        .where((CustomIntent intent) => intent.id != id)
        .toList();
    notifyListeners();
    deletions.value++;
  }

  /// Forgets everything, for a sign-out. The next [load] reads the incoming
  /// account's own verbs instead of serving the previous one's.
  void clear() {
    _customIntents = const <CustomIntent>[];
    _recentIds = const <String>[];
    _isLoaded = false;
    notifyListeners();
  }
}
