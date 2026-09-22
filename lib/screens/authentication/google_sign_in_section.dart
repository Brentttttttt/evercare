import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class GoogleSignInSection extends StatelessWidget {
  const GoogleSignInSection({
    required this.onPressed,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('OR', style: AppTextStyles.label),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: isLoading,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              side: const BorderSide(color: Color(0xFF747775)),
            ),
            child: Text(
              isLoading ? 'Signing in with Google…' : 'Continue with Google',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (errorMessage case final message?) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(message, style: AppTextStyles.bodyMuted),
          ),
        ],
      ],
    );
  }
}
