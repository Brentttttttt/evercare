import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CarePhotoBanner extends StatelessWidget {
  const CarePhotoBanner({
    required this.assetPath,
    required this.semanticLabel,
    required this.title,
    required this.subtitle,
    super.key,
    this.height = 172,
  });

  final String assetPath;
  final String semanticLabel;
  final String title;
  final String subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                image: true,
                label: semanticLabel,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  cacheWidth: 1200,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x000C2117),
                      Color(0x160C2117),
                      Color(0xD914261D),
                    ],
                    stops: [0, .42, 1],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: const Color(0xFFE5EFE9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
