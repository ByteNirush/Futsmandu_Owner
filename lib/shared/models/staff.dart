import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff.freezed.dart';
part 'staff.g.dart';

/// Represents available staff roles in owner app.
enum StaffRole {
  ownerAdmin,
  ownerStaff,
}

/// Represents a staff member associated with a venue.
@freezed
abstract class Staff with _$Staff {
  const factory Staff({
    required String id,
    required String venueId,
    required String name,
    required String phone,
    required StaffRole role,
    required DateTime createdAt,
  }) = _Staff;

  factory Staff.fromJson(Map<String, dynamic> json) => _$StaffFromJson(json);
}