import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/futsmandu_design_system.dart'
    show OwnerProfileHeader, ProfileSectionHeader, SettingsTile;

import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../staff/presentation/screens/add_staff_screen.dart';
import '../../../staff/presentation/screens/staff_list_screen.dart';
import '../../../auth/domain/owner_auth_models.dart';
import '../../../auth/presentation/screens/upload_documents_screen.dart';
import '../../../auth/presentation/controllers/owner_auth_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.themeProvider,
    required this.authController,
  });

  final ThemeProvider themeProvider;
  final OwnerAuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  static String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.themeProvider,
        widget.authController,
      ]),
      builder: (context, _) {
        final themeMode = widget.themeProvider.themeMode;
        final owner = widget.authController.owner;
        return Scaffold(
          appBar: AppBar(title: const Text('Owner Profile')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              children: [
                if (owner != null)
                  OwnerProfileHeader(
                    name: owner.displayBusinessName,
                    email: owner.email,
                    phone: owner.phone,
                    isVerified: owner.isVerified,
                    kycStatusLabel: owner.kycStatusLabel,
                    onUpdateKyc: () => _openKycUpdate(context),
                  ),
                const SizedBox(height: AppSpacing.md),
                if (owner != null)
                  _KycStatusSection(
                    status: owner.kycStatus,
                    rejectionReason: owner.kycRejectionReason,
                    hasUploadedAnyKycDocument: owner.hasUploadedAnyKycDocument,
                    hasUploadedAllKycDocuments: owner.hasUploadedAllKycDocuments,
                    businessName: owner.displayBusinessName,
                    onUpdateKyc: () => _openKycUpdate(context),
                    colorScheme: colorScheme,
                  ),
                const SizedBox(height: AppSpacing.md),
                ProfileSectionHeader(
                  title: 'Quick Actions',
                  subtitle: 'Manage staff and analysts in fewer taps.',
                ),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 380;
                    return GridView.count(
                      crossAxisCount: compact ? 1 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: compact ? 3.6 : 1.55,
                      children: [
                        _QuickActionCard(
                          icon: Icons.group_outlined,
                          title: 'Manage Staff',
                          subtitle: 'View, update roles, and deactivate',
                          accentColor: colorScheme.secondary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StaffListScreen(),
                              ),
                            );
                          },
                        ),
                        _QuickActionCard(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'Add Staff',
                          subtitle: 'Invite a new staff member',
                          accentColor: colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddStaffScreen(),
                              ),
                            );
                          },
                        ),
                        _QuickActionCard(
                          icon: Icons.supervisor_account_outlined,
                          title: 'Add Admin',
                          subtitle: 'Invite owner admin account',
                          accentColor: colorScheme.tertiary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddStaffScreen(
                                  title: 'Add Owner Admin',
                                  nameLabel: 'Admin name',
                                  nameHint: 'Enter admin full name',
                                  phoneLabel: 'Phone number',
                                  phoneHint: 'Enter phone number',
                                  roleLabel: 'Role',
                                  primaryActionLabel: 'Invite Admin',
                                  submittingLabel: 'Inviting...',
                                  roles: ['OWNER_ADMIN'],
                                  initialRole: 'OWNER_ADMIN',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                ProfileSectionHeader(
                  title: 'Preferences',
                  subtitle: 'Tune how the owner workspace behaves.',
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Booking alerts and account updates',
                        trailing: Switch.adaptive(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsTile(
                        icon: Icons.brightness_6_outlined,
                        title: 'Theme',
                        subtitle: _themeModeLabel(themeMode),
                        trailing: ToggleButtons(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 44,
                          ),
                          isSelected: [
                            themeMode == ThemeMode.light,
                            themeMode == ThemeMode.dark,
                          ],
                          onPressed: (index) {
                            widget.themeProvider.setThemeMode(
                              index == 0 ? ThemeMode.light : ThemeMode.dark,
                            );
                          },
                          children: const [
                            Icon(Icons.light_mode_outlined, size: 18),
                            Icon(Icons.dark_mode_outlined, size: 18),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'See FAQs or contact the support team',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () => _showSupportSheet(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ProfileSectionHeader(
                  title: 'Account',
                  subtitle: 'Manage access to this owner workspace.',
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      minimumSize: const Size.fromHeight(
                        AppSpacing.buttonHeight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openKycUpdate(BuildContext context) async {
    final didSubmit = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UploadDocumentsScreen(
          onSubmitted: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (didSubmit == true) {
      await widget.authController.bootstrap();
    }
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.email_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Email support'),
                  subtitle: const Text('support@futsmandu.com'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support email copied')),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.phone_outlined,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Call support'),
                  subtitle: const Text('+977 98XXXXXXXX'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support call requested')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from the owner account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await widget.authController.logout();
                } catch (_) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Logout request failed, local session cleared.',
                      ),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}


class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}


class _KycStatusSection extends StatelessWidget {
  const _KycStatusSection({
    required this.status,
    required this.rejectionReason,
    required this.hasUploadedAnyKycDocument,
    required this.hasUploadedAllKycDocuments,
    required this.businessName,
    required this.onUpdateKyc,
    required this.colorScheme,
  });

  final KycVerificationStatus status;
  final String? rejectionReason;
  final bool hasUploadedAnyKycDocument;
  final bool hasUploadedAllKycDocuments;
  final String businessName;
  final VoidCallback onUpdateKyc;
  final ColorScheme colorScheme;

  bool get _isApproved => status == KycVerificationStatus.approved;
  bool get _isRejected => status == KycVerificationStatus.rejected;

  String get _statusMessage {
    if (_isApproved) {
      return 'Your KYC is approved. You have full access.';
    }
    if (_isRejected) {
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty) {
        return 'Your KYC was rejected. ${rejectionReason!.trim()}';
      }
      return 'Your KYC was rejected. Please update your documents and resubmit.';
    }
    if (hasUploadedAllKycDocuments) {
      return 'Your documents are submitted and under admin review.';
    }
    if (hasUploadedAnyKycDocument) {
      return 'Some documents are uploaded. Upload the remaining documents to continue.';
    }
    return 'Upload documents to complete verification.';
  }

  String get _statusDetail {
    if (_isApproved) {
      return 'All required documents verified';
    }
    if (_isRejected) {
      return 'Action required: upload corrected documents for review';
    }
    if (hasUploadedAllKycDocuments) {
      return 'Submitted: waiting for admin approval';
    }
    return 'Please upload: Business Registration, Citizenship, Business PAN';
  }

  String get _ctaLabel {
    if (_isApproved) {
      return 'Update KYC';
    }
    if (_isRejected) {
      return 'Re-upload Documents';
    }
    if (hasUploadedAnyKycDocument) {
      return 'Continue Upload';
    }
    return 'Upload Documents';
  }

  IconData get _statusIcon {
    if (_isApproved) {
      return Icons.verified_user_rounded;
    }
    if (_isRejected) {
      return Icons.cancel_rounded;
    }
    return Icons.assignment_outlined;
  }

  Color get _statusIconColor {
    if (_isApproved) {
      return colorScheme.tertiary;
    }
    if (_isRejected) {
      return colorScheme.error;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _statusIcon,
                color: _statusIconColor,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KYC Verification Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: _isApproved
                  ? colorScheme.tertiaryContainer
                  : _isRejected
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  _isApproved
                      ? Icons.check_circle
                      : _isRejected
                      ? Icons.error_rounded
                      : Icons.hourglass_top_rounded,
                  color: _isApproved
                      ? colorScheme.onTertiaryContainer
                      : _isRejected
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _statusDetail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isApproved
                          ? colorScheme.onTertiaryContainer
                          : _isRejected
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUpdateKyc,
              icon: Icon(
                _isApproved
                    ? Icons.edit_document
                    : _isRejected
                    ? Icons.refresh_rounded
                    : Icons.cloud_upload_rounded,
              ),
              label: Text(_ctaLabel),
              style: FilledButton.styleFrom(
                backgroundColor: _isApproved
                    ? colorScheme.tertiary
                    : _isRejected
                    ? colorScheme.error
                    : colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


