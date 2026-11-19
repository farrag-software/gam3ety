import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/employee.dart';
import '../models/payment.dart';
import '../database/database_helper.dart';

class AddEmployeesToMonthScreen extends StatefulWidget {
  final int month;
  final int year;
  final String monthLabel;
  final Set<int> alreadyPaidEmployeeIds;

  const AddEmployeesToMonthScreen({
    super.key,
    required this.month,
    required this.year,
    required this.monthLabel,
    required this.alreadyPaidEmployeeIds,
  });

  @override
  State<AddEmployeesToMonthScreen> createState() =>
      _AddEmployeesToMonthScreenState();
}

class _AddEmployeesToMonthScreenState extends State<AddEmployeesToMonthScreen> {
  static const _primaryColor = Color(0xFF136dec);

  final _searchController = TextEditingController();
  List<Employee> _employees = [];
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
    final allEmployees = await DatabaseHelper.instance.getAllEmployees();

    // Filter out employees who already have a payment for this month
    final availableEmployees = allEmployees
        .where((e) => !widget.alreadyPaidEmployeeIds.contains(e.id))
        .toList();

    if (mounted) {
      setState(() {
        _employees = availableEmployees;
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
                        SliverToBoxAdapter(child: _buildSearchBox()),
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
                                  'المستفيدين المتاحين (${filtered.length})',
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
                                          Icons.check_circle_outline_rounded,
                                          size: 48,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا يوجد مستفيدين لإضافتهم',
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
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            color: const Color(0xFF475569),
          ),
          Expanded(
            child: Text(
              'إضافة للتقرير (${widget.monthLabel})',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSearchBox() => Padding(
    padding: const EdgeInsets.all(16),
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث عن مستفيد...',
          hintStyle: GoogleFonts.cairo(
            color: const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    ),
  );

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
                    Text(
                      '${e.monthlySalary.toStringAsFixed(0)} ج.م',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
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
          onPressed: _selectedCount > 0 ? _onAdd : null,
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
            'تأكيد الإضافة ($_selectedCount)',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        ),
      ),
    ),
  );

  void _onAdd() async {
    final selectedEmployees = _employees
        .where((e) => _selectedIds.contains(e.id))
        .toList();

    for (final emp in selectedEmployees) {
      final payment = Payment(
        employeeId: emp.id!,
        monthLabel: widget.monthLabel,
        month: widget.month,
        year: widget.year,
        amount: emp.monthlySalary,
        received: false,
        date: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.insertPayment(payment);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تمت الإضافة للتقرير بنجاح ✓',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.of(context).pop(true);
  }
}
