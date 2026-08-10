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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .42),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: .58),
          width: .8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
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
                      Color(0x080C2117),
                      Color(0x100C2117),
                      Color(0xE014261D),
                    ],
                    stops: [0, .38, 1],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
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
                        fontSize: 17,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: Colors.white.withValues(alpha: .88),
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

class CareCardArtwork extends StatelessWidget {
  const CareCardArtwork({
    required this.assetPath,
    super.key,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: alignment,
          cacheWidth: 1200,
          filterQuality: FilterQuality.medium,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xF0155E43), Color(0xB8155E43), Color(0x6B155E43)],
              stops: [0, .52, 1],
            ),
          ),
        ),
      ],
    );
  }
}
