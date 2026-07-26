import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../appointments/appointments_screen.dart';
import '../health/health_overview_screen.dart';
import '../medications/medication_screen.dart';
import '../profile/profile_screen.dart';
import 'home_dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex.clamp(0, 4);

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    const headers = [
      (title: 'Home', subtitle: 'Your care overview'),
      (title: 'My Health', subtitle: 'Blood pressure monitoring'),
      (title: 'Medications', subtitle: 'Your daily medicine schedule'),
      (title: 'Appointments', subtitle: 'Manage your medical visits'),
      (title: 'Profile', subtitle: 'Personal details and settings'),
    ];
    final pages = [
      HomeDashboardScreen(onSelectTab: _selectTab),
      const HealthOverviewScreen(),
      const MedicationScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];
    final header = headers[_selectedIndex];

    return Scaffold(
      body: Column(
        children: [
          EverCareHeader(
            title: header.title,
            subtitle: header.subtitle,
            showNotifications: true,
            onNotifications: () =>
                Navigator.pushNamed(context, AppRoutes.notifications),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: IndexedStack(index: _selectedIndex, children: pages),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
      ),
    );
  }
}
