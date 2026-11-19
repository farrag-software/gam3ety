import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pdf_settings.dart';
import 'web_downloader_io.dart'
    if (dart.library.html) 'web_downloader_web.dart';

class PdfExporter {
  // ── Font loading ───────────────────────────────────────────────────────────

  /// Loads Cairo font from bundled assets (works offline on all platforms).
  /// Falls back to PdfGoogleFonts (network) and then Helvetica as last resort.
  static Future<pw.Font> _cairo({bool bold = false}) async {
    // 1. Try bundled asset first (always available, no network needed)
    try {
      final data = await rootBundle.load(
        bold ? 'assets/fonts/Cairo-Bold.ttf' : 'assets/fonts/Cairo-Regular.ttf',
      );
      return pw.Font.ttf(data);
    } catch (_) {}

    // 2. Fallback: download from Google Fonts CDN
    try {
      return bold
          ? await PdfGoogleFonts.cairoBold()
          : await PdfGoogleFonts.cairoRegular();
    } catch (_) {}

    // 3. Last resort: built-in Helvetica (no Arabic support, but avoids crash)
    return bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

  // ── Main export ────────────────────────────────────────────────────────────

  static Future<void> exportMonthReport({
    required String monthLabel,
    required List<Map<String, dynamic>> payments,
    PdfSettings settings = const PdfSettings(),
  }) async {
    final regular = await _cairo();
    final bold = await _cairo(bold: true);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginLeft: settings.pageMargin,
          marginRight: settings.pageMargin,
          marginTop: settings.pageMargin,
          marginBottom: settings.pageMargin,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Center(
            child: pw.Text(
              'كشف توزيعات (أفقي) - $monthLabel',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: bold,
                fontSize: settings.headerFontSize,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: regular,
              fontSize: 9,
              color: PdfColors.grey,
            ),
          ),
        ),
        build: (_) {
          final int perPage = settings.rowsPerPageHorizontal;
          final List<pw.Widget> widgets = [];

          for (int i = 0; i < payments.length; i += perPage) {
            final end = (i + perPage < payments.length)
                ? i + perPage
                : payments.length;
            final chunk = payments.sublist(i, end);

            widgets.add(
              _buildTable(
                chunk,
                startIndex: i,
                regular: regular,
                bold: bold,
                settings: settings,
              ),
            );

            if (end < payments.length) widgets.add(pw.NewPage());
          }

          return widgets;
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final name = 'تقرير_توزيعات_أفقي_$monthLabel.pdf'.replaceAll(' ', '_');

    await _deliver(bytes, name, monthLabel);
  }

  static Future<void> exportVerticalMonthReport({
    required String monthLabel,
    required List<Map<String, dynamic>> payments,
    PdfSettings settings = const PdfSettings(),
  }) async {
    final regular = await _cairo();
    final bold = await _cairo(bold: true);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          // Portrait
          marginLeft: settings.pageMargin,
          marginRight: settings.pageMargin,
          marginTop: settings.pageMargin,
          marginBottom: settings.pageMargin,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Center(
            child: pw.Text(
              'كشف توزيعات (رأسي) - $monthLabel',
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(
                font: bold,
                fontSize: settings.headerFontSize,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              font: regular,
              fontSize: 9,
              color: PdfColors.grey,
            ),
          ),
        ),
        build: (_) {
          final int perPage = settings.rowsPerPageVertical;
          final List<pw.Widget> widgets = [];

          for (int i = 0; i < payments.length; i += perPage) {
            final end = (i + perPage < payments.length)
                ? i + perPage
                : payments.length;
            final chunk = payments.sublist(i, end);

            // Split chunk into two halves for the two side-by-side tables
            final half = (chunk.length / 2).ceil();
            final firstHalf = chunk.sublist(0, half);
            final secondHalf = chunk.sublist(half, chunk.length);

            widgets.add(
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Right table (first half of data because RTL)
                  pw.Expanded(
                    child: _buildVerticalTable(
                      firstHalf,
                      startIndex: i,
                      regular: regular,
                      bold: bold,
                      settings: settings,
                    ),
                  ),
                  if (secondHalf.isNotEmpty) ...[
                    pw.SizedBox(width: 24), // Gap between tables
                    // Left table (second half of data)
                    pw.Expanded(
                      child: _buildVerticalTable(
                        secondHalf,
                        startIndex: i + half,
                        regular: regular,
                        bold: bold,
                        settings: settings,
                      ),
                    ),
                  ] else ...[
                    pw.SizedBox(width: 24),
                    pw.Expanded(
                      child: pw.SizedBox(),
                    ), // Empty space if no second half
                  ],
                ],
              ),
            );

            if (end < payments.length) widgets.add(pw.NewPage());
          }

          return widgets;
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final name = 'تقرير_توزيعات_رأسي_$monthLabel.pdf'.replaceAll(' ', '_');

    await _deliver(bytes, name, monthLabel);
  }

  // ── Custom RTL table ───────────────────────────────────────────────────────

