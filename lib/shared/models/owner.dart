import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner.freezed.dart';
part 'owner.g.dart';

/// Represents the authenticated business owner account.
@freezed
abstract class Owner with _$Owner {
  const factory Owner({
    required String id,
    required String businessName,
    required String email,
    required String phone,
    required bool isVerified,
    required DateTime createdAt,
  }) = _Owner;

  factory Owner.fromJson(Map<String, dynamic> json) => _$OwnerFromJson(json);
}