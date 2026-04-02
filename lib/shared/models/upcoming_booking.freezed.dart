// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upcoming_booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpcomingBooking {

 String get teamName; String get courtName; DateTime get startTime; DateTime get endTime; BookingStatus get status;
/// Create a copy of UpcomingBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpcomingBookingCopyWith<UpcomingBooking> get copyWith => _$UpcomingBookingCopyWithImpl<UpcomingBooking>(this as UpcomingBooking, _$identity);

  /// Serializes this UpcomingBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpcomingBooking&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.courtName, courtName) || other.courtName == courtName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamName,courtName,startTime,endTime,status);

@override
String toString() {
  return 'UpcomingBooking(teamName: $teamName, courtName: $courtName, startTime: $startTime, endTime: $endTime, status: $status)';
}


}

/// @nodoc
abstract mixin class $UpcomingBookingCopyWith<$Res>  {
  factory $UpcomingBookingCopyWith(UpcomingBooking value, $Res Function(UpcomingBooking) _then) = _$UpcomingBookingCopyWithImpl;
@useResult
$Res call({
 String teamName, String courtName, DateTime startTime, DateTime endTime, BookingStatus status
});




}
/// @nodoc
class _$UpcomingBookingCopyWithImpl<$Res>
    implements $UpcomingBookingCopyWith<$Res> {
  _$UpcomingBookingCopyWithImpl(this._self, this._then);

  final UpcomingBooking _self;
  final $Res Function(UpcomingBooking) _then;

/// Create a copy of UpcomingBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamName = null,Object? courtName = null,Object? startTime = null,Object? endTime = null,Object? status = null,}) {
  return _then(_self.copyWith(
teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,courtName: null == courtName ? _self.courtName : courtName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [UpcomingBooking].
extension UpcomingBookingPatterns on UpcomingBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpcomingBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpcomingBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpcomingBooking value)  $default,){
final _that = this;
switch (_that) {
case _UpcomingBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpcomingBooking value)?  $default,){
final _that = this;
switch (_that) {
case _UpcomingBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String teamName,  String courtName,  DateTime startTime,  DateTime endTime,  BookingStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpcomingBooking() when $default != null:
return $default(_that.teamName,_that.courtName,_that.startTime,_that.endTime,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String teamName,  String courtName,  DateTime startTime,  DateTime endTime,  BookingStatus status)  $default,) {final _that = this;
switch (_that) {
case _UpcomingBooking():
return $default(_that.teamName,_that.courtName,_that.startTime,_that.endTime,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String teamName,  String courtName,  DateTime startTime,  DateTime endTime,  BookingStatus status)?  $default,) {final _that = this;
switch (_that) {
case _UpcomingBooking() when $default != null:
return $default(_that.teamName,_that.courtName,_that.startTime,_that.endTime,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpcomingBooking implements UpcomingBooking {
  const _UpcomingBooking({required this.teamName, required this.courtName, required this.startTime, required this.endTime, required this.status});
  factory _UpcomingBooking.fromJson(Map<String, dynamic> json) => _$UpcomingBookingFromJson(json);

@override final  String teamName;
@override final  String courtName;
@override final  DateTime startTime;
@override final  DateTime endTime;
@override final  BookingStatus status;

/// Create a copy of UpcomingBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpcomingBookingCopyWith<_UpcomingBooking> get copyWith => __$UpcomingBookingCopyWithImpl<_UpcomingBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpcomingBookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpcomingBooking&&(identical(other.teamName, teamName) || other.teamName == teamName)&&(identical(other.courtName, courtName) || other.courtName == courtName)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamName,courtName,startTime,endTime,status);

@override
String toString() {
  return 'UpcomingBooking(teamName: $teamName, courtName: $courtName, startTime: $startTime, endTime: $endTime, status: $status)';
}


}

/// @nodoc
abstract mixin class _$UpcomingBookingCopyWith<$Res> implements $UpcomingBookingCopyWith<$Res> {
  factory _$UpcomingBookingCopyWith(_UpcomingBooking value, $Res Function(_UpcomingBooking) _then) = __$UpcomingBookingCopyWithImpl;
@override @useResult
$Res call({
 String teamName, String courtName, DateTime startTime, DateTime endTime, BookingStatus status
});




}
/// @nodoc
class __$UpcomingBookingCopyWithImpl<$Res>
    implements _$UpcomingBookingCopyWith<$Res> {
  __$UpcomingBookingCopyWithImpl(this._self, this._then);

  final _UpcomingBooking _self;
  final $Res Function(_UpcomingBooking) _then;

/// Create a copy of UpcomingBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamName = null,Object? courtName = null,Object? startTime = null,Object? endTime = null,Object? status = null,}) {
  return _then(_UpcomingBooking(
teamName: null == teamName ? _self.teamName : teamName // ignore: cast_nullable_to_non_nullable
as String,courtName: null == courtName ? _self.courtName : courtName // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,
  ));
}


}

// dart format on
