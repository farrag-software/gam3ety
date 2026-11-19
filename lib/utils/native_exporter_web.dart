/// Stub for web: no-op (web uses dart:html directly).
class NativeExporter {
  static Future<void> share(List<int> bytes, String filename) async {
    // On web this is never called.
  }
}
