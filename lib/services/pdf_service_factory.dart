import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/quote.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/dish.dart';

// Import the platform-specific implementations
import 'pdf_service.dart';
import 'pdf_service_simple.dart';
import 'pdf_service_web.dart';

// Conditionally import the web implementation
// This is a conditional import that will only be used on web platforms
export 'pdf_service_web.dart' if (dart.library.io) 'pdf_service.dart';

/// Factory class that provides the appropriate PDF service based on the platform
class PdfServiceFactory {
  /// Generates a quote PDF using the appropriate service for the current platform
  static Future<dynamic> generateQuotePdf({
    required Quote quote,
    required Client client,
    Event? event,
    required List<Dish> selectedDishes,
    required Map<String, double> dishQuantities,
    required Map<String, double> percentageChoices,
  }) async {
    try {
      if (kIsWeb) {
        // For web platforms, use the web-specific implementation
        // This will be handled by the conditional export above
        // The web implementation returns void instead of File
        print('Using web PDF service');
        
        // Use the web-specific implementation from PdfServiceWeb class
        return PdfServiceWeb.generateAndDownloadQuotePdf(
          quote: quote,
          client: client,
          event: event,
          selectedDishes: selectedDishes,
          dishQuantities: dishQuantities,
          percentageChoices: percentageChoices,
        );
      } else {
        // For non-web platforms, use the regular implementation
        print('Using regular PDF service');
        return PdfService.generateQuotePdf(
          quote: quote,
          client: client,
          event: event,
          selectedDishes: selectedDishes,
          dishQuantities: dishQuantities,
          percentageChoices: percentageChoices,
        );
      }
    } catch (e) {
      print('Error in PDF service factory: $e');
      print('Falling back to simple PDF service');
      
      // If both attempts fail, fall back to PdfServiceSimple
      print('Error generating PDF with PdfService: $e');
      print('Falling back to PdfServiceSimple');
      final pdfService = PdfServiceSimple.create();
      return pdfService.generateQuotePdf(
        quote: quote,
        client: client,
        event: event,
        selectedDishes: selectedDishes,
        dishQuantities: dishQuantities,
        percentageChoices: percentageChoices,
      );
    }
  }
}