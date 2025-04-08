import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/quote.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/dish.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<File> generateQuotePdf({
    required Quote quote,
    required Client client,
    Event? event,
    required List<Dish> selectedDishes,
    required Map<String, double> dishQuantities,
    required Map<String, double> percentageChoices,
  }) async {
    final pdf = pw.Document();

    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(client, event),
            _buildGuestDetails(quote),
            _buildDishList(quote, selectedDishes, dishQuantities, percentageChoices),
            _buildCostSummary(quote),
            _buildTermsAndConditions(quote),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/quote_${quote.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildHeader(Client client, Event? event) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'QUOTE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Date: ${DateFormat('MMMM d, y').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  client.clientName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (client.contactPerson != null)
                  pw.Text(
                    'Contact: ${client.contactPerson}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                if (client.phone1 != null)
                  pw.Text(
                    'Phone: ${client.phone1}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                if (client.email1 != null)
                  pw.Text(
                    'Email: ${client.email1}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        if (event != null) ...[
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Event Details',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Event: ${event.eventName ?? 'Unnamed Event'}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (event.venueAddress != null)
                  pw.Text(
                    'Venue: ${event.venueAddress}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                pw.Text(
                  'Date: ${event.eventDate != null ? DateFormat('MMMM d, y').format(event.eventDate!) : 'Not specified'}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildGuestDetails(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Guest Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Count', isHeader: true),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Total Guests'),
                _buildTableCell(quote.totalGuestCount.toString()),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Male Guests'),
                _buildTableCell(quote.guestsMale.toString()),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Female Guests'),
                _buildTableCell(quote.guestsFemale.toString()),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Elderly Guests'),
                _buildTableCell(quote.guestsElderly.toString()),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Youth Guests'),
                _buildTableCell(quote.guestsYouth.toString()),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell('Child Guests'),
                _buildTableCell(quote.guestsChild.toString()),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildDishList(
    Quote quote,
    List<Dish> selectedDishes,
    Map<String, double> dishQuantities,
    Map<String, double> percentageChoices,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Selected Dishes',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            pw.TableRow(
              children: [
                _buildTableCell('Dish', isHeader: true),
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Quantity', isHeader: true),
                _buildTableCell('Base Cost', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            ...selectedDishes.map((dish) {
              final quantity = dishQuantities[dish.id] ?? 1.0;
              final percentage = percentageChoices[dish.id];
              final totalCost = percentage != null
                  ? dish.baseFoodCost * (quote.totalGuestCount * percentage / 100)
                  : dish.baseFoodCost * quantity;

              return pw.TableRow(
                children: [
                  _buildTableCell(dish.name),
                  _buildTableCell(dish.category),
                  _buildTableCell(
                    percentage != null
                        ? '${percentage.toStringAsFixed(1)}%'
                        : quantity.toStringAsFixed(1),
                  ),
                  _buildTableCell('₹${dish.baseFoodCost.toStringAsFixed(2)}'),
                  _buildTableCell('₹${totalCost.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildCostSummary(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cost Summary',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildCostRow(
                'Total Food Cost',
                quote.calculatedTotalFoodCost,
              ),
              _buildCostRow(
                'Overhead (${quote.overheadPercentage}%)',
                quote.calculatedOverheadCost,
              ),
              pw.Divider(),
              _buildCostRow(
                'Grand Total',
                quote.grandTotal,
                isTotal: true,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildTermsAndConditions(Quote quote) {
    if (quote.termsAndConditions == null) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Text(
            quote.termsAndConditions!,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
        pw.SizedBox(height: 24),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for your business!',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'For any queries, please contact us.',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static pw.Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
          ),
          pw.Text(
            '₹${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: isTotal ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
} 