import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/screen_state_view.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({
    super.key,
    this.state = ScreenUiState.content,
  });

  final ScreenUiState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Search staff
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddStaffScreen()),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Staff'),
      ),
      body: ScreenStateView(
        state: state,
        emptyTitle: 'No staff members',
        emptySubtitle: 'Add staff to share operational responsibilities.',
        content: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemCount: 3,
          separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final staff = _sampleStaff[index];
            return AppCard(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  child: Text(
                    staff['name']!.split(' ').map((n) => n[0]).take(2).join(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  staff['name']!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${staff['role']} • ${staff['phone']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    // Handle menu actions
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: AppSpacing.xs),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static const List<Map<String, String>> _sampleStaff = [
    {'name': 'Sujan Thapa', 'role': 'Owner Staff', 'phone': '98XXXXXXXX'},
    {'name': 'Ramesh KC', 'role': 'Owner Staff', 'phone': '98XXXXXXXX'},
    {'name': 'Priya Sharma', 'role': 'Owner Admin', 'phone': '98XXXXXXXX'},
  ];
}
