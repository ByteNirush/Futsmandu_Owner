import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';

class OwnerPricingApi {
  OwnerPricingApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<List<OwnerPricingRule>> listPricingRules(String courtId) async {
    final response = await _apiClient.get(
      OwnerApiConfig.pricingRulesEndpoint(courtId),
    );
    final itemsRaw = response['items'];
    if (itemsRaw is! List) {
      return const [];
    }
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(OwnerPricingRule.fromJson)
        .toList(growable: false);
  }

  Future<OwnerPricingRule> createPricingRule({
    required String courtId,
    required String ruleType,
    required int priority,
    required int pricePaisa,
    required String modifier,
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    String? dateFrom,
    String? dateTo,
    int? hoursBefore,
  }) async {
    final response = await _apiClient.post(
      OwnerApiConfig.pricingRulesEndpoint(courtId),
      data: {
        'rule_type': ruleType,
        'priority': priority,
        'price': pricePaisa,
        'modifier': modifier,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        if (startTime != null && startTime.isNotEmpty) 'start_time': startTime,
        if (endTime != null && endTime.isNotEmpty) 'end_time': endTime,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (hoursBefore != null) 'hours_before': hoursBefore,
      },
    );

    return OwnerPricingRule.fromJson(response);
  }

  Future<OwnerPricingRule> updatePricingRule({
    required String ruleId,
    int? pricePaisa,
    String? modifier,
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    String? dateFrom,
    String? dateTo,
    int? hoursBefore,
    bool? isActive,
  }) async {
    final response = await _apiClient.put(
      OwnerApiConfig.pricingRuleEndpoint(ruleId),
      data: {
        if (pricePaisa != null) 'price': pricePaisa,
        if (modifier != null) 'modifier': modifier,
        if (daysOfWeek != null) 'days_of_week': daysOfWeek,
        if (startTime != null && startTime.isNotEmpty) 'start_time': startTime,
        if (endTime != null && endTime.isNotEmpty) 'end_time': endTime,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
        if (hoursBefore != null) 'hours_before': hoursBefore,
        if (isActive != null) 'is_active': isActive,
      },
    );

    return OwnerPricingRule.fromJson(response);
  }

  Future<void> deletePricingRule(String ruleId) async {
    await _apiClient.delete(OwnerApiConfig.pricingRuleEndpoint(ruleId));
  }

  Future<PricingPreviewResult> previewPrice({
    required String courtId,
    required DateTime date,
    required String time,
  }) async {
    final response = await _apiClient.get(
      OwnerApiConfig.pricingPreviewEndpoint(courtId),
      queryParameters: {
        'date': _toDateOnly(date),
        'time': time,
      },
    );

    return PricingPreviewResult.fromJson(response);
  }

  String _toDateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class OwnerPricingRule {
  OwnerPricingRule({
    required this.id,
    required this.ruleType,
    this.courtId,
    this.priority,
    this.pricePaisa,
    this.modifier,
    this.daysOfWeek = const [],
    this.startTime,
    this.endTime,
    this.dateFrom,
    this.dateTo,
    this.hoursBefore,
    this.isActive,
    this.createdAt,
  });

  final String id;
  final String ruleType;
  final String? courtId;
  final int? priority;
  final int? pricePaisa;
  final String? modifier;
  final List<int> daysOfWeek;
  final String? startTime;
  final String? endTime;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? hoursBefore;
  final bool? isActive;
  final DateTime? createdAt;

  factory OwnerPricingRule.fromJson(Map<String, dynamic> json) {
    return OwnerPricingRule(
      id: (json['id'] as String?) ?? '',
      courtId: json['court_id'] as String? ?? json['courtId'] as String?,
      ruleType: (json['rule_type'] as String?) ?? (json['ruleType'] as String?) ?? 'custom',
      priority: _asInt(json['priority']),
      pricePaisa: _asInt(json['price']),
      modifier: json['modifier'] as String?,
      daysOfWeek: _asIntList(json['days_of_week'] ?? json['daysOfWeek']),
      startTime: json['start_time'] as String? ?? json['startTime'] as String?,
      endTime: json['end_time'] as String? ?? json['endTime'] as String?,
      dateFrom: DateTime.tryParse((json['date_from'] as String?) ?? (json['dateFrom'] as String?) ?? ''),
      dateTo: DateTime.tryParse((json['date_to'] as String?) ?? (json['dateTo'] as String?) ?? ''),
      hoursBefore: _asInt(json['hours_before'] ?? json['hoursBefore']),
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool?,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? (json['createdAt'] as String?) ?? ''),
    );
  }

  String get title => ruleType.toUpperCase();

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<int> _asIntList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((entry) => entry is int ? entry : int.tryParse(entry.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
}

class PricingPreviewResult {
  PricingPreviewResult({
    required this.pricePaisa,
    required this.displayPrice,
    required this.ruleId,
    required this.ruleType,
    required this.date,
    required this.time,
  });

  final int pricePaisa;
  final String displayPrice;
  final String? ruleId;
  final String? ruleType;
  final String date;
  final String time;

  factory PricingPreviewResult.fromJson(Map<String, dynamic> json) {
    return PricingPreviewResult(
      pricePaisa: _asInt(json['price']),
      displayPrice: (json['displayPrice'] as String?) ?? '',
      ruleId: json['ruleId'] as String?,
      ruleType: json['ruleType'] as String?,
      date: (json['date'] as String?) ?? '',
      time: (json['time'] as String?) ?? '',
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
