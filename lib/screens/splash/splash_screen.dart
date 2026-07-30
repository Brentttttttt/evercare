import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/evercare_backend_scope.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _continueFromSession();
  }

  Future<void> _continueFromSession() async {
    final client = EverCareBackendScope.maybeClient(context);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final destination = client?.auth.currentSession == null
        ? AppRoutes.welcome
        : AppRoutes.home;
    Navigator.pushReplacementNamed(context, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EverCareLogo(size: 92),
              const SizedBox(height: 14),
              Text(
                'Your Health. Our Care.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
