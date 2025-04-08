import 'package:flutter/foundation.dart';
import '../../models/quote.dart';
import '../../models/quote_item.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';
import 'quote_item_database_service.dart';

/// Service for quote-related database operations
class QuoteDatabaseService {
  final BaseDatabaseService _baseService;
  final QuoteItemDatabaseService _quoteItemService;

  QuoteDatabaseService(this._baseService, this._quoteItemService);

  /// Get all quotes from the database
  Future<List<Quote>> getQuotes() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM quotes');

      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        
        // Get quote items
        final items = await _quoteItemService.getQuoteItemsForQuote(fields['quote_id'].toString());

        return Quote(
          id: DatabaseHelper.stringValue(fields['quote_id']),
          eventId: DatabaseHelper.stringValue(fields['event_id']),
          clientId: DatabaseHelper.stringValue(fields['client_id']) ?? '',
          quoteDate: DatabaseHelper.dateTimeValue(fields['quote_date']) ?? DateTime.now(),
          totalGuestCount: DatabaseHelper.intValue(fields['total_guest_count']) ?? 0,
          guestsMale: DatabaseHelper.intValue(fields['guests_male']) ?? 0,
          guestsFemale: DatabaseHelper.intValue(fields['guests_female']) ?? 0,
          guestsElderly: DatabaseHelper.intValue(fields['guests_elderly']) ?? 0,
          guestsYouth: DatabaseHelper.intValue(fields['guests_youth']) ?? 0,
          guestsChild: DatabaseHelper.intValue(fields['guests_child']) ?? 0,
          calculationMethod: fields['calculation_method'] as String? ?? 'Simple',
          overheadPercentage: DatabaseHelper.doubleValue(fields['overhead_percentage']) ?? 30.0,
          calculatedTotalFoodCost: DatabaseHelper.doubleValue(fields['calculated_total_food_cost']) ?? 0.0,
          calculatedOverheadCost: DatabaseHelper.doubleValue(fields['calculated_overhead_cost']) ?? 0.0,
          grandTotal: DatabaseHelper.doubleValue(fields['grand_total']) ?? 0.0,
          notes: fields['notes'] as String?,
          termsAndConditions: fields['terms_and_conditions'] as String?,
          status: fields['status'] as String? ?? 'Draft',
          items: items,
        );
      }));
    } catch (e) {
      debugPrint('Error getting quotes: $e');
      rethrow;
    }
  }

  /// Get a specific quote by ID
  Future<Quote?> getQuote(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM quotes WHERE quote_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      // Get quote items for this quote
      final quoteItems = await _quoteItemService.getQuoteItemsForQuote(id);
      
      return Quote(
        id: DatabaseHelper.stringValue(fields['quote_id']) ?? '',
        eventId: DatabaseHelper.stringValue(fields['event_id']),
        clientId: DatabaseHelper.stringValue(fields['client_id']) ?? '',
        quoteDate: DatabaseHelper.dateTimeValue(fields['quote_date']) ?? DateTime.now(),
        totalGuestCount: DatabaseHelper.intValue(fields['total_guest_count']) ?? 0,
        guestsMale: DatabaseHelper.intValue(fields['guests_male']) ?? 0,
        guestsFemale: DatabaseHelper.intValue(fields['guests_female']) ?? 0,
        guestsElderly: DatabaseHelper.intValue(fields['guests_elderly']) ?? 0,
        guestsYouth: DatabaseHelper.intValue(fields['guests_youth']) ?? 0,
        guestsChild: DatabaseHelper.intValue(fields['guests_child']) ?? 0,
        calculationMethod: fields['calculation_method'] as String? ?? 'Simple',
        overheadPercentage: DatabaseHelper.doubleValue(fields['overhead_percentage']) ?? 30.0,
        calculatedTotalFoodCost: DatabaseHelper.doubleValue(fields['calculated_total_food_cost']) ?? 0.0,
        calculatedOverheadCost: DatabaseHelper.doubleValue(fields['calculated_overhead_cost']) ?? 0.0,
        grandTotal: DatabaseHelper.doubleValue(fields['grand_total']) ?? 0.0,
        notes: fields['notes'] as String?,
        termsAndConditions: fields['terms_and_conditions'] as String?,
        status: fields['status'] as String? ?? 'Draft',
        items: quoteItems,
      );
    } catch (e) {
      debugPrint('Error getting quote: $e');
      rethrow;
    }
  }

  /// Add a new quote to the database
  Future<String> addQuote(Quote quote) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Insert the quote
      final result = await conn.execute(
        '''INSERT INTO quotes (
          event_id, client_id, quote_date, total_guest_count,
          guests_male, guests_female, guests_elderly, guests_youth, guests_child,
          calculation_method, overhead_percentage, calculated_total_food_cost,
          calculated_overhead_cost, grand_total, notes, terms_and_conditions, status
        ) VALUES (
          :eventId, :clientId, :quoteDate, :totalGuestCount,
          :guestsMale, :guestsFemale, :guestsElderly, :guestsYouth, :guestsChild,
          :calculationMethod, :overheadPercentage, :calculatedTotalFoodCost,
          :calculatedOverheadCost, :grandTotal, :notes, :termsAndConditions, :status
        )''',
        {
          'eventId': quote.eventId,
          'clientId': quote.clientId,
          'quoteDate': quote.quoteDate.toIso8601String(),
          'totalGuestCount': quote.totalGuestCount,
          'guestsMale': quote.guestsMale,
          'guestsFemale': quote.guestsFemale,
          'guestsElderly': quote.guestsElderly,
          'guestsYouth': quote.guestsYouth,
          'guestsChild': quote.guestsChild,
          'calculationMethod': quote.calculationMethod,
          'overheadPercentage': quote.overheadPercentage,
          'calculatedTotalFoodCost': quote.calculatedTotalFoodCost,
          'calculatedOverheadCost': quote.calculatedOverheadCost,
          'grandTotal': quote.grandTotal,
          'notes': quote.notes ?? '',
          'termsAndConditions': quote.termsAndConditions ?? '',
          'status': quote.status,
        }
      );

      final quoteId = result.lastInsertID.toString();
      
      // Insert quote items if any
      if (quote.items.isNotEmpty) {
        for (var item in quote.items) {
          final quoteItem = item.copyWith(quoteId: quoteId);
          await _quoteItemService.addQuoteItem(quoteItem);
        }
      }
      
      return quoteId;
    } catch (e) {
      debugPrint('Error adding quote: $e');
      rethrow;
    }
  }

  /// Update an existing quote in the database
  Future<void> updateQuote(Quote quote) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Update the quote
      final result = await conn.execute(
        '''UPDATE quotes SET
          event_id = :eventId,
          client_id = :clientId,
          quote_date = :quoteDate,
          total_guest_count = :totalGuestCount,
          guests_male = :guestsMale,
          guests_female = :guestsFemale,
          guests_elderly = :guestsElderly,
          guests_youth = :guestsYouth,
          guests_child = :guestsChild,
          calculation_method = :calculationMethod,
          overhead_percentage = :overheadPercentage,
          calculated_total_food_cost = :calculatedTotalFoodCost,
          calculated_overhead_cost = :calculatedOverheadCost,
          grand_total = :grandTotal,
          notes = :notes,
          terms_and_conditions = :termsAndConditions,
          status = :status
          WHERE quote_id = :id
        ''',
        {
          'eventId': quote.eventId,
          'clientId': quote.clientId,
          'quoteDate': quote.quoteDate.toIso8601String(),
          'totalGuestCount': quote.totalGuestCount,
          'guestsMale': quote.guestsMale,
          'guestsFemale': quote.guestsFemale,
          'guestsElderly': quote.guestsElderly,
          'guestsYouth': quote.guestsYouth,
          'guestsChild': quote.guestsChild,
          'calculationMethod': quote.calculationMethod,
          'overheadPercentage': quote.overheadPercentage,
          'calculatedTotalFoodCost': quote.calculatedTotalFoodCost,
          'calculatedOverheadCost': quote.calculatedOverheadCost,
          'grandTotal': quote.grandTotal,
          'notes': quote.notes ?? '',
          'termsAndConditions': quote.termsAndConditions ?? '',
          'status': quote.status,
          'id': quote.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No quote updated with ID: ${quote.id}');
      }
      
      // Delete existing quote items
      await conn.execute(
        'DELETE FROM quote_items WHERE quote_id = :quoteId',
        {'quoteId': quote.id}
      );
      
      // Insert updated quote items
      if (quote.items.isNotEmpty) {
        for (var item in quote.items) {
          final quoteItem = item.copyWith(quoteId: quote.id);
          await _quoteItemService.addQuoteItem(quoteItem);
        }
      }
    } catch (e) {
      debugPrint('Error updating quote: $e');
      rethrow;
    }
  }

  /// Delete a quote from the database
  Future<void> deleteQuote(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Delete quote items first (should cascade, but just to be safe)
      await _baseService.executeQuery(
        'DELETE FROM quote_items WHERE quote_id = :id',
        {'id': id}
      );
      
      // Delete the quote
      final result = await _baseService.executeQuery(
        'DELETE FROM quotes WHERE quote_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No quote deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      rethrow;
    }
  }
}