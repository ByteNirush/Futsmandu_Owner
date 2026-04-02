// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PricingRule _$PricingRuleFromJson(Map<String, dynamic> json) => _PricingRule(
  id: json['id'] as String,
  courtId: json['courtId'] as String,
  ruleType: $enumDecode(_$PricingRuleTypeEnumMap, json['ruleType']),
  priority: (json['priority'] as num).toInt(),
  daysOfWeek: (json['daysOfWeek'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
  timeFrom: DateTime.parse(json['timeFrom'] as String),
  timeTo: DateTime.parse(json['timeTo'] as String),
  dateFrom: DateTime.parse(json['dateFrom'] as String),
  dateTo: DateTime.parse(json['dateTo'] as String),
  priceNpr: (json['priceNpr'] as num).toDouble(),
);

Map<String, dynamic> _$PricingRuleToJson(_PricingRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courtId': instance.courtId,
      'ruleType': _$PricingRuleTypeEnumMap[instance.ruleType]!,
      'priority': instance.priority,
      'daysOfWeek': instance.daysOfWeek,
      'timeFrom': instance.timeFrom.toIso8601String(),
      'timeTo': instance.timeTo.toIso8601String(),
      'dateFrom': instance.dateFrom.toIso8601String(),
      'dateTo': instance.dateTo.toIso8601String(),
      'priceNpr': instance.priceNpr,
    };

const _$PricingRuleTypeEnumMap = {
  PricingRuleType.base: 'base',
  PricingRuleType.peak: 'peak',
  PricingRuleType.offPeak: 'offPeak',
  PricingRuleType.holiday: 'holiday',
  PricingRuleType.lastMinute: 'lastMinute',
};
