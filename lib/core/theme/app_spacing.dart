import 'package:flutter/material.dart';

/// 8dp spacing rhythm + corner radius scale (Apple HIG).
abstract final class AppSpacing {
  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // ── Padding presets ────────────────────────────────────────────────────────
  static const pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const cardPadding = EdgeInsets.all(lg);
  static const sectionGap = SizedBox(height: xl);
  static const itemGap = SizedBox(height: md);

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  static final borderRadiusSm = BorderRadius.circular(radiusSm);
  static final borderRadiusMd = BorderRadius.circular(radiusMd);
  static final borderRadiusLg = BorderRadius.circular(radiusLg);
  static final borderRadiusXl = BorderRadius.circular(radiusXl);
}
