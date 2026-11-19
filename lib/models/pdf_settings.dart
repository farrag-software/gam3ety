/// Holds all tunable PDF layout parameters.
class PdfSettings {
  // ── Page layout ─────────────────────────────────────────────────────────────
  /// Rows (records) per page for the landscape (horizontal) PDF.
  final int rowsPerPageHorizontal;

  /// Rows (records) per page for the portrait (vertical) PDF.
  /// Each column gets half this number.
  final int rowsPerPageVertical;

  /// Page margin (pts) applied to all four sides.
  final double pageMargin;

  // ── Cell padding ─────────────────────────────────────────────────────────────
  /// Horizontal padding inside each table cell (pts).
  final double cellPaddingH;

  /// Vertical padding inside each table cell (pts).
  final double cellPaddingV;

  // ── Font sizes ───────────────────────────────────────────────────────────────
  /// Title / header font size (pts).
  final double headerFontSize;

  /// Column header font size (pts).
  final double columnHeaderFontSize;

  /// Body (data row) font size for the horizontal PDF (pts).
  final double bodyFontSizeHorizontal;

  /// Body (data row) font size for the vertical PDF (pts).
  final double bodyFontSizeVertical;

  const PdfSettings({
    this.rowsPerPageHorizontal = 10,
    this.rowsPerPageVertical = 30,
    this.pageMargin = 32,
    this.cellPaddingH = 4,
    this.cellPaddingV = 8,
    this.headerFontSize = 22,
    this.columnHeaderFontSize = 12,
    this.bodyFontSizeHorizontal = 11,
    this.bodyFontSizeVertical = 10,
  });

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'rowsPerPageHorizontal': rowsPerPageHorizontal,
    'rowsPerPageVertical': rowsPerPageVertical,
    'pageMargin': pageMargin,
    'cellPaddingH': cellPaddingH,
    'cellPaddingV': cellPaddingV,
    'headerFontSize': headerFontSize,
    'columnHeaderFontSize': columnHeaderFontSize,
    'bodyFontSizeHorizontal': bodyFontSizeHorizontal,
    'bodyFontSizeVertical': bodyFontSizeVertical,
  };

  factory PdfSettings.fromMap(Map<String, dynamic> m) => PdfSettings(
    rowsPerPageHorizontal:
        (m['rowsPerPageHorizontal'] as num?)?.toInt() ?? 10,
    rowsPerPageVertical:
        (m['rowsPerPageVertical'] as num?)?.toInt() ?? 30,
    pageMargin: (m['pageMargin'] as num?)?.toDouble() ?? 32,
    cellPaddingH: (m['cellPaddingH'] as num?)?.toDouble() ?? 4,
    cellPaddingV: (m['cellPaddingV'] as num?)?.toDouble() ?? 8,
    headerFontSize: (m['headerFontSize'] as num?)?.toDouble() ?? 22,
    columnHeaderFontSize:
        (m['columnHeaderFontSize'] as num?)?.toDouble() ?? 12,
    bodyFontSizeHorizontal:
        (m['bodyFontSizeHorizontal'] as num?)?.toDouble() ?? 11,
    bodyFontSizeVertical:
        (m['bodyFontSizeVertical'] as num?)?.toDouble() ?? 10,
  );

  PdfSettings copyWith({
    int? rowsPerPageHorizontal,
    int? rowsPerPageVertical,
    double? pageMargin,
    double? cellPaddingH,
    double? cellPaddingV,
    double? headerFontSize,
    double? columnHeaderFontSize,
    double? bodyFontSizeHorizontal,
    double? bodyFontSizeVertical,
  }) =>
      PdfSettings(
        rowsPerPageHorizontal:
            rowsPerPageHorizontal ?? this.rowsPerPageHorizontal,
        rowsPerPageVertical: rowsPerPageVertical ?? this.rowsPerPageVertical,
        pageMargin: pageMargin ?? this.pageMargin,
        cellPaddingH: cellPaddingH ?? this.cellPaddingH,
        cellPaddingV: cellPaddingV ?? this.cellPaddingV,
        headerFontSize: headerFontSize ?? this.headerFontSize,
        columnHeaderFontSize: columnHeaderFontSize ?? this.columnHeaderFontSize,
        bodyFontSizeHorizontal:
            bodyFontSizeHorizontal ?? this.bodyFontSizeHorizontal,
        bodyFontSizeVertical: bodyFontSizeVertical ?? this.bodyFontSizeVertical,
      );

  static const defaults = PdfSettings();
}
