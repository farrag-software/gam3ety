import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_provider.dart';
import '../core/widgets/glass_bottom_sheet.dart';
import '../core/widgets/glass_dialog.dart';
import '../models/pdf_settings.dart';
import '../screens/login_screen.dart';
import '../utils/backup_manager.dart';
import '../utils/pdf_settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                color: cs.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      'الإعدادات',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Appearance / Theme (Apple HIG Pattern) ─────────────
                    _buildThemeSection(context),
                    const SizedBox(height: 16),

                    // ── App Info ───────────────────────────────────────────
                    _buildSection(
                      label: 'التطبيق',
                      children: [
                        _buildTile(
                          icon: Icons.info_outline_rounded,
                          iconBg: cs.primary.withOpacity(0.12),
                          iconColor: cs.primary,
                          title: 'الإصدار',
                          trailing: Text(
                            '2.0.0 (Apple HIG)',
                            style: tt.labelSmall,
                          ),
                        ),
                        _buildTile(
                          icon: Icons.corporate_fare_rounded,
                          iconBg: const Color(0xFF10B981).withOpacity(0.12),
                          iconColor: const Color(0xFF10B981),
                          title: 'اسم الجمعية',
                          trailing: Text(
                            'الجمعية الخيرية',
                            style: tt.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Data Backup ────────────────────────────────────────
                    _buildSection(
                      label: 'البيانات والنسخ الاحتياطي',
                      children: [
                        _buildTile(
                          icon: Icons.upload_rounded,
                          iconBg: const Color(0xFF10B981).withOpacity(0.12),
                          iconColor: const Color(0xFF10B981),
                          title: 'تصدير نسخة احتياطية',
                          loading: _exporting,
                          onTap: _exporting ? null : _handleExport,
                        ),
                        _buildTile(
                          icon: Icons.download_rounded,
                          iconBg: const Color(0xFFF97316).withOpacity(0.12),
                          iconColor: const Color(0xFFF97316),
                          title: 'استيراد نسخة احتياطية',
                          loading: _importing,
                          onTap: _importing ? null : () => _confirmImport(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Reports Customization ──────────────────────────────
                    _buildSection(
                      label: 'تخصيص التقارير',
                      children: [
                        _buildTile(
                          icon: Icons.tune_rounded,
                          iconBg: const Color(0xFF6366F1).withOpacity(0.12),
                          iconColor: const Color(0xFF6366F1),
                          title: 'تخصيص كشف PDF',
                          onTap: () => _showPdfCustomization(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Account ────────────────────────────────────────────
                    _buildSection(
                      label: 'الحساب',
                      children: [
                        _buildTile(
                          icon: Icons.person_outline_rounded,
                          iconBg: const Color(0xFF8B5CF6).withOpacity(0.12),
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'اسم المسؤول',
                          trailing: Text('المسؤول', style: tt.labelSmall),
                        ),
                        _buildTile(
                          icon: Icons.logout_rounded,
                          iconBg: cs.error.withOpacity(0.12),
                          iconColor: cs.error,
                          title: 'تسجيل الخروج',
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Appearance Section (Light / Dark / Auto) ───────────────────────────────
  Widget _buildThemeSection(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'المظهر والتصميم',
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.palette_outlined, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('نمط العرض', style: tt.titleMedium?.copyWith(fontSize: 14)),
                        Text('اختر المظهر الفاتح أو الداكن', style: tt.bodyMedium?.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Segmented Button
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('فاتح'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      label: Text('تلقائي'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('داكن'),
                    ),
                  ],
                  selected: {themeProvider.themeMode},
                  onSelectionChanged: (selected) {
                    HapticFeedback.selectionClick();
                    themeProvider.setThemeMode(selected.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleExport() async {
    HapticFeedback.lightImpact();
    setState(() => _exporting = true);
    try {
      await BackupManager.exportBackup();
      if (mounted) {
        _showSnack('✅ تم تصدير البيانات بنجاح', const Color(0xFF10B981));
      }
    } catch (e) {
      if (mounted) {
        _showSnack('❌ فشل التصدير: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _confirmImport(BuildContext context) async {
    HapticFeedback.selectionClick();
    final confirmed = await showGlassDialog(
      context,
      title: 'استيراد نسخة احتياطية',
      message: 'سيتم استبدال جميع البيانات الحالية بالبيانات المستوردة.\nهل تريد المتابعة؟',
      confirmLabel: 'استيراد',
      cancelLabel: 'إلغاء',
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFF97316),
      isDestructive: false,
    );

    if (confirmed == true) {
      _handleImport();
    }
  }

  Future<void> _handleImport() async {
    setState(() => _importing = true);
    try {
      final count = await BackupManager.importBackup();
      if (!mounted) return;
      if (count == -1) {
        _showSnack('تم إلغاء الاستيراد', Theme.of(context).colorScheme.outline);
      } else {
        _showSnack('✅ تم استيراد $count مستفيد بنجاح', const Color(0xFF10B981));
      }
    } catch (e) {
      if (mounted) {
        _showSnack('❌ فشل الاستيراد: $e', const Color(0xFFEF4444));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPdfCustomization(BuildContext context) {
    HapticFeedback.lightImpact();
    final store = context.read<PdfSettingsStore>();

    showGlassBottomSheet(
      context,
      builder: (_) => ChangeNotifierProvider.value(
        value: store,
        child: const _PdfCustomizationSheet(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    HapticFeedback.selectionClick();
    final confirmed = await showGlassDialog(
      context,
      title: 'تسجيل الخروج',
      message: 'هل تريد تسجيل الخروج من التطبيق؟',
      confirmLabel: 'خروج',
      cancelLabel: 'إلغاء',
      icon: Icons.logout_rounded,
      iconColor: Theme.of(context).colorScheme.error,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────

  Widget _buildSection({
    required String label,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            label,
            style: tt.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (i) => Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: cs.outlineVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (onTap != null) HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(9),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: iconColor,
                        ),
                      )
                    : Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: tt.titleMedium?.copyWith(
                    fontSize: 14,
                    color: loading ? cs.outline : cs.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing,
              if (onTap != null && trailing == null && !loading)
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: cs.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PDF Customization Sheet Inside Glass Bottom Sheet ───────────────────────

class _PdfCustomizationSheet extends StatefulWidget {
  const _PdfCustomizationSheet();

  @override
  State<_PdfCustomizationSheet> createState() => _PdfCustomizationSheetState();
}

class _PdfCustomizationSheetState extends State<_PdfCustomizationSheet> {
  late PdfSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = context.read<PdfSettingsStore>().settings;
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await context.read<PdfSettingsStore>().update(_draft);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _reset() async {
    HapticFeedback.lightImpact();
    await context.read<PdfSettingsStore>().reset();
    if (mounted) {
      setState(() => _draft = const PdfSettings());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تخصيص كشف PDF',
                        style: tt.titleLarge?.copyWith(fontSize: 16),
                      ),
                      Text(
                        'اضبط مظهر التقرير المصدر',
                        style: tt.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text('إعادة تعيين', style: tt.labelSmall),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sliders
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.52,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _sectionLabel('تقسيم الصفحات'),
                    _intSlider(
                      label: 'صفوف لكل صفحة (أفقي)',
                      icon: Icons.table_rows_rounded,
                      value: _draft.rowsPerPageHorizontal,
                      min: 5,
                      max: 30,
                      color: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(rowsPerPageHorizontal: v)),
                    ),
                    _intSlider(
                      label: 'صفوف لكل صفحة (رأسي)',
                      icon: Icons.view_list_rounded,
                      value: _draft.rowsPerPageVertical,
                      min: 10,
                      max: 60,
                      color: const Color(0xFFEF4444),
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(rowsPerPageVertical: v)),
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel('هوامش وحشو الخلايا'),
                    _doubleSlider(
                      label: 'هامش الصفحة (pt)',
                      icon: Icons.space_bar_rounded,
                      value: _draft.pageMargin,
                      min: 10,
                      max: 60,
                      color: cs.primary,
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(pageMargin: v)),
                    ),
                    _doubleSlider(
                      label: 'حشو أفقي (pt)',
                      icon: Icons.swap_horiz_rounded,
                      value: _draft.cellPaddingH,
                      min: 2,
                      max: 20,
                      color: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(cellPaddingH: v)),
                    ),
                    _doubleSlider(
                      label: 'حشو رأسي (pt)',
                      icon: Icons.swap_vert_rounded,
                      value: _draft.cellPaddingV,
                      min: 2,
                      max: 20,
                      color: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(cellPaddingV: v)),
                    ),
                    const SizedBox(height: 8),
                    _sectionLabel('أحجام الخطوط'),
                    _doubleSlider(
                      label: 'خط العنوان الرئيسي (pt)',
                      icon: Icons.title_rounded,
                      value: _draft.headerFontSize,
                      min: 14,
                      max: 32,
                      color: cs.primary,
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(headerFontSize: v)),
                    ),
                    _doubleSlider(
                      label: 'خط رؤوس الأعمدة (pt)',
                      icon: Icons.format_size_rounded,
                      value: _draft.tableHeaderFontSize,
                      min: 7,
                      max: 16,
                      color: cs.primary,
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(tableHeaderFontSize: v)),
                    ),
                    _doubleSlider(
                      label: 'خط بيانات الجدول (pt)',
                      icon: Icons.text_fields_rounded,
                      value: _draft.tableDataFontSize,
                      min: 6,
                      max: 14,
                      color: cs.primary,
                      onChanged: (v) => setState(() => _draft = _draft.copyWith(tableDataFontSize: v)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ الإعدادات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: tt.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _intSlider({
    required String label,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return _sliderRow(
      label: label,
      icon: icon,
      valueLabel: '$value',
      color: color,
      slider: Slider(
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: max - min,
        activeColor: color,
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }

  Widget _doubleSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return _sliderRow(
      label: label,
      icon: icon,
      valueLabel: value.toStringAsFixed(1),
      color: color,
      slider: Slider(
        value: value,
        min: min,
        max: max,
        divisions: ((max - min) * 2).round(),
        activeColor: color,
        onChanged: onChanged,
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required IconData icon,
    required String valueLabel,
    required Color color,
    required Widget slider,
  }) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valueLabel,
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}
