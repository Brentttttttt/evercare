import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.white,
              title: const SizedBox.shrink(),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.center,
                child: EverCareLogo(size: 54),
              ),
              const SizedBox(height: 34),
              Text(title, style: AppTextStyles.pageTitle),
              const SizedBox(height: 8),
              Text(subtitle, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 28),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class MockTextField extends StatelessWidget {
  const MockTextField({
    required this.label,
    required this.icon,
    super.key,
    this.obscureText = false,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
  });

  final String label;
  final IconData icon;
  final bool obscureText;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
