import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/widgets/empty_state.dart';
import '../core/widgets/glass_card.dart';
import '../core/widgets/stat_card.dart';
import '../database/database_helper.dart';
import 'export_screen.dart';
import 'month_payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _totalEmployees = 0;
  int _totalFamilyMembers = 0;
  double _totalSalaries = 0.0;
  int _pendingCount = 0;
  List<Map<String, dynamic>> _archiveGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// Called externally (from MainScreen) to refresh after adding an employee.
  Future<void> loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final summary = await DatabaseHelper.instance.getEmployeesSummary();
    final archive = await DatabaseHelper.instance.getMonthlyArchive(limit: 5);
    final pending = await DatabaseHelper.instance.getPendingPaymentsCount();
    if (mounted) {
      setState(() {
        _totalEmployees = summary['total_employees'] as int;
        _totalFamilyMembers = summary['total_family_members'] as int;
        _totalSalaries = summary['total_salaries'] as double;
        _archiveGroups = archive;
        _pendingCount = pending;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: loadData,
          color: cs.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildWelcomeBanner(context),
                    const SizedBox(height: 16),
                    _buildStatsRow(),
                    const SizedBox(height: 16),
                    _buildExportButton(context),
                    const SizedBox(height: 24),
                    _buildRecentActivity(context),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (Apple HIG / Glassy) ────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [cs.primary, const Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً بك', style: tt.labelSmall),
                  Text(
                    'لوحة تحكم المسؤول',
                    style: tt.titleLarge?.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 20,
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome Banner (Vibrant Gradient + Depth) ──────────────────────────────
  Widget _buildWelcomeBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, const Color(0xFF2563EB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي المستفيدين (أفراد)',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFBFDBFE),
                ),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _loading ? '...' : '$_totalFamilyMembers ',
                      style: GoogleFonts.cairo(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'مستفيد',
                      style: GoogleFonts.cairo(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _loading
                    ? '...'
                    : 'إجمالي الرواتب: ${_totalSalaries.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFBFDBFE),
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row using Liquid Glass Cards ──────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(
      children: [
        StatCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: const Color(0xFF10B981),
          value: _loading ? '...' : '$_totalEmployees',
          label: 'إجمالي الأسر',
        ),
        const SizedBox(width: 12),
        StatCard(
          icon: Icons.pending_actions_rounded,
          iconColor: const Color(0xFFEA580C),
          value: _loading ? '...' : '$_pendingCount',
          label: 'توزيعات معلقة',
        ),
      ],
    );
  }

  // ── Action / Export Button ─────────────────────────────────────────────────
  Widget _buildExportButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () async {
          HapticFeedback.lightImpact();
          final now = DateTime.now();
          final exists = _archiveGroups.any(
            (g) => g['month'] == now.month && g['year'] == now.year,
          );
          if (exists) {
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
            final monthLabel = '${arabicMonths[now.month]} ${now.year}';
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MonthPaymentsScreen(
                  month: now.month,
                  year: now.year,
                  monthLabel: monthLabel,
                ),
              ),
            );
            if (result == true) loadData();
          } else {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportScreen()),
            );
            if (result == true) loadData();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.table_chart_outlined, size: 20),
        label: Text(
          'كشف رواتب شهر ${DateTime.now().month}',
          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Recent Activity / Monthly Archive ──────────────────────────────────────
  Widget _buildRecentActivity(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أحدث الكشوف الشهرية',
              style: tt.titleLarge?.copyWith(fontSize: 17),
            ),
            if (_archiveGroups.isNotEmpty)
              Text(
                'آخر ${_archiveGroups.length} أشهر',
                style: tt.labelSmall,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: cs.primary),
            ),
          )
        else if (_archiveGroups.isEmpty)
          EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد كشوف محفوظة بعد',
            subtitle: 'أضف مستفيداً ثم أنشئ استمارة الشهر',
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

  Widget _buildArchiveItem(BuildContext context, Map<String, dynamic> data) {
    final int month = data['month'] as int;
    final int year = data['year'] as int;
    final String label = data['month_label'] as String;
    final int families = data['families'] as int;
    final double amount = (data['total_amount'] as num).toDouble();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MonthPaymentsScreen(
                month: month,
                year: year,
                monthLabel: label,
              ),
            ),
          );
          loadData();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.folder_shared_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: tt.titleMedium?.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('$families سلة/أسرة', style: tt.bodyMedium?.copyWith(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${amount.toStringAsFixed(0)} ج.م',
                    style: tt.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'عرض التفاصيل',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
