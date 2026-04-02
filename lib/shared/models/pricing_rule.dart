import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_rule.freezed.dart';
part 'pricing_rule.g.dart';

/// Represents supported pricing strategy types.
enum PricingRuleType {
  base,
  peak,
  offPeak,
  holiday,
  lastMinute,
}

/// Represents a pricing rule applied to a court.
@freezed
abstract class PricingRule with _$PricingRule {
  const factory PricingRule({
    required String id,
    required String courtId,
    required PricingRuleType ruleType,
    required int priority,
    required List<int> daysOfWeek,
    required DateTime timeFrom,
    required DateTime timeTo,
    required DateTime dateFrom,
    required DateTime dateTo,
    required double priceNpr,
  }) = _PricingRule;

  factory PricingRule.fromJson(Map<String, dynamic> json) =>
      _$PricingRuleFromJson(json);
}