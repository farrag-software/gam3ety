import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/glass_card.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _login() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (_usernameController.text.trim() == 'admin' &&
        _passwordController.text == 'admin') {
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Ambient Liquid Glass Gradient Background
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1E3A8A).withOpacity(0.35)
                      : const Color(0xFF93C5FD).withOpacity(0.45),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF312E81).withOpacity(0.30)
                      : const Color(0xFFC7D2FE).withOpacity(0.40),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon with Vibrancy
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, const Color(0xFF60A5FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'الجمعية الخيرية',
                        style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تسجيل الدخول للوحة التحكم',
                        style: tt.bodyMedium,
                      ),
                      const SizedBox(height: 32),

                      // Glass Card
                      GlassCard(
                        borderRadius: 24,
                        blur: 24,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'اسم المستخدم',
                              style: tt.labelLarge?.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _usernameController,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'أدخل اسم المستخدم',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Text(
                              'كلمة المرور',
                              style: tt.labelLarge?.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'أدخل كلمة المرور',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cs.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: cs.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('تسجيل الدخول'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        'الجمعية الخيرية © 2026',
                        style: tt.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
