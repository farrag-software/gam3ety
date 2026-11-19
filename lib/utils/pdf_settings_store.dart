import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_settings.dart';

/// A [ChangeNotifier] that holds [PdfSettings] and persists them via
/// [SharedPreferences] so they survive app restarts.
class PdfSettingsStore extends ChangeNotifier {
  static const _key = 'pdf_settings_v1';

  PdfSettings _settings = const PdfSettings();

  PdfSettings get settings => _settings;

  // ── Initialization ─────────────────────────────────────────────────────────

  /// Must be called once at app startup (before runApp) or inside initState
  /// of the root widget. Loads persisted settings from disk.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _settings = PdfSettings.fromMap(map);
      }
    } catch (_) {
      // If anything goes wrong, fall back to defaults silently.
      _settings = const PdfSettings();
    }
    notifyListeners();
  }

  // ── Mutators ───────────────────────────────────────────────────────────────

  /// Replace the current settings and persist to disk.
  Future<void> update(PdfSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _persist();
  }

  /// Reset to factory defaults and persist.
  Future<void> reset() async {
    _settings = const PdfSettings();
    notifyListeners();
    await _persist();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_settings.toMap()));
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }
}
