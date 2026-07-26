import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
