import 'package:shoto/core/localization/app_message.dart';
import 'package:shoto/core/utils/filing_rules.dart';
import 'package:shoto/features/rules/domain/entities/rule_run_result.dart';

abstract class RulesState {}

class RulesInitialState extends RulesState {}

class RulesLoadingState extends RulesState {}

class RulesLoadedState extends RulesState {
  final List<FilingRule> rules;

  /// Set while a library-wide pass is in flight, so the button can show
  /// progress instead of looking frozen on a big library.
  final int? runProgress;
  final int? runTotal;

  /// The outcome of the last pass, shown once and then cleared by the next
  /// action — a result that lingers stops meaning anything.
  final RuleRunResult? lastRun;

  RulesLoadedState({
    required this.rules,
    this.runProgress,
    this.runTotal,
    this.lastRun,
  });

  bool get isRunning => runProgress != null;

  RulesLoadedState copyWith({
    List<FilingRule>? rules,
    int? runProgress,
    int? runTotal,
    RuleRunResult? lastRun,
    bool clearRun = false,
    bool clearLastRun = false,
  }) {
    return RulesLoadedState(
      rules: rules ?? this.rules,
      runProgress: clearRun ? null : (runProgress ?? this.runProgress),
      runTotal: clearRun ? null : (runTotal ?? this.runTotal),
      lastRun: clearLastRun ? null : (lastRun ?? this.lastRun),
    );
  }
}

class RulesErrorState extends RulesState {
  final AppMessage message;
  RulesErrorState(this.message);
}
