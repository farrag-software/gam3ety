import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/search_field.dart';
import '../database/database_helper.dart';
import '../models/employee.dart';
import 'employee_profile_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  EmployeeListScreenState createState() => EmployeeListScreenState();
}

class EmployeeListScreenState extends State<EmployeeListScreen> {
  final _searchCtrl = TextEditingController();
  List<Employee> _employees = [];
  List<Employee> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Called externally from MainScreen after adding an employee.
  Future<void> loadData() => _loadData();

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final list = await DatabaseHelper.instance.getAllEmployees();
    if (mounted) {
      setState(() {
        _employees = list;
        _filtered = list;
        _loading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _employees
          : _employees
              .where(
                (e) =>
                    e.name.toLowerCase().contains(q) ||
                    e.nationalId.contains(q) ||
                    e.phone.contains(q),
              )
              .toList();
    });
  }

  Color _avatarColor(String name) {
    return AppColors.avatarColors[name.codeUnitAt(0) % AppColors.avatarColors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // ── Search & Header bar (Apple HIG Glassy surface) ───────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المستفيدون',
                      style: tt.headlineMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_employees.length} مستفيد',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SearchField(
                  controller: _searchCtrl,
                  hintText: 'بحث بالاسم أو الرقم القومي أو الهاتف...',
                  onChanged: (_) => _onSearch(),
                ),
              ],
            ),
          ),

          // ── List ───────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: cs.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildEmployeeCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearch = _searchCtrl.text.isNotEmpty;
    return EmptyState(
      icon: isSearch ? Icons.search_off_rounded : Icons.group_outlined,
      title: isSearch ? 'لا توجد نتائج مطابقة' : 'لا يوجد مستفيدون بعد',
      subtitle: isSearch ? 'جرب البحث بكلمات أخرى' : 'اضغط على زر + في الأسفل لإضافة أول مستفيد',
    );
  }

  Widget _buildEmployeeCard(Employee e) {
    final color = _avatarColor(e.name);
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
              builder: (_) => EmployeeProfileScreen(employeeId: e.id!),
            ),
          );
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(e.name),
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      style: tt.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: cs.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          e.nationalId.length > 8
                              ? '${e.nationalId.substring(0, 8)}...'
                              : e.nationalId,
                          style: tt.labelSmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.family_restroom_rounded,
                          size: 13,
                          color: cs.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.familyMembers} أفراد',
                          style: tt.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Salary chip + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${e.monthlySalary.toStringAsFixed(0)} ج.م',
                    style: tt.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: cs.outline,
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
