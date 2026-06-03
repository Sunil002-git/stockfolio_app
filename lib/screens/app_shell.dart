import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/broker_provider.dart';
import 'dashboard/dashboard_screen.dart';
 
// Placeholder screens for tabs not yet built.
// Replace these one by one in future sprints.
import 'placeholder_screen.dart';
 
// AppShell — the main app frame after login.
// Equivalent to the MainScaffold with BottomNavigationBar
// described in the Flutter guide document.
//
// This screen:
//   1. Loads brokers once on first build
//   2. Shows BottomNavigationBar with 5 tabs
//   3. Switches content based on selected tab
//   4. Does NOT rebuild the whole screen on tab switch
//      — IndexedStack keeps all tabs alive in memory
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}
 
class _AppShellState extends State<AppShell> {
  int _currentTab = 0;
  bool _brokersLoaded = false;
 
  // Tab definitions — add more as you build each sprint
  static const _tabs = [
    _Tab(icon: Icons.speed_outlined,          label: 'Dashboard'),
    _Tab(icon: Icons.layers_outlined,          label: 'Positions'),
    _Tab(icon: Icons.account_balance_outlined, label: 'Funds'),
    _Tab(icon: Icons.history_outlined,         label: 'History'),
    _Tab(icon: Icons.person_outline,           label: 'Profile'),
  ];
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load brokers once after the widget tree is ready.
    // didChangeDependencies is safe for context.read() calls.
    if (!_brokersLoaded) {
      _brokersLoaded = true;
      final api = context.read<ApiService>();
      context.read<BrokerProvider>().loadBrokers(api);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
 
    // The 5 screen widgets — one per tab.
    // Replace PlaceholderScreen with real screens in future sprints.
    final screens = [
      const DashboardScreen(),
      const PlaceholderScreen(title: 'Positions',  icon: Icons.layers_outlined),
      const PlaceholderScreen(title: 'Funds',      icon: Icons.account_balance_outlined),
      const PlaceholderScreen(title: 'History',    icon: Icons.history_outlined),
      const PlaceholderScreen(title: 'Profile',    icon: Icons.person_outline),
    ];
 
    return Scaffold(
      // IndexedStack keeps all tab screens in memory.
      // Unlike PageView, the user's scroll position and state
      // is preserved when switching tabs.
      body: IndexedStack(
        index: _currentTab,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex:   _currentTab,
        backgroundColor: AppColors.bgDeep,
        indicatorColor:  AppColors.brand.withOpacity(0.15),
        labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) =>
          setState(() => _currentTab = i),
        destinations: _tabs.map((t) =>
          NavigationDestination(
            icon:         Icon(t.icon, color: AppColors.textMuted),
            selectedIcon: Icon(t.icon, color: AppColors.brand),
            label:        t.label,
          )
        ).toList(),
      ),
    );
  }
}
 
// Simple data class for tab definitions
class _Tab {
  final IconData icon;
  final String   label;
  const _Tab({required this.icon, required this.label});
}
