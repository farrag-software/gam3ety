import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Glassmorphic confirmation dialog — Apple HIG style.
Future<bool?> showGlassDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'تأكيد',
  String cancelLabel = 'إلغاء',
  bool isDestructive = false,
  IconData? icon,
  Color? iconColor,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final brightness = Theme.of(ctx).brightness;
      final cs = Theme.of(ctx).colorScheme;
      final tt = Theme.of(ctx).textTheme;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.glassBackground(brightness),
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: AppColors.glassBorder(brightness)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.glassShadow(brightness),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (iconColor ?? cs.primary)
                                .withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: iconColor ?? cs.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        title,
                        style: tt.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(cancelLabel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: isDestructive
                                  ? FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                    )
                                  : null,
                              child: Text(confirmLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
