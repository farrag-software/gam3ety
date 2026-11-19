import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/widgets/glass_card.dart';
import '../core/widgets/glass_dialog.dart';
import '../database/database_helper.dart';
import '../models/employee.dart';

class EmployeeFormScreen extends StatefulWidget {
  /// Pass an existing employee to edit, or null to add a new one.
  final Employee? employee;
  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _familyMembers = 1;
  bool _saving = false;

  // Signature
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.employee!;
      _nameCtrl.text = e.name;
      _nationalIdCtrl.text = e.nationalId;
      _phoneCtrl.text = e.phone;
      _salaryCtrl.text = e.monthlySalary.toStringAsFixed(0);
      _notesCtrl.text = e.notes;
      _familyMembers = e.familyMembers;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      final employee = Employee(
        id: widget.employee?.id,
        name: _nameCtrl.text.trim(),
        nationalId: _nationalIdCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        familyMembers: _familyMembers,
        monthlySalary: double.tryParse(_salaryCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim(),
        createdAt: widget.employee?.createdAt ?? now,
      );

      if (_isEdit) {
        await DatabaseHelper.instance.updateEmployee(employee);
      } else {
        await DatabaseHelper.instance.insertEmployee(employee);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'تم تحديث البيانات بنجاح ✓' : 'تم حفظ البيانات بنجاح ✓',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: GoogleFonts.cairo(color: Colors.white),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('البيانات الشخصية'),
                      const SizedBox(height: 12),
                      _buildNameField(),
                      const SizedBox(height: 14),
                      _buildNationalIdField(),
                      const SizedBox(height: 24),

                      _sectionLabel('بيانات الاتصال والأسرة'),
                      const SizedBox(height: 12),
                      _buildPhoneField(),
                      const SizedBox(height: 14),
                      _buildFamilyStepper(),
                      const SizedBox(height: 14),
                      _buildSalaryField(),
                      const SizedBox(height: 24),

                      _sectionLabel('ملاحظات إضافية'),
                      const SizedBox(height: 12),
                      _buildNotesField(),
                      const SizedBox(height: 24),

                      _sectionLabel('توقيع المستفيد'),
                      const SizedBox(height: 12),
                      _buildSignaturePad(),
                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          'أقر أن جميع البيانات المذكورة أعلاه صحيحة',
                          style: tt.labelSmall,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky save button
              _buildSaveButton(context),
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

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
              color: cs.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isEdit ? 'تعديل بيانات مستفيد' : 'إضافة مستفيد جديد',
                style: tt.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            if (_isEdit)
              IconButton(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                color: cs.error,
                tooltip: 'حذف المستفيد',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.selectionClick();
    final passCtrl = TextEditingController();
    bool obscure = true;

    final shouldDelete = await showGlassDialog(
      context,
      title: 'حذف مستفيد',
      message: 'هل أنت متأكد من رغبتك في حذف هذا المستفيد؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
      iconColor: Theme.of(context).colorScheme.error,
    );

    if (shouldDelete == true && widget.employee?.id != null) {
      setState(() => _saving = true);
      try {
        await DatabaseHelper.instance.deleteEmployee(widget.employee!.id!);
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حذف المستفيد بنجاح ✓',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e', style: GoogleFonts.cairo(color: Colors.white)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Widget _sectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text(
      text,
      style: tt.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.primary,
      ),
    );
  }

  // ── Fields ─────────────────────────────────────────────────────────────────
  Widget _buildNameField() => _inputCard(
    label: 'الاسم بالكامل',
    child: TextFormField(
      controller: _nameCtrl,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.cairo(fontSize: 14),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
      decoration: _inputDeco(
        hint: 'محمد أحمد إبراهيم',
        icon: Icons.person_outline_rounded,
      ),
    ),
  );

  Widget _buildNationalIdField() => _inputCard(
    label: 'الرقم القومي',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nationalIdCtrl,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.number,
          maxLength: 14,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(fontSize: 14, letterSpacing: 1.5),
          validator: (v) {
            if (v == null || v.trim().length != 14) {
              return 'يجب أن يكون 14 رقماً';
            }
            return null;
          },
          decoration: _inputDeco(
            hint: '29012345678901',
            icon: Icons.badge_outlined,
            counter: false,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'يجب أن يتكون من 14 رقماً',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    ),
  );

  Widget _buildPhoneField() => _inputCard(
    label: 'رقم الهاتف',
    child: TextFormField(
      controller: _phoneCtrl,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.phone,
      style: GoogleFonts.inter(fontSize: 14),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم الهاتف' : null,
      decoration: _inputDeco(hint: '010xxxxxxxx', icon: Icons.phone_outlined),
    ),
  );

  Widget _buildFamilyStepper() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _inputCard(
      label: 'عدد أفراد الأسرة',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stepperBtn(Icons.remove_rounded, () {
              if (_familyMembers > 1) {
                HapticFeedback.selectionClick();
                setState(() => _familyMembers--);
              }
            }),
            Text(
              '$_familyMembers',
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            _stepperBtn(Icons.add_rounded, () {
              if (_familyMembers < 20) {
                HapticFeedback.selectionClick();
                setState(() => _familyMembers++);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: cs.primary),
      ),
    );
  }

  Widget _buildSalaryField() => _inputCard(
    label: 'الراتب الشهري المستحق',
    child: TextFormField(
      controller: _salaryCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      style: GoogleFonts.inter(fontSize: 14),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الراتب' : null,
      decoration: _inputDeco(
        hint: '500',
        icon: Icons.payments_outlined,
        suffix: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'ج.م',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildNotesField() => _inputCard(
    label: 'ملاحظات إضافية',
    child: TextFormField(
      controller: _notesCtrl,
      textDirection: TextDirection.rtl,
      maxLines: 3,
      style: GoogleFonts.cairo(fontSize: 13),
      decoration: _inputDeco(
        hint: 'اكتب أي ملاحظات هامة عن الحالة الاجتماعية أو الصحية...',
        icon: Icons.description_outlined,
      ),
    ),
  );

  // ── Signature Pad ─────────────────────────────────────────────────────────
  Widget _buildSignaturePad() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _inputCard(
      label: 'التوقيع الرقمي',
      trailing: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _strokes.clear();
            _currentStroke = [];
          });
        },
        child: Text(
          'مسح التوقيع',
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
      ),
      child: GestureDetector(
        onPanStart: (d) => setState(() => _currentStroke = [d.localPosition]),
        onPanUpdate: (d) => setState(() => _currentStroke = [..._currentStroke, d.localPosition]),
        onPanEnd: (_) => setState(() {
          _strokes.add(List.from(_currentStroke));
          _currentStroke = [];
        }),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141721) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _SignaturePainter(
              strokes: _strokes,
              current: _currentStroke,
              strokeColor: cs.primary,
            ),
            child: _strokes.isEmpty && _currentStroke.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw_outlined, size: 30, color: cs.outline),
                        const SizedBox(height: 8),
                        Text('قم بالتوقيع هنا باللمس', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Save Button (Apple HIG Sticky CTA) ──────────────────────────────────────
  Widget _buildSaveButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 20),
          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ البيانات'),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _inputCard({
    required String label,
    required Widget child,
    Widget? trailing,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13),
          ),
          if (trailing != null) trailing,
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
    bool counter = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: cs.outline),
      suffixIcon: suffix,
      counterText: counter ? null : '',
    );
  }
}

// ── Signature Painter ─────────────────────────────────────────────────────────
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color strokeColor;

  const _SignaturePainter({
    required this.strokes,
    required this.current,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (current.isNotEmpty) {
      _drawStroke(canvas, current, paint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SignaturePainter old) =>
      old.strokes != strokes || old.current != current || old.strokeColor != strokeColor;
}
