import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';
import '../../widgets/primary_button.dart';
import '../authentication/auth_widgets.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = MockData.profile;
    return DetailPage(
      title: 'Personal Information',
      child: Column(
        children: [
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.lightGreen,
            child: Text(
              'MS',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => showMockDialog(
              context,
              title: 'Profile photo',
              message: 'Photo selection is not available in this UI prototype.',
              icon: Icons.photo_camera_outlined,
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Change photo'),
          ),
          const SizedBox(height: 18),
          MockTextField(
            label: 'Full name',
            hint: profile['name'],
            icon: Icons.person_outline_rounded,
          ),
          MockTextField(
            label: 'Email address',
            hint: profile['email'],
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          MockTextField(
            label: 'Phone number',
            hint: profile['phone'],
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          MockTextField(
            label: 'Date of birth',
            hint: profile['birthDate'],
            icon: Icons.cake_outlined,
          ),
          MockTextField(
            label: 'Address',
            hint: profile['address'],
            icon: Icons.home_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Save Changes',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 10),
          Text(
            'Changes are not permanently saved.',
            style: AppTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}