  static pw.Widget _buildVerticalTable(
    List<Map<String, dynamic>> rows, {
    required int startIndex,
    required pw.Font regular,
    required pw.Font bold,
    required PdfSettings settings,
  }) {
    // Physical (left → right) due to RTL table quirks in pdf package:
    // التوقيع | المبلغ | الاسم | م
    final columns = [
      ('التوقيع', 3), // leftmost physically
      ('المبلغ (ج.م)', 3),
      ('الاسم', 6),
      ('م', 2), // rightmost physically
    ];

    pw.Widget cell(
      String text, {
      bool isHeader = false,
      PdfColor? bg,
      PdfColor? fg,
    }) {
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.symmetric(
          horizontal: settings.cellPaddingH,
          vertical: settings.cellPaddingV,
        ),
        color: bg,
        child: pw.Text(
          text,
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: isHeader ? bold : regular,
            fontSize: isHeader
                ? settings.columnHeaderFontSize
                : settings.bodyFontSizeVertical,
            color: fg ?? PdfColors.black,
          ),
        ),
      );
    }

    pw.TableRow headerRow() => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      children: columns.map((c) => cell(c.$1, isHeader: true)).toList(),
    );

    pw.TableRow dataRow(int i) {
      final p = rows[i];
      final name = p['employee_name']?.toString() ?? '-';
      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final bg = i.isOdd ? PdfColors.grey100 : PdfColors.white;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          cell('', bg: bg), // التوقيع
          cell(amount.toStringAsFixed(0), bg: bg), // المبلغ
          cell(name, bg: bg), // الاسم
          cell('${startIndex + i + 1}', bg: bg), // م
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        for (int i = 0; i < columns.length; i++)
          i: pw.FlexColumnWidth(columns[i].$2.toDouble()),
      },
      children: [headerRow(), for (int i = 0; i < rows.length; i++) dataRow(i)],
    );
  }

  static pw.Widget _buildTable(
    List<Map<String, dynamic>> rows, {
    required int startIndex,
    required pw.Font regular,
    required pw.Font bold,
    required PdfSettings settings,
  }) {
    // pw.Table always renders column[0] on the physical LEFT.
    // For Arabic RTL: م must be on the physical RIGHT.
    // So array order = leftmost→rightmost = الحالة→م
    //
    // Physical (left → right):
    //   الحالة | المبلغ | عدد الأفراد | الرقم القومي | رقم الهاتف | التوقيع | الاسم | م
    final columns = [
      ('الحالة', 2), // leftmost  (physically left)
      ('المبلغ (ج.م)', 2),
      ('عدد الأفراد', 2),
      ('الرقم القومي', 3),
      ('رقم الهاتف', 3),
      ('التوقيع', 3), // empty — for manual signature
      ('الاسم', 4),
      ('م', 1), // rightmost (physically right)
    ];

    pw.Widget cell(
      String text, {
      bool isHeader = false,
      PdfColor? bg,
      PdfColor? fg,
    }) {
      // All cells centered
      return pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.symmetric(
          horizontal: settings.cellPaddingH,
          vertical: settings.cellPaddingV,
        ),
        color: bg,
        child: pw.Text(
          text,
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: isHeader ? bold : regular,
            fontSize: isHeader
                ? settings.columnHeaderFontSize
                : settings.bodyFontSizeHorizontal,
            color: fg ?? PdfColors.black,
          ),
        ),
      );
    }

    pw.TableRow headerRow() => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      children: columns.map((c) => cell(c.$1, isHeader: true)).toList(),
    );

    pw.TableRow dataRow(int i) {
      final p = rows[i];
      final name = p['employee_name']?.toString() ?? '-';
      final phone = p['phone']?.toString() ?? '-';
      final nid = p['national_id']?.toString() ?? '-';
      final fam = p['family_members']?.toString() ?? '-';
      final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
      final received = (p['received'] as int?) == 1;

      final bg = i.isOdd ? PdfColors.grey100 : PdfColors.white;
      final statusColor = received ? PdfColors.green700 : PdfColors.orange700;

      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          cell(
            received ? 'تم الصرف' : 'معلق',
            bg: bg,
            fg: statusColor,
          ), // الحالة
          cell(amount.toStringAsFixed(0), bg: bg), // المبلغ
          cell(fam, bg: bg), // عدد الأفراد
          cell(nid, bg: bg), // الرقم القومي
          cell(phone, bg: bg), // رقم الهاتف
          cell('', bg: bg), // التوقيع (empty)
          cell(name, bg: bg), // الاسم
          cell('${startIndex + i + 1}', bg: bg), // م
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        for (int i = 0; i < columns.length; i++)
          i: pw.FlexColumnWidth(columns[i].$2.toDouble()),
      },
      children: [headerRow(), for (int i = 0; i < rows.length; i++) dataRow(i)],
    );
  }

  // ── Delivery ───────────────────────────────────────────────────────────────

  static Future<void> _deliver(
    Uint8List bytes,
    String name,
    String label,
  ) async {
    if (kIsWeb) {
      // Direct browser download – saves the PDF file to the Downloads folder
      WebDownloader.download(bytes, name);
    } else {
      await Share.shareXFiles([
        XFile.fromData(bytes, name: name, mimeType: 'application/pdf'),
      ], text: 'تقرير توزيعات - $label');
    }
  }
}
