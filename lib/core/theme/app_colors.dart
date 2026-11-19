import 'package:flutter/material.dart';

/// Semantic color tokens for Gam3ety — Apple HIG + Liquid Glass inspired.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF136DEC);
  static const primaryDark = Color(0xFF60A5FA);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const lightSurface = Color(0xFFF6F7F8);
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
  static const lightTextMuted = Color(0xFF94A3B8);
  static const lightDivider = Color(0xFFF1F5F9);
  static const lightInputBorder = Color(0xFFE2E8F0);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const darkSurface = Color(0xFF0F1117);
  static const darkSurfaceElevated = Color(0xFF1A1D27);
  static const darkTextPrimary = Color(0xFFE2E8F0);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextMuted = Color(0xFF475569);
  static const darkDivider = Color(0xFF1E293B);
  static const darkInputBorder = Color(0xFF334155);

  // ── Semantic (shared) ──────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF34D399);
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFFBBF24);
  static const destructive = Color(0xFFEF4444);
  static const destructiveDark = Color(0xFFFB7185);

  // ── Glass tokens ───────────────────────────────────────────────────────────
  static Color glassBackground(Brightness brightness) =>
      brightness == Brightness.light
          ? Colors.white.withOpacity(0.72)
          : const Color(0xFF1E2130).withOpacity(0.72);

  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.light
          ? Colors.white.withOpacity(0.3)
          : Colors.white.withOpacity(0.08);

  static Color glassShadow(Brightness brightness) =>
      brightness == Brightness.light
          ? Colors.black.withOpacity(0.08)
          : Colors.black.withOpacity(0.3);

  // ── Avatar palette ─────────────────────────────────────────────────────────
  static const avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
  ];
}
