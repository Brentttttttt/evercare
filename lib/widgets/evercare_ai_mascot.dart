import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const evercareAiMascotKey = ValueKey<String>('evercare-ai-mascot');

const evercareAiMascotAvatarAsset =
    'assets/ai_mascot/evercare_ai_mascot_avatar.png';

/// Small, reusable avatar for EverCare AI surfaces.
///
/// The surrounding UI identifies the assistant, so this artwork is decorative
/// and excluded from semantics to avoid duplicate screen-reader announcements.
class AiMascotAvatar extends StatelessWidget {
  const AiMascotAvatar({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final decodeSize = (size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 512);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: .09),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.purple.withValues(alpha: .16)),
      ),
      child: ClipOval(
        child: Image.asset(
          evercareAiMascotAvatarAsset,
          key: evercareAiMascotKey,
          fit: BoxFit.contain,
          cacheWidth: decodeSize,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => const ColoredBox(
            color: AppColors.card,
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.purple,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
