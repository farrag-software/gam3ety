import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/employee.dart';
import '../models/payment.dart';
import '../database/database_helper.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  static const _primaryColor = Color(0xFF136dec);

  final _searchController = TextEditingController();
  int _selectedFilter = 0;
  final _filters = ['الكل', 'منطقة أ', 'منطقة ب', 'حالات خاصة'];

  List<Employee> _employees = [];
  // Track selected employee ids
  final Set<int> _selectedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    final employees = await DatabaseHelper.instance.getAllEmployees();
    if (mounted) {
      setState(() {
        _employees = employees;
        // Pre-select all employees
        _selectedIds.addAll(employees.map((e) => e.id!));
        _loading = false;
      });
    }
  }

  List<Employee> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _employees.where((e) {
      final matchesSearch =
          query.isEmpty ||
          e.name.toLowerCase().contains(query) ||
          e.nationalId.contains(query);
      return matchesSearch;
    }).toList();
  }

  int get _selectedCount => _selectedIds.length;

  void _toggleAll(bool select) {
    setState(() {
      if (select) {
        _selectedIds.addAll(_employees.map((e) => e.id!));
      } else {
        _selectedIds.clear();
      }
    });
  }

  // Avatar color based on name
  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFFF97316),
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1);
    return '${parts[0].substring(0, 1)}.${parts[1].substring(0, 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildStats()),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickySearchDelegate(
                            child: _buildSearchAndFilters(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'قائمة المستفيدين (${filtered.length})',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleAll(
                                    _selectedIds.length < _employees.length,
                                  ),
                                  child: Text(
                                    _selectedIds.length == _employees.length
                                        ? 'إلغاء تحديد الكل'
                                        : 'تحديد الكل',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        filtered.isEmpty
                            ? SliverToBoxAdapter(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          size: 48,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد نتائج',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => i < filtered.length
                                      ? _buildItem(filtered[i])
                                      : null,
                                ),
                              ),
                        const SliverToBoxAdapter(child: SizedBox(height: 90)),
                      ],
                    ),
            ),
          ],
        ),
        bottomSheet: _buildFooter(),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) => SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            color: const Color(0xFF475569),
          ),
          Expanded(
            child: Text(
              'إدارة كشوف المرتبات',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: const Color(0xFF475569),
          ),
        ],
      ),
    ),
  );

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStats() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Expanded(
          child: _buildStatCard(
            iconBg: _primaryColor.withOpacity(0.15),
            icon: Icons.group_outlined,
            iconColor: _primaryColor,
            label: 'المستفيدين المحددين',
            value: '$_selectedCount',
            suffix: '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            iconBg: const Color(0xFF10B981).withOpacity(0.15),
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFF10B981),
            label: 'إجمالي تقديري',
            value:
                '${_employees.where((e) => _selectedIds.contains(e.id)).fold(0.0, (s, e) => s + e.monthlySalary).toStringAsFixed(0)}',
            suffix: ' ج.م',
          ),
        ),
      ],
    ),
  );

  Widget _buildStatCard({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String suffix,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: suffix,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Search + Filters ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilters() => Container(
    color: Colors.white.withOpacity(0.95),
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الرقم القومي',
              hintStyle: GoogleFonts.cairo(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
              suffixIcon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primaryColor, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _selectedFilter == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: selected ? _primaryColor : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    _filters[i],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  // ── List item ──────────────────────────────────────────────────────────────
  Widget _buildItem(Employee e) {
    final selected = _selectedIds.contains(e.id);
    final color = _avatarColor(e.name);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
      ),
      child: InkWell(
        onTap: () => setState(() {
          if (selected) {
            _selectedIds.remove(e.id);
          } else {
            _selectedIds.add(e.id!);
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(e.name),
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'رقم ق: ${e.nationalId.length > 8 ? e.nationalId.substring(0, 8) + '...' : e.nationalId}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          '${e.monthlySalary.toStringAsFixed(0)} ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: selected,
                  onChanged: (val) => setState(() {
                    if (val) {
                      _selectedIds.add(e.id!);
                    } else {
                      _selectedIds.remove(e.id);
                    }
                  }),
                  activeColor: Colors.white,
                  activeTrackColor: _primaryColor,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _selectedCount > 0 ? _onExport : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFCBD5E1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          label: Text(
            'تأكيد وإنشاء التقرير ($_selectedCount)',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        ),
      ),
    ),
  );

  void _onExport() {
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'تأكيد إنشاء التقرير',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'سيتم إنشاء كشف مرتبات لـ $_selectedCount مستفيد.\nهل تريد المتابعة؟',
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(color: const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final now = DateTime.now();
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

                final selectedEmployees = _employees
                    .where((e) => _selectedIds.contains(e.id))
                    .toList();

                for (final emp in selectedEmployees) {
                  final payment = Payment(
                    employeeId: emp.id!,
                    monthLabel: monthLabel,
                    month: now.month,
                    year: now.year,
                    amount: emp.monthlySalary,
                    received: false, // Default to pending
                    date: now.toIso8601String(),
                  );
                  await DatabaseHelper.instance.insertPayment(payment);
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم إنشاء التقرير بنجاح ✓',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      textDirection: TextDirection.rtl,
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );

                // Return to previous screen (MainScreen) after creating the report
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'تأكيد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky Delegate ────────────────────────────────────────────────────────────
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickySearchDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(_StickySearchDelegate old) => old.child != child;
}
