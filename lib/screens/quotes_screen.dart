import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/quote.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/dish.dart';
import '../widgets/quote_form.dart';
import '../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  Future<void> _generateAndSharePdf(BuildContext context, Quote quote) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final client = appState.clients.firstWhere((c) => c.id == quote.clientId);
      final event = quote.eventId != null
          ? appState.events.firstWhere((e) => e.id == quote.eventId)
          : null;
      
      // TODO: Get selected dishes and quantities from quote items
      final selectedDishes = <Dish>[];
      final dishQuantities = <String, double>{};
      final percentageChoices = <String, double>{};

      final pdfFile = await PdfService.generateQuotePdf(
        quote: quote,
        client: client,
        event: event,
        selectedDishes: selectedDishes,
        dishQuantities: dishQuantities,
        percentageChoices: percentageChoices,
      );

      // Show options to share or open the PDF
      if (context.mounted) {
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
                    [XFile(pdfFile.path)],
                    subject: 'Quote for ${client.clientName}',
                  );
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  OpenFile.open(pdfFile.path);
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
                (c) => c.id == quote.clientId,
                orElse: () => Client(
                  id: quote.clientId,
                  clientName: 'Unknown Client',
                ),
              );
              final event = quote.eventId != null
                  ? appState.events.firstWhere(
                      (e) => e.id == quote.eventId,
                      orElse: () => Event(
                        id: quote.eventId!,
                        eventName: 'Unknown Event',
                        clientId: quote.clientId,
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
                        'Guests: ${quote.totalGuestCount} | Total: ₹${quote.grandTotal.toStringAsFixed(2)}',
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
                                    appState.deleteQuote(quote.id);
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