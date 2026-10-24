import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF08080D);
  static const surface = Color(0xFF111118);
  static const surfaceElevated = Color(0xFF181820);
  static const surfaceHighlight = Color(0xFF20202A);

  // Borders
  static const border = Color(0xFF272732);
  static const borderSubtle = Color(0xFF1D1D26);

  // Brand
  static const primary = Color(0xFF8B5CF6);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF6D28D9);

  // Accent
  static const accentBlue = Color(0xFF38BDF8);
  static const accentCyan = Color(0xFF22D3EE);
  static const accentGreen = Color(0xFF34D399);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentRed = Color(0xFFEF4444);
  static const accentOrange = Color(0xFFF97316);

  // Text
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const textDisabled = Color(0xFF52525B);

  // Semantic
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF38BDF8);

  // Category colors
  static const api = Color(0xFF8B5CF6);
  static const mqtt = Color(0xFF22C55E);
  static const code = Color(0xFF38BDF8);
  static const sql = Color(0xFFF59E0B);
  static const tools = Color(0xFFF97316);
  static const notes = Color(0xFFEC4899);

  static const transparent = Colors.transparent;
}
