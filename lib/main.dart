import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/design_system/app_spacing.dart';
import 'core/theme/theme_provider.dart';
import 'features/analytics/presentation/screens/analytics_overview_screen.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/upload_documents_screen.dart';
import 'features/bookings/presentation/screens/create_offline_booking_screen.dart';
import 'features/bookings/presentation/screens/bookings_list_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/pricing/presentation/screens/pricing_rules_screen.dart';
import 'features/settings/presentation/screens/profile_screen.dart';
import 'features/staff/presentation/screens/staff_list_screen.dart';
import 'features/venues/presentation/screens/venues_list_screen.dart';
import 'shared/widgets/app_card.dart';

void main() {
  runApp(const FutsmanduApp());
}

class FutsmanduApp extends StatefulWidget {
  const FutsmanduApp({super.key});

  @override
  State<FutsmanduApp> createState() => _FutsmanduAppState();
}

class _FutsmanduAppState extends State<FutsmanduApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Futsmandu Owner App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _themeProvider.themeMode,
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/otp-verification': (_) => const OtpVerificationScreen(),
            '/reset-password': (_) => const ResetPasswordScreen(),
            '/upload-documents': (_) => const UploadDocumentsScreen(),
            '/shell': (_) => OwnerShellScreen(themeProvider: _themeProvider),
          },
        );
      },
    );
  }
}

class OwnerShellScreen extends StatefulWidget {
  const OwnerShellScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

  @override
  State<OwnerShellScreen> createState() => _OwnerShellScreenState();
}

class _OwnerShellScreenState extends State<OwnerShellScreen> {
  int _selectedIndex = 0;

  late final List<DashboardQuickAction> _dashboardQuickActions = [
    const DashboardQuickAction(
      title: 'Add Offline Booking',
      icon: Icons.add_box_outlined,
      builder: _buildCreateOfflineBooking,
    ),
    const DashboardQuickAction(
      title: 'Manage Venues',
      icon: Icons.location_city_outlined,
      builder: _buildVenuesList,
    ),
    const DashboardQuickAction(
      title: 'Manage Pricing',
      icon: Icons.local_offer_outlined,
      builder: _buildPricingRules,
    ),
    const DashboardQuickAction(
      title: 'View Analytics',
      icon: Icons.query_stats_outlined,
      builder: _buildAnalyticsOverview,
    ),
  ];

  late final List<Widget> _tabs = [
    DashboardScreen(quickActions: _dashboardQuickActions),
    const BookingsListScreen(),
    const VenuesListScreen(),
    const PricingRulesScreen(),
    MoreTabScreen(themeProvider: widget.themeProvider),
  ];

  static Widget _buildCreateOfflineBooking(BuildContext _) =>
      const CreateOfflineBookingScreen();

  static Widget _buildVenuesList(BuildContext _) => const VenuesListScreen();

  static Widget _buildPricingRules(BuildContext _) =>
      const PricingRulesScreen();

  static Widget _buildAnalyticsOverview(BuildContext _) =>
      const AnalyticsOverviewScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city),
            label: 'Venues',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'Pricing',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class MoreTabScreen extends StatelessWidget {
  const MoreTabScreen({super.key, required this.themeProvider});

  final ThemeProvider themeProvider;

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
    final items = [
      (
        title: 'Staff',
        icon: Icons.groups_rounded,
        screen: const StaffListScreen(),
      ),
      (
        title: 'Analytics',
        icon: Icons.insert_chart_outlined_rounded,
        screen: const AnalyticsOverviewScreen(),
      ),
      (
        title: 'Settings',
        icon: Icons.settings_outlined,
        screen: const ProfileScreen(),
      ),
    ];

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        itemCount: items.length + 1,
        separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppCard(
              // Give the segmented control more horizontal room on small screens.
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxs,
                AppSpacing.md,
                AppSpacing.xxs,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Current: ${_themeModeLabel(themeProvider.themeMode)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text(
                            'System',
                            maxLines: 1,
                            softWrap: false,
                          ),
                          icon: Icon(Icons.settings_suggest_outlined, size: 16),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text(
                            'Light',
                            maxLines: 1,
                            softWrap: false,
                          ),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text(
                            'Dark',
                            maxLines: 1,
                            softWrap: false,
                          ),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                      ],
                      selected: {themeProvider.themeMode},
                      style: ButtonStyle(
                        side: WidgetStatePropertyAll(
                          BorderSide(color: colorScheme.outline),
                        ),
                        // Reduce internal spacing so all labels fit on one line.
                        padding: WidgetStatePropertyAll(
                          const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                      onSelectionChanged: (selection) {
                        themeProvider.setThemeMode(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          final item = items[index - 1];
          return AppCard(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => item.screen));
            },
            child: Row(
              children: [
                Icon(item.icon),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          );
        },
      ),
    );
  }
}
