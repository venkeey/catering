import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/quote.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/dish.dart';
import 'package:intl/intl.dart';
import '../utils/file_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

/// A simplified PDF service that doesn't rely on custom fonts
/// This avoids the issues with loading TTF files
class PdfServiceSimple {
  static Future<void> generateAndShareQuote(Quote quote, List<Dish> selectedDishes) async {
    debugPrint('Starting PDF generation for quote: ${quote.id}');
    debugPrint('Number of items in quote: ${quote.items.length}');
    debugPrint('Number of selected dishes: ${selectedDishes.length}');

    // Create PDF document
    final pdf = pw.Document();

    // Add page to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(quote.clientId.toString(), quote.eventId?.toString()),
            _buildQuoteDetails(quote),
            _buildItemsTable(
              quote,
              selectedDishes,
              Map<String, double>.fromEntries(
                quote.items.map((item) => MapEntry(item.dishId.toString(), item.quantity))
              ),
              Map<String, double>.fromEntries(
                quote.items.where((item) => item.percentageTakeRate != null)
                    .map((item) => MapEntry(item.dishId.toString(), item.percentageTakeRate!))
              ),
            ),
            _buildTotals(quote),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/quote_${quote.id}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Quote ${quote.id}',
    );
  }

  static Future<Uint8List> generateQuotePdf({
    required Quote quote,
    required Client client,
    Event? event,
    required List<Dish> selectedDishes,
    required Map<String, double> dishQuantities,
    required Map<String, double> percentageChoices,
  }) async {
    debugPrint('PdfServiceSimple: Starting PDF generation for quote: ${quote.id}');
    debugPrint('PdfServiceSimple: Number of items in quote: ${quote.items.length}');
    debugPrint('PdfServiceSimple: Number of selected dishes: ${selectedDishes.length}');
    debugPrint('PdfServiceSimple: Dish quantities: $dishQuantities');
    debugPrint('PdfServiceSimple: Percentage choices: $percentageChoices');
    
    // Create a new PDF document
    final pdf = pw.Document();
    
    // Add a page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (pw.Context context) {
          debugPrint('PdfServiceSimple: Building PDF content');
          return [
            _buildHeader(client.clientName, event?.eventName),
            _buildQuoteDetails(quote),
            _buildItemsTable(quote, selectedDishes, dishQuantities, percentageChoices),
            _buildTotals(quote),
            _buildFooter(),
          ];
        },
      ),
    );
    
    // Save the PDF to a Uint8List
    final pdfBytes = await pdf.save();
    debugPrint('PdfServiceSimple: PDF generated successfully with ${pdfBytes.length} bytes');
    return pdfBytes;
  }

  static pw.Widget _buildHeader(String? clientName, String? eventName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CATERERER',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Quote',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 18,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Client:',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    clientName ?? 'Not specified',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Event:',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    eventName ?? 'Not specified',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQuoteDetails(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Quote Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Quote Date:', DateFormat('yyyy-MM-dd').format(quote.quoteDate)),
                  _buildDetailRow('Guest Count:', quote.totalGuestCount.toString()),
                  _buildDetailRow('Calculation Method:', quote.calculationMethod),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Status:', quote.status),
                  _buildDetailRow('Overhead %:', '${quote.overheadPercentage.toStringAsFixed(1)}%'),
                  _buildDetailRow('Notes:', quote.notes ?? 'None'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    Quote quote,
    List<Dish> selectedDishes,
    Map<String, double> dishQuantities,
    Map<String, double> percentageChoices,
  ) {
    debugPrint('PdfServiceSimple: Building items table');
    debugPrint('PdfServiceSimple: Selected dishes count: ${selectedDishes.length}');
    debugPrint('PdfServiceSimple: Dish quantities: $dishQuantities');
    debugPrint('PdfServiceSimple: Percentage choices: $percentageChoices');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Menu Items',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell('Item', isHeader: true),
                  _buildTableCell('Qty', isHeader: true),
                  _buildTableCell('Price', isHeader: true),
                  _buildTableCell('Total', isHeader: true),
                ],
              ),
              ...selectedDishes.map((dish) {
                debugPrint('PdfServiceSimple: Processing dish: ${dish.name} (ID: ${dish.id})');
                final quantity = dishQuantities[dish.id] ?? 0;
                final percentage = percentageChoices[dish.id] ?? 0.0;
                final totalCost = dish.basePrice * quantity * (percentage / 100);
                
                debugPrint('PdfServiceSimple: Dish ${dish.name} - Quantity: $quantity, Percentage: $percentage, Total Cost: $totalCost');
                
                return pw.TableRow(
                  children: [
                    _buildTableCell(dish.name),
                    _buildTableCell('$quantity'),
                    _buildTableCell('Rs. ${_formatIndianNumber(dish.basePrice.round())}'),
                    _buildTableCell('Rs. ${_formatIndianNumber(totalCost.round())}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotals(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal:', 'Rs. ${_formatIndianNumber(quote.calculatedTotalFoodCost.round())}'),
          _buildTotalRow('Overhead (${quote.overheadPercentage.round()}%):', 'Rs. ${_formatIndianNumber(quote.calculatedOverheadCost.round())}'),
          pw.Divider(color: PdfColors.grey300),
          _buildTotalRow('Grand Total:', 'Rs. ${_formatIndianNumber(quote.grandTotal.round())}', isTotal: true),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColors.blue900 : PdfColors.grey700,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: pw.FontWeight.bold,
              color: isTotal ? PdfColors.blue900 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for choosing Catererer',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'For any questions or clarifications, please contact us',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build table cells
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  // Helper method to format numbers in Indian format (with commas)
  static String _formatIndianNumber(int number) {
    String numStr = number.toString();
    int len = numStr.length;
    String result = '';
    
    // Handle the last 3 digits (hundreds, tens, ones)
    if (len > 3) {
      result = numStr.substring(len - 3);
      numStr = numStr.substring(0, len - 3);
      len = numStr.length;
    } else {
      return numStr;
    }
    
    // Add commas for thousands and lakhs
    while (len > 2) {
      result = numStr.substring(len - 2) + ',' + result;
      numStr = numStr.substring(0, len - 2);
      len = numStr.length;
    }
    
    // Add the remaining digits
    if (len > 0) {
      result = numStr + ',' + result;
    }
    
    return result;
  }
}