import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/profile_avatar.dart';

class ProfilePhotoCard extends StatelessWidget {
  const ProfilePhotoCard({
    required this.profile,
    required this.onChoose,
    required this.busy,
    this.preview,
    this.error,
    this.onDiscard,
    super.key,
  });
  final UserProfile profile;
  final Uint8List? preview;
  final bool busy;
  final String? error;
  final VoidCallback onChoose;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) => AppCard(
    color: const Color(0xFFEDF7F0),
    padding: const EdgeInsets.all(22),
    child: Column(
      children: [
        Semantics(
          button: true,
          enabled: !busy,
          label: 'Choose and crop profile photo',
          onTap: busy ? null : onChoose,
          excludeSemantics: true,
          child: Tooltip(
            message: 'Choose and crop profile photo',
            child: InkResponse(
              key: const ValueKey('edit-profile-photo-button'),
              onTap: busy ? null : onChoose,
              radius: 64,
              child: SizedBox.square(
                dimension: 120,
                child: Stack(
                  children: [
                    ProfileAvatar(
                      profile: profile,
                      size: 112,
                      previewBytes: preview,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.darkGreen,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('A familiar face', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 6),
        Text(
          preview == null
              ? 'Choose a photo, then move, zoom or crop it to your liking.'
              : 'Check your round preview. Save your changes to keep this photo.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy ? null : onChoose,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            preview != null ||
                    profile.avatarPath != null ||
                    profile.googleAvatarUrl != null
                ? 'Change Photo'
                : 'Add Photo',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 52),
            backgroundColor: Colors.white,
          ),
        ),
        if (preview != null)
          TextButton(
            onPressed: busy ? null : onDiscard,
            child: const Text('Keep previous photo'),
          ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              semanticsLabel: 'Preparing or saving your profile',
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.destructiveContainerForeground,
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Uploaded photos are stored privately in your EverCare account.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMuted,
        ),
      ],
    ),
  );
}

class ProfileFormSection extends StatelessWidget {
  const ProfileFormSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.children,
    super.key,
  });
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.darkGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 5),
                  Text(description, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    ),
  );
}
