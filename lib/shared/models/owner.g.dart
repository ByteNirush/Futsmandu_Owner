// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Owner _$OwnerFromJson(Map<String, dynamic> json) => _Owner(
  id: json['id'] as String,
  businessName: json['businessName'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  isVerified: json['isVerified'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$OwnerToJson(_Owner instance) => <String, dynamic>{
  'id': instance.id,
  'businessName': instance.businessName,
  'email': instance.email,
  'phone': instance.phone,
  'isVerified': instance.isVerified,
  'createdAt': instance.createdAt.toIso8601String(),
};
