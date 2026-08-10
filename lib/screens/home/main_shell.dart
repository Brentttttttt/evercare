import 'package:flutter/material.dart';

import '../../routes/app_route_observer.dart';
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
    with SingleTickerProviderStateMixin, RouteAware {
  late int _selectedIndex = widget.initialIndex.clamp(0, 7);
  final List<ScrollController> _pageScrollControllers = List.generate(
    8,
    (_) => ScrollController(),
  );
  PageRoute<dynamic>? _pageRoute;
  late final AnimationController _contentController = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: 1,
  );
  int _transitionDirection = 1;

  void _selectTab(int index) {
    if (index == _selectedIndex) {
      _resetPageScroll(index);
      return;
    }
    _resetPageScroll(index);
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

  void _resetPageScroll(int index) {
    final controller = _pageScrollControllers[index];
    if (!controller.hasClients) return;
    controller.jumpTo(controller.position.minScrollExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || identical(route, _pageRoute)) return;
    if (_pageRoute != null) everCareRouteObserver.unsubscribe(this);
    _pageRoute = route;
    everCareRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resetPageScroll(_selectedIndex);
    });
  }

  @override
  void dispose() {
    if (_pageRoute != null) everCareRouteObserver.unsubscribe(this);
    for (final controller in _pageScrollControllers) {
      controller.dispose();
    }
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
      HomeDashboardScreen(
        onSelectTab: _selectTab,
        isActive: _selectedIndex == 0,
        scrollController: _pageScrollControllers[0],
      ),
      HealthOverviewScreen(
        isActive: _selectedIndex == 1,
        scrollController: _pageScrollControllers[1],
      ),
      MedicationScreen(
        isActive: _selectedIndex == 2,
        scrollController: _pageScrollControllers[2],
      ),
      AppointmentsScreen(
        isActive: _selectedIndex == 3,
        scrollController: _pageScrollControllers[3],
      ),
      JournalsScreen(scrollController: _pageScrollControllers[4]),
      CareBookScreen(scrollController: _pageScrollControllers[5]),
      EmergencyScreen(scrollController: _pageScrollControllers[6]),
      ProfileScreen(scrollController: _pageScrollControllers[7]),
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
