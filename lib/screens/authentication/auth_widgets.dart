import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';

String? validateRequiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required.';
  return null;
}

String? validateEmailAddress(String? value) {
  final requiredMessage = validateRequiredText(value, 'Email address');
  if (requiredMessage != null) return requiredMessage;
  final email = value!.trim();
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

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

class AppTextField extends StatelessWidget {
  const AppTextField({
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
    this.controller,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.onFieldSubmitted,
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
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        enabled: enabled,
        onFieldSubmitted: onFieldSubmitted,
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
