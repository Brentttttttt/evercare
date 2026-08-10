import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class JournalPaper extends StatelessWidget {
  const JournalPaper({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final resolvedPadding =
            padding ??
            EdgeInsets.fromLTRB(compact ? 42 : 54, 24, compact ? 18 : 26, 28);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE7DEC6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x161A3D2C),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: CustomPaint(
              painter: JournalPaperPainter(compact: compact),
              child: Padding(padding: resolvedPadding, child: child),
            ),
          ),
        );
      },
    );
  }
}

class JournalPaperPainter extends CustomPainter {
  const JournalPaperPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x24709B88)
      ..strokeWidth = 1;
    for (double y = 126; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = const Color(0x4AD98A78)
      ..strokeWidth = 1.2;
    final marginX = compact ? 30.0 : 40.0;
    canvas.drawLine(
      Offset(marginX, 0),
      Offset(marginX, size.height),
      marginPaint,
    );

    final holeFill = Paint()..color = const Color(0xFFF5EEDB);
    final holeBorder = Paint()
      ..color = const Color(0xFFDBD0B5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 72; y < size.height - 20; y += 92) {
      final center = Offset(compact ? 15 : 20, y);
      canvas.drawCircle(center, 5.5, holeFill);
      canvas.drawCircle(center, 5.5, holeBorder);
    }
  }

  @override
  bool shouldRepaint(JournalPaperPainter oldDelegate) =>
      oldDelegate.compact != compact;
}

class JournalSection extends StatelessWidget {
  const JournalSection({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
    this.subtitle,
    this.collapsible = false,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: const Color(0xEFFFFDF7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE7DF)),
    );
    if (collapsible) {
      return Material(
        color: const Color(0xEFFFFDF7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFDDE7DF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            maintainState: true,
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            leading: Icon(icon, color: AppColors.primaryGreen),
            title: Text(title, style: AppTextStyles.cardTitle),
            subtitle: subtitle == null
                ? null
                : Text(subtitle!, style: AppTextStyles.small),
            children: [child],
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.cardTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTextStyles.small),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class JournalOptionChip extends StatelessWidget {
  const JournalOptionChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.icon,
    this.singleChoice = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  final bool singleChoice;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(label);
    final avatar = icon == null
        ? null
        : Icon(
            icon,
            size: 18,
            color: selected ? AppColors.darkGreen : AppColors.secondaryText,
          );
    return Semantics(
      button: true,
      selected: selected,
      label: '$label${selected ? ', selected' : ''}',
      child: singleChoice
          ? ChoiceChip(
              label: labelWidget,
              avatar: avatar,
              selected: selected,
              showCheckmark: icon == null,
              onSelected: onSelected,
            )
          : FilterChip(
              label: labelWidget,
              avatar: avatar,
              selected: selected,
              showCheckmark: icon == null,
              onSelected: onSelected,
            ),
    );
  }
}
