import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_header.dart';
import 'auth_background.dart';

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
      backgroundColor: AppColors.background,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxHeight < 480 ||
                  MediaQuery.viewInsetsOf(context).bottom > 0;
              return Column(
                children: [
                  // The brand is outside the form scroll view and stays visible
                  // when the keyboard opens or the form is scrolled.
                  _AuthBrand(showBack: showBack, compact: compact),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('auth-form-scroll'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _AuthFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style: AppTextStyles.pageTitle.copyWith(
                                      fontSize: 25,
                                      color: AppColors.darkGreen,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(subtitle, style: AppTextStyles.bodyMuted),
                                const SizedBox(height: 20),
                                ...children,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// An opaque form surface keeps fields readable over decorative imagery.
class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFDCE8DF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0B244B35),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: child,
    ),
  );
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.showBack, required this.compact});

  final bool showBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          key: const ValueKey('auth-fixed-brand'),
          padding: EdgeInsets.fromLTRB(
            8,
            compact ? 6 : 16,
            16,
            compact ? 6 : 10,
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.darkGreen,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                )
              else
                const SizedBox(width: 12),
              Container(
                width: compact ? 42 : 54,
                height: compact ? 42 : 54,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 13 : 17),
                  border: Border.all(color: AppColors.border),
                ),
                child: EverCareLogo(
                  size: compact ? 34 : 46,
                  showWordmark: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  // The full brand lockup remains visible in compact layouts.
                  // Form content below keeps the user's full text scaling.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'EverCare',
                          style: AppTextStyles.pageTitle.copyWith(
                            color: AppColors.darkGreen,
                            fontSize: compact ? 25 : 29,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Care, made simpler',
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: const Color(0xFF496352),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.destructiveContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMuted.copyWith(
                color: AppColors.destructiveContainerForeground,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AuthAccountLink extends StatelessWidget {
  const AuthAccountLink({
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    ),
    child: Text.rich(
      TextSpan(
        text: '$prompt ',
        style: AppTextStyles.bodyMuted,
        children: [
          TextSpan(
            text: action,
            style: TextStyle(
              color: onPressed == null
                  ? AppColors.mutedForeground
                  : AppColors.darkGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
  );
}

class AuthRoleOption extends StatelessWidget {
  const AuthRoleOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    enabled: onSelected != null,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? AppColors.primaryContainer : const Color(0xFFF8FAF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.cardTitle),
                      const SizedBox(height: 3),
                      Text(description, style: AppTextStyles.bodyMuted),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
    this.bottomSpacing = 14,
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
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final passwordField =
        obscureText ||
        (autofillHints?.any(
              (hint) =>
                  hint == AutofillHints.password ||
                  hint == AutofillHints.newPassword,
            ) ??
            false);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            initialValue: initialValue,
            obscureText: obscureText,
            autocorrect:
                !passwordField && keyboardType != TextInputType.emailAddress,
            enableSuggestions: !passwordField,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            enabled: enabled,
            onFieldSubmitted: onFieldSubmitted,
            scrollPadding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            style: AppTextStyles.body.copyWith(height: 1.3),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: enabled
                  ? const Color(0xFFF7FAF7)
                  : AppColors.secondary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              constraints: const BoxConstraints(minHeight: 54),
              errorMaxLines: 4,
              errorStyle: AppTextStyles.bodyMuted.copyWith(
                color: AppColors.destructiveContainerForeground,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD9E4DC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
              prefixIcon: Icon(icon, color: AppColors.primaryGreen),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}
