import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExporter {
  static Future<void> exportMonthReport({
    required String monthLabel,
    required List<Map<String, dynamic>> payments,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Header row
    sheet.appendRow([
      TextCellValue('م'),
      TextCellValue('الاسم'),
      TextCellValue('الرقم القومي'),
      TextCellValue('عدد الأفراد'),
      TextCellValue('المبلغ (ج.م)'),
      TextCellValue('الحالة'),
    ]);

    // Data rows
    int index = 1;
    for (final p in payments) {
      final empName = p['employee_name']?.toString() ?? 'بدون اسم';
      final nationalId = p['national_id']?.toString() ?? '-';
      final familyMembers = p['family_members']?.toString() ?? '-';
      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final received = (p['received'] as int?) == 1;

      sheet.appendRow([
        IntCellValue(index),
        TextCellValue(empName),
        TextCellValue(nationalId),
        TextCellValue(familyMembers),
        DoubleCellValue(amount),
        TextCellValue(received ? 'تم الصرف' : 'معلق'),
      ]);
      index++;
    }

    final bytes = excel.encode();
    if (bytes != null) {
      final fileName = 'تقرير_توزيعات_$monthLabel.xlsx'.replaceAll(' ', '_');
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], text: 'تقرير توزيعات - $monthLabel');
    }
  }
}
