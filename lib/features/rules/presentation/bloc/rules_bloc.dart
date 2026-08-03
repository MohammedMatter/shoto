import 'package:shoto/core/localization/app_message.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';
import 'package:shoto/features/rules/domain/use_cases/create_rule_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/delete_rule_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/get_rules_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/reorder_rules_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/update_rule_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/run_rules_on_library_use_case.dart';
import 'package:shoto/features/rules/domain/use_cases/set_rule_enabled_use_case.dart';
import 'package:shoto/features/rules/presentation/bloc/rules_event.dart';
import 'package:shoto/features/rules/presentation/bloc/rules_state.dart';

class RulesBloc extends Bloc<RulesEvent, RulesState> {
  final GetRulesUseCase getRulesUseCase;
  final CreateRuleUseCase createRuleUseCase;
  final UpdateRuleUseCase updateRuleUseCase;
  final ReorderRulesUseCase reorderRulesUseCase;
  final DeleteRuleUseCase deleteRuleUseCase;
  final SetRuleEnabledUseCase setRuleEnabledUseCase;
  final RunRulesOnLibraryUseCase runRulesOnLibraryUseCase;

  RulesBloc({
    required this.getRulesUseCase,
    required this.createRuleUseCase,
    required this.updateRuleUseCase,
    required this.reorderRulesUseCase,
    required this.deleteRuleUseCase,
    required this.setRuleEnabledUseCase,
    required this.runRulesOnLibraryUseCase,
  }) : super(RulesInitialState()) {
    on<LoadRulesEvent>(_onLoad);
    on<CreateRuleEvent>(_onCreate);
    on<UpdateRuleEvent>(_onUpdate);
    on<MoveRuleEvent>(_onMove);
    on<DeleteRuleEvent>(_onDelete);
    on<SetRuleEnabledEvent>(_onSetEnabled);
    on<RunRulesEvent>(_onRun);
  }

  Future<void> _onLoad(LoadRulesEvent event, Emitter<RulesState> emit) async {
    emit(RulesLoadingState());
    try {
      emit(RulesLoadedState(rules: await getRulesUseCase()));
    } catch (_) {
      emit(RulesErrorState(AppMessage.loadRules));
    }
  }

  Future<void> _onCreate(
    CreateRuleEvent event,
    Emitter<RulesState> emit,
  ) async {
    await createRuleUseCase(
      name: event.name,
      folderId: event.folderId,
      conditions: event.conditions,
      match: event.match,
    );
    await _reload(emit);
  }

  Future<void> _onUpdate(
    UpdateRuleEvent event,
    Emitter<RulesState> emit,
  ) async {
    await updateRuleUseCase(
      ruleId: event.ruleId,
      name: event.name,
      folderId: event.folderId,
      conditions: event.conditions,
      match: event.match,
    );
    await _reload(emit);
  }

  /// Moves one rule a single place and writes the whole order back.
  ///
  /// The list is reordered in the state first and the write follows, the same
  /// way [_onSetEnabled] flips the switch before persisting: this is a direct
  /// manipulation, and a card that only jumps once the database answers reads
  /// as the tap not registering.
  Future<void> _onMove(MoveRuleEvent event, Emitter<RulesState> emit) async {
    final RulesState current = state;
    if (current is! RulesLoadedState) return;

    final List<FilingRule> rules = List.of(current.rules);
    final int from = rules.indexWhere((rule) => rule.id == event.ruleId);
    if (from < 0) return;

    final int to = event.up ? from - 1 : from + 1;
    // Silently ignored rather than guarded at the call site as well: the
    // arrows are already hidden at the ends, and a bloc that trusts its own
    // bounds is one fewer place for the two to disagree.
    if (to < 0 || to >= rules.length) return;

    rules.insert(to, rules.removeAt(from));
    emit(current.copyWith(rules: rules, clearLastRun: true));

    await reorderRulesUseCase([for (final FilingRule rule in rules) rule.id]);
  }

  Future<void> _onDelete(
    DeleteRuleEvent event,
    Emitter<RulesState> emit,
  ) async {
    await deleteRuleUseCase(event.ruleId);
    await _reload(emit);
  }

  Future<void> _onSetEnabled(
    SetRuleEnabledEvent event,
    Emitter<RulesState> emit,
  ) async {
    final RulesState current = state;
    if (current is! RulesLoadedState) return;

    // Flipped in the state first so the switch moves under the finger; the
    // write is fast but not instant, and a switch that lags reads as broken.
    emit(
      current.copyWith(
        rules: [
          for (final FilingRule rule in current.rules)
            if (rule.id == event.ruleId)
              FilingRule(
                id: rule.id,
                name: rule.name,
                folderId: rule.folderId,
                conditions: rule.conditions,
                match: rule.match,
                isEnabled: event.isEnabled,
              )
            else
              rule,
        ],
        clearLastRun: true,
      ),
    );
    await setRuleEnabledUseCase(event.ruleId, event.isEnabled);
  }

  Future<void> _onRun(RunRulesEvent event, Emitter<RulesState> emit) async {
    final RulesState current = state;
    if (current is! RulesLoadedState || current.isRunning) return;

    emit(current.copyWith(runProgress: 0, runTotal: 0, clearLastRun: true));

    final RuleRunResult result = await runRulesOnLibraryUseCase(
      onProgress: (processed, total) {
        if (isClosed) return;
        final RulesState now = state;
        if (now is! RulesLoadedState) return;
        emit(now.copyWith(runProgress: processed, runTotal: total));
      },
    );

    if (isClosed) return;
    final RulesState after = state;
    if (after is! RulesLoadedState) return;
    emit(after.copyWith(clearRun: true, lastRun: result));
  }

  Future<void> _reload(Emitter<RulesState> emit) async {
    final RulesState current = state;
    final List<FilingRule> rules = await getRulesUseCase();
    emit(
      current is RulesLoadedState
          ? current.copyWith(rules: rules, clearLastRun: true)
          : RulesLoadedState(rules: rules),
    );
  }
}
