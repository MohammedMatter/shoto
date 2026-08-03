import 'package:shoto/core/utils/filing_rules.dart';

abstract class RulesEvent {}

class LoadRulesEvent extends RulesEvent {}

class CreateRuleEvent extends RulesEvent {
  final String name;
  final int folderId;
  final List<RuleCondition> conditions;
  final RuleMatch match;

  CreateRuleEvent({
    required this.name,
    required this.folderId,
    required this.conditions,
    required this.match,
  });
}

class UpdateRuleEvent extends RulesEvent {
  final int ruleId;
  final String name;
  final int folderId;
  final List<RuleCondition> conditions;
  final RuleMatch match;

  UpdateRuleEvent({
    required this.ruleId,
    required this.name,
    required this.folderId,
    required this.conditions,
    required this.match,
  });
}

/// Moves a rule one place up or down the priority order.
///
/// One step at a time rather than a drag: the list is short, the cards are
/// tall, and a drag inside the scrolling list this screen already has is the
/// kind of gesture that fights the scroll on every attempt.
class MoveRuleEvent extends RulesEvent {
  final int ruleId;
  final bool up;

  MoveRuleEvent(this.ruleId, {required this.up});
}

class DeleteRuleEvent extends RulesEvent {
  final int ruleId;
  DeleteRuleEvent(this.ruleId);
}

class SetRuleEnabledEvent extends RulesEvent {
  final int ruleId;
  final bool isEnabled;
  SetRuleEnabledEvent(this.ruleId, this.isEnabled);
}

class RunRulesEvent extends RulesEvent {}
