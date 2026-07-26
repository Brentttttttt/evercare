import 'dart:async';

import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
