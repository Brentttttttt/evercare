import 'package:flutter/material.dart';

import '../models/blood_pressure_assessment.dart';
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

Color bloodPressureRangeColor(BloodPressureAssessment assessment) =>
    switch (assessment.category) {
      BloodPressureCategory.normal => AppColors.primaryGreen,
      BloodPressureCategory.elevated => const Color(0xFF93690D),
      BloodPressureCategory.hypertensionStage1 => const Color(0xFFA85A16),
      BloodPressureCategory.hypertensionStage2 => const Color(0xFFB24636),
      BloodPressureCategory.severeHypertension => AppColors.danger,
      BloodPressureCategory.lowerThanUsual => AppColors.blue,
    };

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
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 3,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
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
    final assessment = BloodPressureAssessment.fromValues(
      systolic: record.systolic,
      diastolic: record.diastolic,
      pulse: record.pulse,
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final readingValue = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${record.systolic}/${record.diastolic}',
          style: AppTextStyles.metric.copyWith(fontSize: 26),
        ),
        const Text('mmHg', style: AppTextStyles.small),
      ],
    );
    final pulseValue = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_rounded, color: AppColors.danger, size: 18),
        const SizedBox(width: 5),
        Text('${record.pulse} BPM', style: AppTextStyles.cardTitle),
      ],
    );
    return Semantics(
      button: true,
      label:
          '${assessment.friendlyStatus}. ${assessment.label}. Upper number '
          '${record.systolic}, lower number ${record.diastolic}, pulse '
          '${record.pulse} beats per minute.',
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.dateLabel, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 3),
                  Text(record.timeLabel, style: AppTextStyles.small),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.dateLabel,
                      style: AppTextStyles.cardTitle,
                    ),
                  ),
                  Text(record.timeLabel, style: AppTextStyles.small),
                ],
              ),
            const SizedBox(height: 11),
            Text(assessment.friendlyStatus, style: AppTextStyles.cardTitle),
            const SizedBox(height: 2),
            Text(
              assessment.label,
              style: AppTextStyles.small.copyWith(
                color: bloodPressureRangeColor(assessment),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 15),
            if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  readingValue,
                  const SizedBox(height: 10),
                  pulseValue,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: readingValue),
                  pulseValue,
                ],
              ),
            const SizedBox(height: 13),
            if (largeText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BloodPressureStatusBadge(status: record.statusLabel),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.secondaryText,
                      size: 16,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  BloodPressureStatusBadge(status: record.statusLabel),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.secondaryText,
                    size: 16,
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: .65),
              ),
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
      ),
    );
  }
}

class BloodPressureFriendlyGuidance extends StatelessWidget {
  const BloodPressureFriendlyGuidance({required this.assessment, super.key});

  final BloodPressureAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final color = bloodPressureRangeColor(assessment);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          assessment.friendlySupportingText,
          style: AppTextStyles.bodyMuted.copyWith(height: 1.42),
        ),
        const SizedBox(height: 9),
        Text(
          assessment.upperLowerExplanation,
          style: AppTextStyles.bodyMuted.copyWith(
            color: AppColors.foreground,
            height: 1.42,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: .22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.refresh_rounded, size: 19, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assessment.nextStep,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BloodPressureReadingDisclaimer extends StatelessWidget {
  const BloodPressureReadingDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              BloodPressureAssessment.shortDisclaimer,
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.38,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'More about this result',
            onPressed: () => _showBloodPressureDisclaimerInfo(context),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

Future<void> _showBloodPressureDisclaimerInfo(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('About this blood pressure result'),
      content: const Text(BloodPressureAssessment.additionalDisclaimerInfo),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
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
            _Legend(color: AppColors.danger, label: 'Upper number (systolic)'),
            _Legend(color: AppColors.blue, label: 'Lower number (diastolic)'),
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
