import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_page.dart';
import '../../widgets/section_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = ['Today', 'Yesterday', 'Earlier'];
    return DetailPage(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () => showMockDialog(
            context,
            title: 'All caught up',
            message:
                'Notifications would be marked as read. This sample list stays unchanged.',
            icon: Icons.done_all_rounded,
          ),
          child: const Text('Mark all'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final group in groups) ...[
            SectionHeader(title: group),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  for (final item
                      in MockData.notifications
                          .where((item) => item['group'] == group)
                          .indexed) ...[
                    ListTile(
                      minTileHeight: 76,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          item.$2['icon']! as IconData,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      title: Text(
                        item.$2['title']! as String,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(item.$2['subtitle']! as String),
                      ),
                      trailing: group == 'Today'
                          ? const CircleAvatar(
                              radius: 5,
                              backgroundColor: AppColors.primaryGreen,
                            )
                          : null,
                      onTap: () => showMockDialog(
                        context,
                        title: item.$2['title']! as String,
                        message:
                            '${item.$2['subtitle']}\n\nThis is a static notification preview.',
                        icon: item.$2['icon']! as IconData,
                      ),
                    ),
                    if (item.$1 <
                        MockData.notifications
                                .where((entry) => entry['group'] == group)
                                .length -
                            1)
                      const Divider(height: 1, indent: 76),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}
