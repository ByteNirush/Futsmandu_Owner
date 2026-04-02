// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Staff _$StaffFromJson(Map<String, dynamic> json) => _Staff(
  id: json['id'] as String,
  venueId: json['venueId'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String,
  role: $enumDecode(_$StaffRoleEnumMap, json['role']),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$StaffToJson(_Staff instance) => <String, dynamic>{
  'id': instance.id,
  'venueId': instance.venueId,
  'name': instance.name,
  'phone': instance.phone,
  'role': _$StaffRoleEnumMap[instance.role]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$StaffRoleEnumMap = {
  StaffRole.ownerAdmin: 'ownerAdmin',
  StaffRole.ownerStaff: 'ownerStaff',
};
