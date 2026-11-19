import 'package:flutter/material.dart';

/// Shortcuts so screens can write `context.colors` instead of
/// `Theme.of(context).colorScheme`.
extension ContextExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
