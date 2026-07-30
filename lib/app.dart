import 'dart:async';

import 'package:flutter/material.dart';

import 'routes/app_route_observer.dart';
import 'routes/app_routes.dart';
import 'services/bp_monitor_ble_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bp_monitor_ble_scope.dart';

class EverCareApp extends StatefulWidget {
  const EverCareApp({super.key});

  @override
  State<EverCareApp> createState() => _EverCareAppState();
}

class _EverCareAppState extends State<EverCareApp> with WidgetsBindingObserver {
  late final BpMonitorBleService _bpMonitorService = BpMonitorBleService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_bpMonitorService.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _bpMonitorService.setAppInForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_bpMonitorService.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BpMonitorBleScope(
      service: _bpMonitorService,
      child: MaterialApp(
        title: 'EverCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        navigatorObservers: [everCareRouteObserver],
      ),
    );
  }
}
