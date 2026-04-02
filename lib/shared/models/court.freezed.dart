// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'court.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Court {

 String get id; String get venueId; String get name; String get surface; int get capacity; int get minPlayers; DateTime get openTime; DateTime get closeTime; int get slotDuration;
/// Create a copy of Court
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CourtCopyWith<Court> get copyWith => _$CourtCopyWithImpl<Court>(this as Court, _$identity);

  /// Serializes this Court to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Court&&(identical(other.id, id) || other.id == id)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.name, name) || other.name == name)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.minPlayers, minPlayers) || other.minPlayers == minPlayers)&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime)&&(identical(other.slotDuration, slotDuration) || other.slotDuration == slotDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,venueId,name,surface,capacity,minPlayers,openTime,closeTime,slotDuration);

@override
String toString() {
  return 'Court(id: $id, venueId: $venueId, name: $name, surface: $surface, capacity: $capacity, minPlayers: $minPlayers, openTime: $openTime, closeTime: $closeTime, slotDuration: $slotDuration)';
}


}

/// @nodoc
abstract mixin class $CourtCopyWith<$Res>  {
  factory $CourtCopyWith(Court value, $Res Function(Court) _then) = _$CourtCopyWithImpl;
@useResult
$Res call({
 String id, String venueId, String name, String surface, int capacity, int minPlayers, DateTime openTime, DateTime closeTime, int slotDuration
});




}
/// @nodoc
class _$CourtCopyWithImpl<$Res>
    implements $CourtCopyWith<$Res> {
  _$CourtCopyWithImpl(this._self, this._then);

  final Court _self;
  final $Res Function(Court) _then;

/// Create a copy of Court
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? venueId = null,Object? name = null,Object? surface = null,Object? capacity = null,Object? minPlayers = null,Object? openTime = null,Object? closeTime = null,Object? slotDuration = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,openTime: null == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as DateTime,closeTime: null == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as DateTime,slotDuration: null == slotDuration ? _self.slotDuration : slotDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Court].
extension CourtPatterns on Court {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Court value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Court() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Court value)  $default,){
final _that = this;
switch (_that) {
case _Court():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Court value)?  $default,){
final _that = this;
switch (_that) {
case _Court() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String venueId,  String name,  String surface,  int capacity,  int minPlayers,  DateTime openTime,  DateTime closeTime,  int slotDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Court() when $default != null:
return $default(_that.id,_that.venueId,_that.name,_that.surface,_that.capacity,_that.minPlayers,_that.openTime,_that.closeTime,_that.slotDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String venueId,  String name,  String surface,  int capacity,  int minPlayers,  DateTime openTime,  DateTime closeTime,  int slotDuration)  $default,) {final _that = this;
switch (_that) {
case _Court():
return $default(_that.id,_that.venueId,_that.name,_that.surface,_that.capacity,_that.minPlayers,_that.openTime,_that.closeTime,_that.slotDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String venueId,  String name,  String surface,  int capacity,  int minPlayers,  DateTime openTime,  DateTime closeTime,  int slotDuration)?  $default,) {final _that = this;
switch (_that) {
case _Court() when $default != null:
return $default(_that.id,_that.venueId,_that.name,_that.surface,_that.capacity,_that.minPlayers,_that.openTime,_that.closeTime,_that.slotDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Court implements Court {
  const _Court({required this.id, required this.venueId, required this.name, required this.surface, required this.capacity, required this.minPlayers, required this.openTime, required this.closeTime, required this.slotDuration});
  factory _Court.fromJson(Map<String, dynamic> json) => _$CourtFromJson(json);

@override final  String id;
@override final  String venueId;
@override final  String name;
@override final  String surface;
@override final  int capacity;
@override final  int minPlayers;
@override final  DateTime openTime;
@override final  DateTime closeTime;
@override final  int slotDuration;

/// Create a copy of Court
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CourtCopyWith<_Court> get copyWith => __$CourtCopyWithImpl<_Court>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CourtToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Court&&(identical(other.id, id) || other.id == id)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.name, name) || other.name == name)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.minPlayers, minPlayers) || other.minPlayers == minPlayers)&&(identical(other.openTime, openTime) || other.openTime == openTime)&&(identical(other.closeTime, closeTime) || other.closeTime == closeTime)&&(identical(other.slotDuration, slotDuration) || other.slotDuration == slotDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,venueId,name,surface,capacity,minPlayers,openTime,closeTime,slotDuration);

@override
String toString() {
  return 'Court(id: $id, venueId: $venueId, name: $name, surface: $surface, capacity: $capacity, minPlayers: $minPlayers, openTime: $openTime, closeTime: $closeTime, slotDuration: $slotDuration)';
}


}

/// @nodoc
abstract mixin class _$CourtCopyWith<$Res> implements $CourtCopyWith<$Res> {
  factory _$CourtCopyWith(_Court value, $Res Function(_Court) _then) = __$CourtCopyWithImpl;
@override @useResult
$Res call({
 String id, String venueId, String name, String surface, int capacity, int minPlayers, DateTime openTime, DateTime closeTime, int slotDuration
});




}
/// @nodoc
class __$CourtCopyWithImpl<$Res>
    implements _$CourtCopyWith<$Res> {
  __$CourtCopyWithImpl(this._self, this._then);

  final _Court _self;
  final $Res Function(_Court) _then;

/// Create a copy of Court
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? venueId = null,Object? name = null,Object? surface = null,Object? capacity = null,Object? minPlayers = null,Object? openTime = null,Object? closeTime = null,Object? slotDuration = null,}) {
  return _then(_Court(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: null == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as String,capacity: null == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int,minPlayers: null == minPlayers ? _self.minPlayers : minPlayers // ignore: cast_nullable_to_non_nullable
as int,openTime: null == openTime ? _self.openTime : openTime // ignore: cast_nullable_to_non_nullable
as DateTime,closeTime: null == closeTime ? _self.closeTime : closeTime // ignore: cast_nullable_to_non_nullable
as DateTime,slotDuration: null == slotDuration ? _self.slotDuration : slotDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
