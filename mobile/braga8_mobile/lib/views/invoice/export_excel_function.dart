import 'package:excel/excel.dart';
import 'package:flutter/material.dart' hide BorderStyle, Border;
import 'package:intl/intl.dart';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/data/models/invoice_detail_model.dart';
import 'package:braga8_mobile/utilities/file_saver.dart';

// ---------------------------------------------------------------------------
// STANDALONE EXCEL EXPORT
// Call this from your screen:
//
//   ElevatedButton(
//     onPressed: () => exportInvoiceExcel(
//       context: context,
//       api: widget.api,
//       invoice: widget.invoice,
//       items: payload.items,   // List<InvoiceItem> from fetchInvoiceDetail
//     ),
//     child: Text('Export Excel'),
//   )
// ---------------------------------------------------------------------------

// ── Formatters ───────────────────────────────────────────────────────────────

String _rupiah(double amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(amount);

String _fmtDate(DateTime d) => DateFormat('dd MMMM yyyy', 'id_ID').format(d);

// ── Snackbar helper (needs a BuildContext) ───────────────────────────────────

void _showSnack(BuildContext context, String msg, IconData icon, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// ── Save + share helper ───────────────────────────────────────────────────────
// Writes bytes to the temp directory then calls share_plus.
// Works on Android & iOS. For web you'd need a different approach.

// ── Main export function ──────────────────────────────────────────────────────

Future<void> exportInvoiceExcel({
  required BuildContext context,
  required ApiService api,
  required Invoice invoice,
  required List<InvoiceItem> items,
}) async {
  // ── Colour constants ──────────────────────────────────────────────────────
  const String kBlack = '#1A1A1A';
  const String kOrange = '#B8864E';
  const String kOrangeLight = '#FFF3E8';
  const String kWhite = '#FFFFFF';
  const String kDarkText = '#1A1A1A';
  const String kGreyText = '#555555';
  const String kBorderClr = '#000000';

  // ── Style factories ───────────────────────────────────────────────────────

  CellStyle headerStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    bold: true,
    fontSize: 14,
    backgroundColorHex: ExcelColor.fromHexString(kBlack),
    fontColorHex: ExcelColor.fromHexString(kWhite),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    leftBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle metaLabelStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    bold: true,
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString(kDarkText),
    backgroundColorHex: ExcelColor.fromHexString(kOrangeLight),
    leftBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle metaValueStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString(kGreyText),
    leftBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle colHeaderStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    bold: true,
    fontSize: 11,
    backgroundColorHex: ExcelColor.fromHexString(kOrange),
    fontColorHex: ExcelColor.fromHexString(kWhite),
    horizontalAlign: HorizontalAlign.Center,
    leftBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle itemStyle({required bool alternate}) => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString(kDarkText),
    backgroundColorHex: ExcelColor.fromHexString(
      alternate ? kOrangeLight : kWhite,
    ),
    leftBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle itemAmountStyle({required bool alternate}) => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    fontSize: 10,
    fontColorHex: ExcelColor.fromHexString(kDarkText),
    backgroundColorHex: ExcelColor.fromHexString(
      alternate ? kOrangeLight : kWhite,
    ),
    numberFormat: NumFormat.custom(formatCode: '#,##0'),
    horizontalAlign: HorizontalAlign.Right,
    leftBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle totalLabelStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    bold: true,
    fontSize: 11,
    backgroundColorHex: ExcelColor.fromHexString(kOrange),
    fontColorHex: ExcelColor.fromHexString(kWhite),
    leftBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  CellStyle totalAmountStyle() => CellStyle(
    fontFamily: getFontFamily(FontFamily.Arial),
    bold: true,
    fontSize: 11,
    backgroundColorHex: ExcelColor.fromHexString(kOrange),
    fontColorHex: ExcelColor.fromHexString(kWhite),
    numberFormat: NumFormat.custom(formatCode: '"Rp "#,##0'),
    horizontalAlign: HorizontalAlign.Right,
    leftBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    rightBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    topBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
    bottomBorder: Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString(kBorderClr),
    ),
  );

  // ── Build workbook ────────────────────────────────────────────────────────
  try {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // remove default blank sheet
    final Sheet sheet = excel['Invoice'];

    // helper: write one meta row (label col A, value col B)
    void metaRow(int rowIdx, String label, String value) {
      final lCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      );
      lCell.value = TextCellValue(label);
      lCell.cellStyle = metaLabelStyle();

      final vCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
      );
      vCell.value = TextCellValue(value);
      vCell.cellStyle = metaValueStyle();
    }

    final String tenantName = api.currentTenant?.name ?? '-';

    // Row 0 — company header, merged A1:B1
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0),
    );
    final companyCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    companyCell.value = TextCellValue('PT Eight Property Indonesia');
    companyCell.cellStyle = headerStyle();
    sheet.setRowHeight(0, 28);

    // Row 1 — blank spacer (skip)

    // Rows 2–6 — meta block
    metaRow(2, 'Invoice', invoice.invoiceNumber);
    metaRow(3, 'Tenant', tenantName);
    metaRow(4, 'Unit', invoice.unitNumber);
    metaRow(
      5,
      'Periode',
      '${_fmtDate(invoice.billingPeriodStart)} – ${_fmtDate(invoice.billingPeriodEnd)}',
    );
    metaRow(6, 'Status', invoice.isPaid ? 'LUNAS ✓' : 'BELUM LUNAS');

    // Row 7 — blank spacer (skip)

    // Row 8 — column headers
    final hKomp = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8),
    );
    hKomp.value = TextCellValue('Komponen');
    hKomp.cellStyle = colHeaderStyle();

    final hJuml = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8),
    );
    hJuml.value = TextCellValue('Jumlah (Rp)');
    hJuml.cellStyle = colHeaderStyle();

    // Rows 9+ — item rows
    for (int i = 0; i < items.length; i++) {
      final rowIdx = 9 + i;
      final alt = i.isOdd;

      final descCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
      );
      descCell.value = TextCellValue(items[i].description);
      descCell.cellStyle = itemStyle(alternate: alt);

      final amtCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
      );
      amtCell.value = DoubleCellValue(items[i].amount);
      amtCell.cellStyle = itemAmountStyle(alternate: alt);
    }

    // Total row — SUM formula so it recalculates if edited in Excel
    final totalRowIdx = 9 + items.length;
    // Excel row numbers are 1-based; index 9 = Excel row 10
    const int firstExcelRow = 10;
    final int lastExcelRow = 9 + items.length; // same as totalRowIdx (1-based)

    final totalLabelCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIdx),
    );
    totalLabelCell.value = TextCellValue('TOTAL');
    totalLabelCell.cellStyle = totalLabelStyle();

    final totalAmtCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: totalRowIdx),
    );
    totalAmtCell.value = FormulaCellValue(
      'SUM(B$firstExcelRow:B$lastExcelRow)',
    );
    totalAmtCell.cellStyle = totalAmountStyle();

    // Column widths
    sheet.setColumnWidth(0, 44);
    sheet.setColumnWidth(1, 22);

    // Encode
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal menghasilkan file Excel');

    final filename = '${invoice.invoiceNumber}.xlsx';
    await saveAndShareFile(bytes, filename);

    if (!context.mounted) return;
    _showSnack(
      context,
      '$filename berhasil diekspor',
      Icons.check_circle_outline,
      Colors.green,
    );
  } catch (e) {
    if (!context.mounted) return;
    _showSnack(
      context,
      'Gagal ekspor: $e',
      Icons.error_outline,
      Colors.redAccent,
    );
  }
}
