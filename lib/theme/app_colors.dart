import 'package:flutter/material.dart';

abstract final class AppColors {
  // A warm, system-grouped palette with EverCare green as the only strong
  // accent. These semantic roles intentionally mirror platform surface and
  // label hierarchies so screens remain calm even when they contain a lot of
  // health information.
  static const background = Color(0xFFF3F5F3);
  static const foreground = Color(0xFF18201B);

  static const card = Color(0xFFFFFFFF);
  static const cardForeground = foreground;
  static const popover = card;
  static const popoverForeground = foreground;

  static const primary = Color(0xFF21835B);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFE3F2E9);
  static const primaryContainerForeground = Color(0xFF164B35);

  static const secondary = Color(0xFFEAEEEB);
  static const secondaryForeground = Color(0xFF27352D);

  static const muted = Color(0xFFF0F2F0);
  static const mutedForeground = Color(0xFF68716B);

  static const accent = Color(0xFFE7F3EC);
  static const accentForeground = Color(0xFF17543B);

  static const destructive = Color(0xFFC83D3D);
  static const destructiveForeground = Color(0xFFFFFFFF);
  static const destructiveContainer = Color(0xFFFBE9E8);
  static const destructiveContainerForeground = Color(0xFF8A2929);

  static const border = Color(0xFFDDE2DE);
  static const input = Color(0xFFD4DAD6);
  static const ring = Color(0xFF21835B);

  // Existing public color names are preserved for feature-level widgets.
  static const primaryGreen = primary;
  static const darkGreen = Color(0xFF15553C);
  static const lightGreen = accent;
  static const primaryText = foreground;
  static const secondaryText = mutedForeground;
  static const surfaceMuted = secondary;

  static const warning = Color(0xFFA9670C);
  static const warningContainer = Color(0xFFFFF2D9);
  static const danger = destructive;
  static const paleBlue = Color(0xFFEAF2F7);
  static const blue = Color(0xFF3479A3);
  static const purple = Color(0xFF6D61A7);

  // Keep elevation perceptible without letting cards appear to float above
  // the content. Feature widgets can layer this token at reduced opacity.
  static const shadow = Color(0x100D1811);
  static const overlay = Color(0x73070D09);
}
