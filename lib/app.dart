import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class EverCareApp extends StatelessWidget {
  const EverCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EverCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
