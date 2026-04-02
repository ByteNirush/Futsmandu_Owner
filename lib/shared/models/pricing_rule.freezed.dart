// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pricing_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PricingRule {

 String get id; String get courtId; PricingRuleType get ruleType; int get priority; List<int> get daysOfWeek; DateTime get timeFrom; DateTime get timeTo; DateTime get dateFrom; DateTime get dateTo; double get priceNpr;
/// Create a copy of PricingRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricingRuleCopyWith<PricingRule> get copyWith => _$PricingRuleCopyWithImpl<PricingRule>(this as PricingRule, _$identity);

  /// Serializes this PricingRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricingRule&&(identical(other.id, id) || other.id == id)&&(identical(other.courtId, courtId) || other.courtId == courtId)&&(identical(other.ruleType, ruleType) || other.ruleType == ruleType)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.daysOfWeek, daysOfWeek)&&(identical(other.timeFrom, timeFrom) || other.timeFrom == timeFrom)&&(identical(other.timeTo, timeTo) || other.timeTo == timeTo)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.priceNpr, priceNpr) || other.priceNpr == priceNpr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courtId,ruleType,priority,const DeepCollectionEquality().hash(daysOfWeek),timeFrom,timeTo,dateFrom,dateTo,priceNpr);

@override
String toString() {
  return 'PricingRule(id: $id, courtId: $courtId, ruleType: $ruleType, priority: $priority, daysOfWeek: $daysOfWeek, timeFrom: $timeFrom, timeTo: $timeTo, dateFrom: $dateFrom, dateTo: $dateTo, priceNpr: $priceNpr)';
}


}

