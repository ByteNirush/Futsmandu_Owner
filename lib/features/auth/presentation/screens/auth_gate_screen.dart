import 'package:flutter/material.dart';
import 'package:futsmandu_design_system/core/theme/app_typography.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../analytics/presentation/screens/analytics_overview_screen.dart';
import '../../../bookings/presentation/screens/bookings_list_screen.dart';
import '../../../bookings/presentation/screens/create_offline_booking_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../pricing/presentation/screens/pricing_rules_screen.dart';
import '../../../settings/presentation/screens/profile_screen.dart';
import '../../../venues/presentation/screens/venues_list_screen.dart';
import '../../presentation/controllers/owner_auth_controller.dart';
import 'login_screen.dart';
import 'pending_verification_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({
    super.key,
    required this.authController,
    required this.themeProvider,
  });

  final OwnerAuthController authController;
  final ThemeProvider themeProvider;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    widget.authController.bootstrap();
    widget.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.authController.isInitializing) {
      return const _BootstrapLoader();
    }

    if (!widget.authController.isAuthenticated) {
      return LoginScreen(authController: widget.authController);
    }

    // User is logged in - allow dashboard access regardless of KYC status
    // KYC banner on dashboard will guide them to complete verification
    return OwnerShellScreen(
      authController: widget.authController,
      themeProvider: widget.themeProvider,
    );
  }
}

class _BootstrapLoader extends StatelessWidget {
  const _BootstrapLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class OwnerShellScreen extends StatefulWidget {
  const OwnerShellScreen({
    super.key,
    required this.authController,
    required this.themeProvider,
  });

  final OwnerAuthController authController;
  final ThemeProvider themeProvider;

  @override
  State<OwnerShellScreen> createState() => _OwnerShellScreenState();
}

class _OwnerShellScreenState extends State<OwnerShellScreen> {
  int _selectedIndex = 0;

  late final List<DashboardQuickAction> _dashboardQuickActions = [
    DashboardQuickAction(
      title: 'Add Offline Booking',
      icon: Icons.add_box_outlined,
      builder: _buildCreateOfflineBooking,
    ),
    DashboardQuickAction(
      title: 'Manage Venues',
      icon: Icons.location_city_outlined,
      builder: _buildVenuesList,
    ),
    DashboardQuickAction(
      title: 'Manage Pricing',
      icon: Icons.local_offer_outlined,
      builder: _buildPricingRules,
    ),
    DashboardQuickAction(
      title: 'View Analytics',
      icon: Icons.query_stats_outlined,
      builder: _buildAnalyticsOverview,
    ),
  ];

  late final List<Widget> _tabs = [
    DashboardScreen(
      quickActions: _dashboardQuickActions,
      authController: widget.authController,
    ),
    const BookingsListScreen(),
    const VenuesListScreen(),
    const PricingRulesScreen(),
    MoreTabScreen(
      themeProvider: widget.themeProvider,
      authController: widget.authController,
    ),
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
    if (!widget.authController.isAuthenticated) {
      return LoginScreen(authController: widget.authController);
    }

    if (widget.authController.needsVerification) {
      return PendingVerificationScreen(authController: widget.authController);
    }

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            indicatorColor: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.14),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                );
              }
              return IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final baseStyle = Theme.of(context).textTheme.labelSmall
                  ?.copyWith(
                    fontSize: 11,
                    fontWeight: AppFontWeights.regular,
                    height: 1.2,
                  );
              if (states.contains(WidgetState.selected)) {
                return baseStyle?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: AppFontWeights.semiBold,
                );
              }
              return baseStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            }),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            shadowColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined, size: 24),
                selectedIcon: Icon(Icons.dashboard, size: 24),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined, size: 24),
                selectedIcon: Icon(Icons.calendar_month, size: 24),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.location_city_outlined, size: 24),
                selectedIcon: Icon(Icons.location_city, size: 24),
                label: 'Venues',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined, size: 24),
                selectedIcon: Icon(Icons.local_offer, size: 24),
                label: 'Pricing',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined, size: 24),
                selectedIcon: Icon(Icons.grid_view, size: 24),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreTabScreen extends StatelessWidget {
  const MoreTabScreen({
    super.key,
    required this.themeProvider,
    required this.authController,
  });

  final ThemeProvider themeProvider;
  final OwnerAuthController authController;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      themeProvider: themeProvider,
      authController: authController,
    );
  }
}
