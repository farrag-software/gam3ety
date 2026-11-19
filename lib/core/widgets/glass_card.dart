import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Apple HIG Liquid-Glass inspired card with backdrop blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsets padding;
  final double borderRadius;
  final EdgeInsets? margin;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.glassBackground(brightness),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppColors.glassBorder(brightness)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.glassShadow(brightness),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
