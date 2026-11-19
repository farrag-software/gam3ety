import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/employee.dart';
import '../models/payment.dart';
import '../database/database_helper.dart';
import 'employee_form_screen.dart';
import 'main_screen.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final int employeeId;
  const EmployeeProfileScreen({super.key, required this.employeeId});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  static const _primaryColor = Color(0xFF136dec);

  Employee? _employee;
  List<Payment> _payments = [];
  double _totalReceived = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final emp = await DatabaseHelper.instance.getEmployee(widget.employeeId);
    final payments = await DatabaseHelper.instance.getPaymentsForEmployee(
      widget.employeeId,
    );
    final total = await DatabaseHelper.instance.totalReceivedForEmployee(
      widget.employeeId,
    );
    if (mounted) {
      setState(() {
        _employee = emp;
        _payments = payments;
        _totalReceived = total;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _employee == null
            ? _buildNotFound()
            : Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 20),
                              _buildTotalAidBanner(),
                              const SizedBox(height: 20),
                              _buildPaymentHistory(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom Nav
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomNav(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotFound() => Center(
    child: Text(
      'المستفيد غير موجود',
      style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
    ),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: const Color(0xFF475569),
            ),
            Text(
              'بيانات المستفيد',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EmployeeFormScreen(employee: _employee),
                    ),
                  );
                  if (changed == true) _loadData();
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: _primaryColor,
                ),
                tooltip: 'تعديل',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    final e = _employee!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Gradient strip + avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: -36,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: const Color(0xFFF1F5F9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials(e.name),
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Name
          Text(
            e.name,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Phone pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.call_rounded,
                  size: 16,
                  color: Color(0xFF475569),
                ),
                const SizedBox(width: 8),
                Text(
                  e.phone,
                  textDirection: TextDirection.ltr,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Info grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(child: _infoCell('الرقم القومي', e.nationalId)),
                Container(width: 1, height: 36, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _infoCell(
                    'عدد أفراد الأسرة',
                    '${e.familyMembers} أفراد',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) => Column(
    children: [
      Text(
        label,
        style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF94A3B8)),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    ],
  );

  // ── Total Aid Banner ──────────────────────────────────────────────────────
  Widget _buildTotalAidBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي المساعدات',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFBFDBFE),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${_totalReceived.toStringAsFixed(0)} ',
                          style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'ج.م',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${_payments.length} دفعة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment History ────────────────────────────────────────────────────────
  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سجل المدفوعات',
          style: GoogleFonts.cairo(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_payments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'لا توجد مدفوعات بعد',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          )
        else
          ...List.generate(
            _payments.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentItem(_payments[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentItem(Payment p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: p.received
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  p.received
                      ? Icons.check_circle_outline_rounded
                      : Icons.history_rounded,
                  size: 22,
                  color: p.received
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.monthLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.date,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.amount.toStringAsFixed(0)} ج.م',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.received
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.received ? 'تم الاستلام' : 'لم يتم الاستلام',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: p.received
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'filled': Icons.home_rounded,
        'label': 'الرئيسية',
      },
      {
        'icon': Icons.group_outlined,
        'filled': Icons.group_rounded,
        'label': 'المستفيدين',
      },
      {
        'icon': Icons.description_outlined,
        'filled': Icons.description_rounded,
        'label': 'التقارير',
      },
      {
        'icon': Icons.settings_outlined,
        'filled': Icons.settings_rounded,
        'label': 'الإعدادات',
      },
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == 1; // Profile is tied to "Employees" tab
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (i == 1) return; // already here
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainScreen(initialIndex: i),
                      ),
                      (route) => false,
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Icon(
                          selected
                              ? (item['filled'] as IconData)
                              : (item['icon'] as IconData),
                          size: 24,
                          color: selected
                              ? _primaryColor
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? _primaryColor
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1);
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}';
  }
}
