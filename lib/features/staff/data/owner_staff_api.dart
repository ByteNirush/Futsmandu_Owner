import '../../../core/config/owner_api_config.dart';
import '../../../core/network/owner_api_client.dart';

class OwnerStaffApi {
  OwnerStaffApi({OwnerApiClient? apiClient})
    : _apiClient = apiClient ?? OwnerApiClient();

  final OwnerApiClient _apiClient;

  Future<List<OwnerStaffMember>> listStaff() async {
    final response = await _apiClient.get(OwnerApiConfig.staffEndpoint);
    final itemsRaw = response['items'];
    if (itemsRaw is! List) {
      return const [];
    }
    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(OwnerStaffMember.fromJson)
        .toList(growable: false);
  }

  Future<OwnerStaffMember> inviteStaff({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '${OwnerApiConfig.staffEndpoint}/invite',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'role': role,
      },
    );
    return OwnerStaffMember.fromJson(response);
  }

  Future<OwnerStaffMember> updateRole({
    required String staffId,
    required String role,
  }) async {
    final response = await _apiClient.put(
      '${OwnerApiConfig.staffEndpoint}/$staffId/role',
      data: {'role': role},
    );
    return OwnerStaffMember.fromJson(response);
  }

  Future<void> deactivate(String staffId) async {
    await _apiClient.delete('${OwnerApiConfig.staffEndpoint}/$staffId');
  }
}

class OwnerStaffMember {
  OwnerStaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  factory OwnerStaffMember.fromJson(Map<String, dynamic> json) {
    return OwnerStaffMember(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'OWNER_STAFF',
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? (json['createdAt'] as String?) ?? ''),
    );
  }

  String get roleLabel {
    switch (role) {
      case 'OWNER_ADMIN':
        return 'Owner Admin';
      case 'OWNER_STAFF':
        return 'Owner Staff';
      default:
        return role;
    }
  }
}
