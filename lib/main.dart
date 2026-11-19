import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Conditional import: web = no-op stub, native = sqflite_common_ffi init
import 'database/db_init_stub.dart'
    if (dart.library.io) 'database/db_init_io.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/login_screen.dart';
import 'utils/pdf_settings_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize sqflite for desktop (no-op on web / Android / iOS)
  initDatabase();

  // Load persisted settings before launching the UI
  final pdfSettingsStore = PdfSettingsStore();
  await pdfSettingsStore.load();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PdfSettingsStore>.value(value: pdfSettingsStore),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const Gam3etyApp(),
    ),
  );
}

class Gam3etyApp extends StatelessWidget {
  const Gam3etyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'الجمعية الخيرية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ── Apple HIG: light + dark + system toggle ────────────────────────
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const LoginScreen(),
    );
  }
}
