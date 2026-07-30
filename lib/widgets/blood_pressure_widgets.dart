import 'package:flutter/material.dart';

import '../models/blood_pressure_reading.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_page.dart';

Color bloodPressureStatusColor(String status) {
  return switch (status) {
    'Clinician verified' => AppColors.primaryGreen,
    _ => AppColors.secondaryText,
  };
}

class BloodPressureStatusBadge extends StatelessWidget {
  const BloodPressureStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = bloodPressureStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status, style: AppTextStyles.small.copyWith(color: color)),
        ],
      ),
    );
  }
}

class BloodPressureRecordCard extends StatelessWidget {
  const BloodPressureRecordCard({
    required this.record,
    required this.onTap,
    super.key,
  });

  final BloodPressureReading record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(record.dateLabel, style: AppTextStyles.cardTitle),
              ),
              Text(record.timeLabel, style: AppTextStyles.small),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${record.systolic}/${record.diastolic}',
                      style: AppTextStyles.metric.copyWith(fontSize: 26),
                    ),
                    const Text('mmHg', style: AppTextStyles.small),
                  ],
                ),
              ),
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.danger,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text('${record.pulse} BPM', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              BloodPressureStatusBadge(status: record.statusLabel),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.secondaryText,
                size: 20,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                record.source == 'ble'
                    ? Icons.bluetooth_connected_rounded
                    : Icons.edit_note_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Source: ${record.monitorName ?? record.sourceLabel}',
                  style: AppTextStyles.small,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BloodPressureTrendChart extends StatelessWidget {
  const BloodPressureTrendChart({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.labels,
    super.key,
    this.height = 190,
  });

  final List<double> systolic;
  final List<double> diastolic;
  final List<double> pulse;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _Legend(color: AppColors.danger, label: 'Systolic'),
            _Legend(color: AppColors.blue, label: 'Diastolic'),
            _Legend(color: AppColors.warning, label: 'Pulse'),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: height,
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _BloodPressureTrendPainter(
                    systolic: systolic,
                    diastolic: diastolic,
                    pulse: pulse,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map((label) => Text(label, style: AppTextStyles.small))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }
}

class _BloodPressureTrendPainter extends CustomPainter {
  const _BloodPressureTrendPainter({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  final List<double> systolic;
  final List<double> diastolic;
  final List<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(canvas, size, systolic, AppColors.danger);
    _drawSeries(canvas, size, diastolic, AppColors.blue);
    _drawSeries(canvas, size, pulse, AppColors.warning);
  }

  void _drawSeries(Canvas canvas, Size size, List<double> values, Color color) {
    if (values.length < 2) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = ((values[i] - 60) / 80).clamp(0.0, 1.0);
      final y = size.height * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final normalized = ((values[i] - 60) / 80).clamp(0.0, 1.0);
      final y = size.height * (1 - normalized);
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _BloodPressureTrendPainter oldDelegate) {
    return oldDelegate.systolic != systolic ||
        oldDelegate.diastolic != diastolic ||
        oldDelegate.pulse != pulse;
  }
}
