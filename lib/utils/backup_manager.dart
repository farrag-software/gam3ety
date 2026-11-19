import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

// Conditional imports for platform-specific implementations
import 'web_downloader_io.dart'
    if (dart.library.html) 'web_downloader_web.dart';
import 'native_exporter_io.dart'
    if (dart.library.html) 'native_exporter_web.dart';

/// Platform-aware backup utility.
///
/// - **Export**: serialises all employees + payments to a JSON backup file.
///   Web → browser file download; Native → temp file shared via share_plus.
/// - **Import**: opens a file picker for a .json file → replaces all DB data.
class BackupManager {
  BackupManager._();

  // ── Export ────────────────────────────────────────────────────────────────

  static Future<void> exportBackup() async {
    final data = await DatabaseHelper.instance.exportAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonStr);
    final now = DateTime.now();
    final filename =
        'gam3ety_backup_${now.year}-${_p(now.month)}-${_p(now.day)}.json';

    if (kIsWeb) {
      WebDownloader.download(bytes, filename);
    } else {
      await NativeExporter.share(bytes, filename);
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Opens a file picker and restores backup.
  /// Returns the number of restored employees, or -1 on cancel/error.
  static Future<int> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return -1;
    final bytes = result.files.first.bytes;
    if (bytes == null) return -1;

    try {
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await DatabaseHelper.instance.importAllData(data);
      final employees = data['employees'] as List<dynamic>? ?? [];
      return employees.length;
    } catch (_) {
      return -1;
    }
  }

  static String _p(int n) => n.toString().padLeft(2, '0');
}
