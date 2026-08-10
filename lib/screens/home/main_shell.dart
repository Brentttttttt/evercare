import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_motion.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../appointments/appointments_screen.dart';
import '../care_book/care_book_screen.dart';
import '../emergency/emergency_screen.dart';
import '../health/health_overview_screen.dart';
import '../journals/journals_screen.dart';
import '../medications/medication_screen.dart';
import '../profile/profile_screen.dart';
import 'home_dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex = widget.initialIndex.clamp(0, 7);
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: 1,
  );
  int _transitionDirection = 1;

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _transitionDirection = index > _selectedIndex ? 1 : -1;
      _selectedIndex = index;
    });
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _contentController.value = 1;
    } else {
      _contentController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const headers = [
      (title: 'Home', subtitle: 'Your care overview'),
      (title: 'My Health', subtitle: 'Blood pressure monitoring'),
      (title: 'Medications', subtitle: 'Your daily medicine schedule'),
      (title: 'Appointments', subtitle: 'Manage your medical visits'),
      (
        title: 'Journals',
        subtitle:
            'Keep track of daily thoughts, feelings, symptoms, and special moments.',
      ),
      (
        title: 'Care Book',
        subtitle: 'NIA handbook reference and simplified caregiving notes',
      ),
      (title: 'Emergency', subtitle: 'Urgent help and trusted contacts'),
      (title: 'Profile', subtitle: 'Personal details and settings'),
    ];
    final pages = [
      HomeDashboardScreen(onSelectTab: _selectTab),
      HealthOverviewScreen(isActive: _selectedIndex == 1),
      const MedicationScreen(),
      const AppointmentsScreen(),
      const JournalsScreen(),
      const CareBookScreen(),
      const EmergencyScreen(),
      const ProfileScreen(),
    ];
    final header = headers[_selectedIndex];
    final contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: AppMotion.emphasizedCurve,
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
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
                    child: FadeTransition(
                      opacity: Tween<double>(
                        begin: .68,
                        end: 1,
                      ).animate(contentAnimation),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(.035 * _transitionDirection, 0),
                          end: Offset.zero,
                        ).animate(contentAnimation),
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: pages,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RepaintBoundary(
              child: AppBottomNavigation(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectTab,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
