import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../theme/app_colors.dart';

/// A shared profile photo with an honest, private fallback while loading.
///
/// An uploaded photo takes precedence over Google metadata. If that photo cannot
/// load, keep the initials instead of unexpectedly reverting to a Google photo.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.profile,
    super.key,
    this.size = 96,
    this.previewBytes,
  }) : assert(size > 0);

  final UserProfile profile;
  final double size;
  final Uint8List? previewBytes;

  @override
  Widget build(BuildContext context) {
    final initials = profile.initials;
    final fallback = ColoredBox(
      color: AppColors.primaryContainer,
      child: Center(
        child: initials.isEmpty
            ? Icon(
                Icons.person_outline_rounded,
                color: AppColors.darkGreen,
                size: size * .46,
              )
            : Padding(
                padding: EdgeInsets.all(size * .18),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: size * .34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
              ),
      ),
    );
    final hasUploadedPhoto =
        (profile.avatarPath?.trim().isNotEmpty ?? false) ||
        (profile.avatarUrl?.trim().isNotEmpty ?? false);
    final url = (hasUploadedPhoto ? profile.avatarUrl : profile.googleAvatarUrl)
        ?.trim();
    Widget photo = fallback;
    if (previewBytes != null) {
      photo = Image.memory(
        previewBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: (_, child, frame, _) => frame == null ? fallback : child,
      );
    } else if (url != null && url.isNotEmpty) {
      photo = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        frameBuilder: (_, child, frame, _) => frame == null ? fallback : child,
      );
    }
    final name = profile.fullName.trim();
    return Semantics(
      image: true,
      label: name.isEmpty ? 'Profile picture' : 'Profile picture for $name',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: ClipOval(child: photo),
        ),
      ),
    );
  }
}
