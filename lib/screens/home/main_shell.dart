import 'package:flutter/material.dart';

import '../../routes/app_route_observer.dart';
import '../../routes/app_routes.dart';
import '../../services/phone_reminder_controller.dart';
import '../../theme/app_motion.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/app_header.dart';
import '../../widgets/phone_reminder_scope.dart';
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
  bool _reminderPromptScheduled = false;
  bool _reminderPromptChecked = false;

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
    if (route is PageRoute<dynamic> && !identical(route, _pageRoute)) {
      if (_pageRoute != null) everCareRouteObserver.unsubscribe(this);
      _pageRoute = route;
      everCareRouteObserver.subscribe(this, route);
    }
    _scheduleReminderPrompt();
  }

  void _scheduleReminderPrompt() {
    final controller = PhoneReminderScope.maybeOf(context);
    if (_reminderPromptScheduled ||
        _reminderPromptChecked ||
        controller == null ||
        !controller.supported ||
        !controller.initialized ||
        !controller.signedIn ||
        controller.busy ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _reminderPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _offerReminderPrompt(controller);
      } finally {
        _reminderPromptScheduled = false;
      }
    });
  }

  Future<void> _offerReminderPrompt(PhoneReminderController controller) async {
    if (!mounted ||
        !controller.signedIn ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    try {
      final shouldOffer = await controller.shouldOfferPermissionPrompt();
      _reminderPromptChecked = true;
      if (!mounted ||
          !controller.signedIn ||
          !shouldOffer ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final enable = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Get reminders on this phone?'),
          content: const Text(
            'EverCare can remind you about medicine and appointments while '
            'the app is in the background. Alerts use generic wording to keep '
            'health details private.\n\n'
            'Enable reminders to allow phone notifications. You can change '
            'permissions or turn reminders off in Notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
      if (enable == true && mounted && controller.signedIn) {
        await controller.enable();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone reminders can be set up in Notifications.'),
        ),
      );
    }
  }

  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetPageScroll(_selectedIndex);
        _scheduleReminderPrompt();
      }
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
