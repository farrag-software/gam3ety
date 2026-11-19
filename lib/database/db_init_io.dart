import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

/// Called at app start on native (Windows/Linux/Mac).
void initDatabase() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
