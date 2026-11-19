import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment.dart';
import '../database/database_helper.dart';
import 'add_employees_to_month_screen.dart';

class MonthPaymentsScreen extends StatefulWidget {
  final int month;
  final int year;
  final String monthLabel;

  const MonthPaymentsScreen({
    super.key,
    required this.month,
    required this.year,
    required this.monthLabel,
  });

  @override
  State<MonthPaymentsScreen> createState() => _MonthPaymentsScreenState();
}

class _MonthPaymentsScreenState extends State<MonthPaymentsScreen> {
  static const _primaryColor = Color(0xFF136dec);
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return widget.month == now.month && widget.year == now.year;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await DatabaseHelper.instance.getPaymentsByMonth(
      widget.month,
      widget.year,
    );
    if (mounted) {
      setState(() {
        _payments = data;
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
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد بيانات لهذا الشهر',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: _payments.length,
                      itemBuilder: (ctx, i) => _buildPaymentItem(_payments[i]),
                    ),
            ),
          ],
        ),
        floatingActionButton: _isCurrentMonth
            ? FloatingActionButton.extended(
                backgroundColor: _primaryColor,
                onPressed: () async {
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddEmployeesToMonthScreen(
                        month: widget.month,
                        year: widget.year,
                        monthLabel: widget.monthLabel,
                        alreadyPaidEmployeeIds: _payments
                            .map((p) => p['employee_id'] as int)
                            .toSet(),
                      ),
                    ),
                  );
                  if (added == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'إضافة مستفيد للتقرير',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: const Color(0xFF475569),
            ),
            Expanded(
              child: Text(
                'توزيعات مستحقة - ${widget.monthLabel}',
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_isCurrentMonth)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'أرشيف للقراءة فقط',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> data) {
    final pay = Payment.fromMap(data);
    final empName = data['employee_name'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empName,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pay.amount.toStringAsFixed(0)} ج.م',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pay.received ? 'تم الصرف' : 'معلق',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: pay.received
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 6),
              if (_isCurrentMonth)
                Switch(
                  value: pay.received,
                  onChanged: (val) async {
                    final updated = pay.copyWith(received: val);
                    await DatabaseHelper.instance.updatePayment(updated);
                    _loadData(); // Refresh local list
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE2E8F0),
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                )
              else
                Icon(
                  pay.received
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: pay.received
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
