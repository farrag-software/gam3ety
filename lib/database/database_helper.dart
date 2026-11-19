/// Conditional export: web uses in-memory store, native uses SQLite.
export 'database_helper_native.dart'
    if (dart.library.html) 'database_helper_web.dart';
