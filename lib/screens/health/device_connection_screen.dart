import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_page.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  bool _searched = false;
  bool _connected = false;

  @override
  Widget build(BuildContext context) {
    return DetailPage(
      title: 'Connect Blood Pressure Monitor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 8),
              ),
              child: Icon(
                _connected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                color: AppColors.primaryGreen,
                size: 62,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Column(
              children: [
                Text(MockData.deviceName, style: AppTextStyles.sectionTitle),
                SizedBox(height: 5),
                Text(
                  'Model YK-BPA1 · Upper-arm blood pressure monitor',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AppCard(
            color: (_connected ? AppColors.primaryGreen : AppColors.blue)
                .withValues(alpha: .08),
            borderColor: (_connected ? AppColors.primaryGreen : AppColors.blue)
                .withValues(alpha: .18),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _connected ? AppColors.primaryGreen : AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _connected
                        ? 'Mock status: Connected'
                        : _searched
                        ? 'Mock device discovered'
                        : 'Ready to preview device search',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => setState(() {
              _searched = true;
              _connected = false;
            }),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search for Device'),
          ),
          if (_searched) ...[
            const SizedBox(height: 18),
            const Text('Discovered device', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MockData.deviceName,
                          style: AppTextStyles.cardTitle,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Mock signal · Nearby',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _connected
                        ? Icons.check_circle_rounded
                        : Icons.bluetooth_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _connected = true),
              icon: Icon(
                _connected ? Icons.check_circle_rounded : Icons.link_rounded,
              ),
              label: Text(_connected ? 'Connected' : 'Connect'),
            ),
          ],
          const SizedBox(height: 26),
          const Text('Setup instructions', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          const AppCard(
            child: Column(
              children: [
                _Instruction(
                  number: '1',
                  text: 'Turn on Bluetooth on the Android phone.',
                ),
                _Instruction(
                  number: '2',
                  text: 'Turn on the Yongrow/Yonker YK-BPA1 monitor.',
                ),
                _Instruction(
                  number: '3',
                  text: 'Keep the device close to the phone.',
                ),
                _Instruction(number: '4', text: 'Tap Search for Device.'),
                _Instruction(number: '5', text: 'Select the YK-BPA1 monitor.'),
                _Instruction(
                  number: '6',
                  text: 'Complete a blood-pressure measurement.',
                ),
                _Instruction(
                  number: '7',
                  text: 'Wait for the result to synchronize.',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppCard(
            color: Color(0xFFFFF8EB),
            borderColor: Color(0xFFF5DFAF),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'UI preview only. No Bluetooth search, pairing, permission '
                    'request, or device communication occurs.',
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({
    required this.number,
    required this.text,
    this.showDivider = true,
  });

  final String number;
  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.lightGreen,
                child: Text(
                  number,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(child: Text(text, style: AppTextStyles.body)),
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}
