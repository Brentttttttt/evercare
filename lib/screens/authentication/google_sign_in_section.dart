import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'auth_widgets.dart';

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
        Row(
          children: [
            Expanded(child: Divider()),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                ),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        Semantics(
          liveRegion: isLoading,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              side: const BorderSide(color: Color(0xFF747775)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontFamily: 'GoogleSansAuth',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
            child: Row(
              children: [
                // Official, unmodified Google Identity asset. Do not recolor
                // or replace it with a text glyph or a hand-drawn logo.
                Image.asset(
                  'assets/images/google_g.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isLoading
                        ? 'Signing in with Google…'
                        : 'Continue with Google',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (errorMessage case final message?) ...[
          const SizedBox(height: 10),
          AuthErrorMessage(message: message),
        ],
      ],
    );
  }
}
