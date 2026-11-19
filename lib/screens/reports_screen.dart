import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/widgets/empty_state.dart';
import '../core/widgets/glass_bottom_sheet.dart';
import '../database/database_helper.dart';
import '../utils/excel_exporter.dart';
import '../utils/pdf_exporter.dart';
import '../utils/pdf_settings_store.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  // Current month stats
  double _currentMonthTotal = 0;
  int _currentMonthFamilies = 0;
  String _currentMonthLabel = '';

  // Preview: all employees with a payment this month
  List<Map<String, dynamic>> _previewRows = [];

  // Archive: distinct month/year groups (excluding current month)
  List<Map<String, dynamic>> _archiveGroups = [];

  bool _loading = true;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    // Current month label (Arabic)
    final arabicMonths = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    _currentMonthLabel = '${arabicMonths[month]} $year';

    // Stats for current month
    final total = await DatabaseHelper.instance.totalForMonth(month, year);
    final families = await DatabaseHelper.instance.familiesForMonth(month, year);

    // Preview rows: recent activity for this month
    final activity = await DatabaseHelper.instance.getRecentActivity(limit: 5);
    final preview = activity
        .where(
          (a) => (a['month'] as int) == month && (a['year'] as int) == year,
        )
        .toList();

    // Archive: group all payments by month/year — ignoring current
    final allEmployees = await DatabaseHelper.instance.getAllEmployees();
    final archive = <String, Map<String, dynamic>>{};
    for (final e in allEmployees) {
      final payments = await DatabaseHelper.instance.getPaymentsForEmployee(e.id!);
      for (final p in payments) {
        if (p.month == month && p.year == year) continue; // skip current
        final key = '${p.year}-${p.month}';
        if (!archive.containsKey(key)) {
          archive[key] = {
            'month': p.month,
            'year': p.year,
            'label': '${arabicMonths[p.month]} ${p.year}',
            'families': 0,
          };
        }
        archive[key]!['families'] = (archive[key]!['families'] as int) + 1;
      }
    }
    final sortedArchive = archive.values.toList()
      ..sort((a, b) {
        final aDate = DateTime(a['year'] as int, a['month'] as int);
        final bDate = DateTime(b['year'] as int, b['month'] as int);
        return bDate.compareTo(aDate);
      });

    if (mounted) {
      setState(() {
        _currentMonthTotal = total;
        _currentMonthFamilies = families;
        _previewRows = preview;
        _archiveGroups = sortedArchive;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: cs.primary))
                  : RefreshIndicator(
                      onRefresh: loadData,
                      color: cs.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(context),
                            const SizedBox(height: 24),
                            _buildCurrentMonthSection(context),
                            const SizedBox(height: 24),
                            _buildArchiveSection(context),
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

  // ── Bottom Sheet Format Chooser (Apple HIG Liquid Glass) ───────────────────
  Future<void> _showFormatChooser(
    String monthLabel,
    int month,
    int year,
  ) async {
    HapticFeedback.lightImpact();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showGlassBottomSheet(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر صيغة التقرير',
              style: tt.headlineMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تقرير توزيعات شهر $monthLabel',
              style: tt.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    context: ctx,
                    icon: Icons.table_chart_rounded,
                    color: const Color(0xFF10B981),
                    title: 'Excel',
                    subtitle: 'للتعديل والأرشفة',
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      _snack('جاري تحضير ملف Excel...');
                      final payments = await DatabaseHelper.instance
                          .getPaymentsByMonth(month, year);
                      await ExcelExporter.exportMonthReport(
                        monthLabel: monthLabel,
                        payments: payments,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatOption(
                    context: ctx,
                    icon: Icons.library_books_rounded,
                    color: const Color(0xFFF59E0B),
                    title: 'PDF أفقي',
                    subtitle: 'كشف شامل',
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      _snack('جاري تحضير ملف PDF...');
                      final payments = await DatabaseHelper.instance
                          .getPaymentsByMonth(month, year);
                      final settings =
                          context.read<PdfSettingsStore>().settings;
                      await PdfExporter.exportMonthReport(
                        monthLabel: monthLabel,
                        payments: payments,
                        settings: settings,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatOption(
                    context: ctx,
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'PDF رأسي',
                    subtitle: 'مختصر للطباعة',
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      _snack('جاري تحضير ملف PDF...');
                      final payments = await DatabaseHelper.instance
                          .getPaymentsByMonth(month, year);
                      final settings =
                          context.read<PdfSettingsStore>().settings;
                      await PdfExporter.exportVerticalMonthReport(
                        monthLabel: monthLabel,
                        payments: payments,
                        settings: settings,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final tt = Theme.of(context).textTheme;

    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: tt.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'التقارير الشهرية',
            style: tt.headlineMedium?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(_pulseAnim.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ──────────────────────────────────────────────────────────
  Widget _buildSummaryCards(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            context: context,
            label: 'إجمالي التوزيعات ($_currentMonthLabel)',
            value: _currentMonthTotal.toStringAsFixed(0),
            suffix: 'ج.م',
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            context: context,
            label: 'الأسر المستفيدة',
            value: '$_currentMonthFamilies',
            suffix: 'أسرة',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required String suffix,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.labelSmall),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: tt.headlineMedium?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Current Month Section ──────────────────────────────────────────────────
  Widget _buildCurrentMonthSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'معاينة الشهر الحالي',
              style: tt.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentMonthLabel,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كشف مرتبات الأسر المستحقة',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(_currentMonthLabel, style: tt.labelSmall),
                      ],
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              if (_previewRows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 40,
                        color: cs.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد صرفيات هذا الشهر بعد',
                        style: tt.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                _buildPreviewTable(context),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final now = DateTime.now();
                      _showFormatChooser(_currentMonthLabel, now.month, now.year);
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('تحميل التقرير'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          horizontalInside: BorderSide(color: cs.outlineVariant),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: cs.surface),
            children: [
              _th(context, 'الاسم الكامل'),
              _th(context, 'الرقم القومي'),
              _th(context, 'القيمة'),
              _th(context, 'الحالة'),
            ],
          ),
          ..._previewRows.map(
            (row) => TableRow(
              children: [
                _td(
                  Text(
                    row['employee_name'] as String,
                    style: tt.titleMedium?.copyWith(fontSize: 13),
                  ),
                ),
                _td(
                  Text(
                    '—',
                    style: tt.labelSmall,
                  ),
                ),
                _td(
                  Text(
                    '${(row['amount'] as num).toStringAsFixed(0)} ج.م',
                    style: tt.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                _td(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (row['received'] as int) == 1
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (row['received'] as int) == 1 ? 'تم' : 'معلق',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: (row['received'] as int) == 1
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(BuildContext context, String t) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        t,
        style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _td(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: child,
  );

  // ── Archive Section ────────────────────────────────────────────────────────
  Widget _buildArchiveSection(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأرشيف',
          style: tt.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (_archiveGroups.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'لا يوجد أرشيف بعد',
            subtitle: 'الكشوف السابقة ستظهر هنا تلقائياً',
          )
        else
          ...List.generate(
            _archiveGroups.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildArchiveItem(context, _archiveGroups[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildArchiveItem(BuildContext context, Map<String, dynamic> group) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _showFormatChooser(
              group['label'] as String,
              group['month'] as int,
              group['year'] as int,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 22,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['label'] as String,
                          style: tt.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تم الإصدار • ${group['families']} أسرة',
                          style: tt.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showFormatChooser(
                      group['label'] as String,
                      group['month'] as int,
                      group['year'] as int,
                    );
                  },
                  icon: Icon(Icons.download_rounded, size: 20, color: cs.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
