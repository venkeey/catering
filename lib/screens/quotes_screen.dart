import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/quote.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/dish.dart';
import '../widgets/quote_form.dart';
import '../services/pdf_service_simple.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  Future<void> _generateAndSharePdf(BuildContext context, Quote quote) async {
    try {
      debugPrint('QuotesScreen: Starting PDF generation for quote ID: ${quote.id}');
      final appState = Provider.of<AppState>(context, listen: false);
      
      debugPrint('QuotesScreen: Looking for client with ID: ${quote.clientId}');
      final client = appState.clients.firstWhere((c) => c.id.toString() == quote.clientId.toString());
      debugPrint('QuotesScreen: Found client: ${client.clientName}');
      
      debugPrint('QuotesScreen: Looking for event with ID: ${quote.eventId}');
      final event = quote.eventId != null
          ? appState.events.firstWhere((e) => e.id.toString() == quote.eventId.toString())
          : null;
      debugPrint('QuotesScreen: Found event: ${event?.eventName ?? 'None'}');
      
      // Get selected dishes and quantities from quote items
      debugPrint('QuotesScreen: Getting quote items for quote ID: ${quote.id}');
      final quoteItems = appState.getQuoteItemsForQuote(quote.id.toString());
      debugPrint('QuotesScreen: Found ${quoteItems.length} quote items');
      
      final selectedDishes = <Dish>[];
      final dishQuantities = <String, double>{};
      final percentageChoices = <String, double>{};
      
      for (final item in quoteItems) {
        debugPrint('QuotesScreen: Processing quote item: ${item.dishName} (ID: ${item.dishId})');
        final dish = appState.getDishForQuoteItem(item);
        if (dish != null) {
          debugPrint('QuotesScreen: Found dish: ${dish.name} (ID: ${dish.id})');
          selectedDishes.add(dish);
          if (dish.itemType == 'PercentageChoice') {
            debugPrint('QuotesScreen: Adding percentage choice: ${item.percentageTakeRate}% for dish ${dish.name}');
            percentageChoices[dish.id] = item.percentageTakeRate ?? 100.0;
          } else {
            debugPrint('QuotesScreen: Adding quantity: ${item.estimatedServings} for dish ${dish.name}');
            dishQuantities[dish.id] = item.estimatedServings?.toDouble() ?? 1.0;
          }
        } else {
          debugPrint('QuotesScreen: WARNING: Dish not found for quote item: ${item.dishName} (ID: ${item.dishId})');
        }
      }
      
      debugPrint('QuotesScreen: Selected dishes count: ${selectedDishes.length}');
      debugPrint('QuotesScreen: Dish quantities: $dishQuantities');
      debugPrint('QuotesScreen: Percentage choices: $percentageChoices');

      debugPrint('QuotesScreen: Calling PdfServiceSimple.generateQuotePdf');
      final pdfService = PdfServiceSimple.create();
      final pdfFile = await pdfService.generateQuotePdf(
        quote: quote,
        client: client,
        event: event,
        selectedDishes: selectedDishes,
        dishQuantities: dishQuantities,
        percentageChoices: percentageChoices,
      );
      debugPrint('QuotesScreen: PDF generated successfully, size: ${pdfFile.length} bytes');

      // Save the PDF to a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/quote_${quote.id}.pdf');
      await tempFile.writeAsBytes(pdfFile);
      debugPrint('QuotesScreen: PDF saved to: ${tempFile.path}');

      // Show options to share or open the PDF
      if (context.mounted) {
        debugPrint('QuotesScreen: Showing dialog with options');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quote Generated'),
            content: const Text('What would you like to do with the quote?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Share.shareXFiles(
                    [XFile(tempFile.path)],
                    subject: 'Quote for ${client.clientName}',
                  );
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFile.open(tempFile.path);
                },
                child: const Text('Open'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('QuotesScreen: Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const QuoteForm(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final quotes = appState.quotes;
          
          if (quotes.isEmpty) {
            return const Center(
              child: Text('No quotes yet. Add a new quote to get started.'),
            );
          }

          return ListView.builder(
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              final client = appState.clients.firstWhere(
                (c) => c.id.toString() == quote.clientId.toString(),
                orElse: () => Client(
                  id: quote.clientId.toString(),
                  clientName: 'Unknown Client',
                ),
              );
              final event = quote.eventId != null
                  ? appState.events.firstWhere(
                      (e) => e.id.toString() == quote.eventId.toString(),
                      orElse: () => Event(
                        id: quote.eventId!.toString(),
                        eventName: 'Unknown Event',
                        clientId: quote.clientId.toString(),
                      ),
                    )
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(client.clientName[0].toUpperCase()),
                  ),
                  title: Text(client.clientName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event != null)
                        Text(
                          'Event: ${event.eventName ?? 'Unnamed Event'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text(
                        'Date: ${DateFormat('MMM d, y').format(quote.quoteDate)}',
                      ),
                      Text(
                        'Status: ${quote.status}',
                        style: TextStyle(
                          color: _getStatusColor(quote.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Guests: ${quote.totalGuestCount} | Total: Rs. ${quote.grandTotal.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _generateAndSharePdf(context, quote),
                        tooltip: 'Generate PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => QuoteForm(quote: quote),
                          );
                        },
                        tooltip: 'Edit Quote',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Quote'),
                              content: const Text(
                                'Are you sure you want to delete this quote?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    appState.deleteQuote(quote.id.toString());
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        tooltip: 'Delete Quote',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'revised':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 