/// @nodoc
abstract mixin class $PricingRuleCopyWith<$Res>  {
  factory $PricingRuleCopyWith(PricingRule value, $Res Function(PricingRule) _then) = _$PricingRuleCopyWithImpl;
@useResult
$Res call({
 String id, String courtId, PricingRuleType ruleType, int priority, List<int> daysOfWeek, DateTime timeFrom, DateTime timeTo, DateTime dateFrom, DateTime dateTo, double priceNpr
});




}
/// @nodoc
class _$PricingRuleCopyWithImpl<$Res>
    implements $PricingRuleCopyWith<$Res> {
  _$PricingRuleCopyWithImpl(this._self, this._then);

  final PricingRule _self;
  final $Res Function(PricingRule) _then;

/// Create a copy of PricingRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? courtId = null,Object? ruleType = null,Object? priority = null,Object? daysOfWeek = null,Object? timeFrom = null,Object? timeTo = null,Object? dateFrom = null,Object? dateTo = null,Object? priceNpr = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courtId: null == courtId ? _self.courtId : courtId // ignore: cast_nullable_to_non_nullable
as String,ruleType: null == ruleType ? _self.ruleType : ruleType // ignore: cast_nullable_to_non_nullable
as PricingRuleType,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,daysOfWeek: null == daysOfWeek ? _self.daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,timeFrom: null == timeFrom ? _self.timeFrom : timeFrom // ignore: cast_nullable_to_non_nullable
as DateTime,timeTo: null == timeTo ? _self.timeTo : timeTo // ignore: cast_nullable_to_non_nullable
as DateTime,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime,priceNpr: null == priceNpr ? _self.priceNpr : priceNpr // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PricingRule].
extension PricingRulePatterns on PricingRule {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PricingRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PricingRule() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PricingRule value)  $default,){
final _that = this;
switch (_that) {
case _PricingRule():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PricingRule value)?  $default,){
final _that = this;
switch (_that) {
case _PricingRule() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String courtId,  PricingRuleType ruleType,  int priority,  List<int> daysOfWeek,  DateTime timeFrom,  DateTime timeTo,  DateTime dateFrom,  DateTime dateTo,  double priceNpr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PricingRule() when $default != null:
return $default(_that.id,_that.courtId,_that.ruleType,_that.priority,_that.daysOfWeek,_that.timeFrom,_that.timeTo,_that.dateFrom,_that.dateTo,_that.priceNpr);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String courtId,  PricingRuleType ruleType,  int priority,  List<int> daysOfWeek,  DateTime timeFrom,  DateTime timeTo,  DateTime dateFrom,  DateTime dateTo,  double priceNpr)  $default,) {final _that = this;
switch (_that) {
case _PricingRule():
return $default(_that.id,_that.courtId,_that.ruleType,_that.priority,_that.daysOfWeek,_that.timeFrom,_that.timeTo,_that.dateFrom,_that.dateTo,_that.priceNpr);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String courtId,  PricingRuleType ruleType,  int priority,  List<int> daysOfWeek,  DateTime timeFrom,  DateTime timeTo,  DateTime dateFrom,  DateTime dateTo,  double priceNpr)?  $default,) {final _that = this;
switch (_that) {
case _PricingRule() when $default != null:
return $default(_that.id,_that.courtId,_that.ruleType,_that.priority,_that.daysOfWeek,_that.timeFrom,_that.timeTo,_that.dateFrom,_that.dateTo,_that.priceNpr);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PricingRule implements PricingRule {
  const _PricingRule({required this.id, required this.courtId, required this.ruleType, required this.priority, required final  List<int> daysOfWeek, required this.timeFrom, required this.timeTo, required this.dateFrom, required this.dateTo, required this.priceNpr}): _daysOfWeek = daysOfWeek;
  factory _PricingRule.fromJson(Map<String, dynamic> json) => _$PricingRuleFromJson(json);

@override final  String id;
@override final  String courtId;
@override final  PricingRuleType ruleType;
@override final  int priority;
 final  List<int> _daysOfWeek;
@override List<int> get daysOfWeek {
  if (_daysOfWeek is EqualUnmodifiableListView) return _daysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daysOfWeek);
}

@override final  DateTime timeFrom;
@override final  DateTime timeTo;
@override final  DateTime dateFrom;
@override final  DateTime dateTo;
@override final  double priceNpr;

/// Create a copy of PricingRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PricingRuleCopyWith<_PricingRule> get copyWith => __$PricingRuleCopyWithImpl<_PricingRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PricingRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PricingRule&&(identical(other.id, id) || other.id == id)&&(identical(other.courtId, courtId) || other.courtId == courtId)&&(identical(other.ruleType, ruleType) || other.ruleType == ruleType)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._daysOfWeek, _daysOfWeek)&&(identical(other.timeFrom, timeFrom) || other.timeFrom == timeFrom)&&(identical(other.timeTo, timeTo) || other.timeTo == timeTo)&&(identical(other.dateFrom, dateFrom) || other.dateFrom == dateFrom)&&(identical(other.dateTo, dateTo) || other.dateTo == dateTo)&&(identical(other.priceNpr, priceNpr) || other.priceNpr == priceNpr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,courtId,ruleType,priority,const DeepCollectionEquality().hash(_daysOfWeek),timeFrom,timeTo,dateFrom,dateTo,priceNpr);

@override
String toString() {
  return 'PricingRule(id: $id, courtId: $courtId, ruleType: $ruleType, priority: $priority, daysOfWeek: $daysOfWeek, timeFrom: $timeFrom, timeTo: $timeTo, dateFrom: $dateFrom, dateTo: $dateTo, priceNpr: $priceNpr)';
}


}

/// @nodoc
abstract mixin class _$PricingRuleCopyWith<$Res> implements $PricingRuleCopyWith<$Res> {
  factory _$PricingRuleCopyWith(_PricingRule value, $Res Function(_PricingRule) _then) = __$PricingRuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String courtId, PricingRuleType ruleType, int priority, List<int> daysOfWeek, DateTime timeFrom, DateTime timeTo, DateTime dateFrom, DateTime dateTo, double priceNpr
});




}
/// @nodoc
class __$PricingRuleCopyWithImpl<$Res>
    implements _$PricingRuleCopyWith<$Res> {
  __$PricingRuleCopyWithImpl(this._self, this._then);

  final _PricingRule _self;
  final $Res Function(_PricingRule) _then;

/// Create a copy of PricingRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? courtId = null,Object? ruleType = null,Object? priority = null,Object? daysOfWeek = null,Object? timeFrom = null,Object? timeTo = null,Object? dateFrom = null,Object? dateTo = null,Object? priceNpr = null,}) {
  return _then(_PricingRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,courtId: null == courtId ? _self.courtId : courtId // ignore: cast_nullable_to_non_nullable
as String,ruleType: null == ruleType ? _self.ruleType : ruleType // ignore: cast_nullable_to_non_nullable
as PricingRuleType,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,daysOfWeek: null == daysOfWeek ? _self._daysOfWeek : daysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>,timeFrom: null == timeFrom ? _self.timeFrom : timeFrom // ignore: cast_nullable_to_non_nullable
as DateTime,timeTo: null == timeTo ? _self.timeTo : timeTo // ignore: cast_nullable_to_non_nullable
as DateTime,dateFrom: null == dateFrom ? _self.dateFrom : dateFrom // ignore: cast_nullable_to_non_nullable
as DateTime,dateTo: null == dateTo ? _self.dateTo : dateTo // ignore: cast_nullable_to_non_nullable
as DateTime,priceNpr: null == priceNpr ? _self.priceNpr : priceNpr // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
