import 'package:flutter/foundation.dart';
import '../../models/quote_item.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';
import 'dish_database_service.dart';
import 'dart:math';

/// Service for quote item-related database operations
class QuoteItemDatabaseService {
  final BaseDatabaseService _baseService;
  final DishDatabaseService _dishService;

  QuoteItemDatabaseService(this._baseService, this._dishService);

  /// Get all quote items from the database
  Future<List<QuoteItem>> getQuoteItems() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM quote_items');
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await _dishService.getDish(fields['dish_id'].toString());
        
        return QuoteItem(
          id: DatabaseHelper.bigIntValue(fields['item_id']),
          quoteId: DatabaseHelper.bigIntValue(fields['quote_id']) ?? BigInt.from(0),
          dishId: DatabaseHelper.bigIntValue(fields['dish_id']) ?? BigInt.from(0),
          dishName: fields['dish_name'] as String? ?? '',
          quantity: DatabaseHelper.doubleValue(fields['quantity']) ?? 0.0,
          unitPrice: DatabaseHelper.doubleValue(fields['unit_price']) ?? 0.0,
          totalPrice: DatabaseHelper.doubleValue(fields['total_price']) ?? 0.0,
          quotedPortionSizeGrams: DatabaseHelper.doubleValue(fields['quoted_portion_size_grams']),
          quotedBaseFoodCostPerServing: DatabaseHelper.doubleValue(fields['quoted_base_food_cost_per_serving']),
          percentageTakeRate: DatabaseHelper.doubleValue(fields['percentage_take_rate']),
          estimatedServings: DatabaseHelper.intValue(fields['estimated_servings']),
          estimatedTotalWeightGrams: DatabaseHelper.doubleValue(fields['estimated_total_weight_grams']),
          estimatedItemFoodCost: DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
          dishObject: dish,
        );
      }));
    } catch (e) {
      debugPrint('Error getting quote items: $e');
      rethrow;
    }
  }

  /// Get all quote items for a specific quote
  Future<List<QuoteItem>> getQuoteItemsForQuote(String quoteId) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM quote_items WHERE quote_id = :quoteId',
        {'quoteId': BigInt.parse(quoteId).toString()}
      );
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await _dishService.getDish(fields['dish_id'].toString());
        
        return QuoteItem(
          id: DatabaseHelper.bigIntValue(fields['quote_item_id']),
          quoteId: DatabaseHelper.bigIntValue(fields['quote_id']) ?? BigInt.from(0),
          dishId: DatabaseHelper.bigIntValue(fields['dish_id']) ?? BigInt.from(0),
          dishName: fields['dish_name'] as String? ?? '',
          quantity: DatabaseHelper.doubleValue(fields['quantity']) ?? 0.0,
          unitPrice: DatabaseHelper.doubleValue(fields['unit_price']) ?? 0.0,
          totalPrice: DatabaseHelper.doubleValue(fields['total_price']) ?? 0.0,
          quotedPortionSizeGrams: DatabaseHelper.doubleValue(fields['quoted_portion_size_grams']),
          quotedBaseFoodCostPerServing: DatabaseHelper.doubleValue(fields['quoted_base_food_cost_per_serving']),
          percentageTakeRate: DatabaseHelper.doubleValue(fields['percentage_take_rate']),
          estimatedServings: DatabaseHelper.intValue(fields['estimated_servings']),
          estimatedTotalWeightGrams: DatabaseHelper.doubleValue(fields['estimated_total_weight_grams']),
          estimatedItemFoodCost: DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
          dishObject: dish,
        );
      }));
    } catch (e) {
      debugPrint('Error getting quote items for quote: $e');
      rethrow;
    }
  }

  /// Add a new quote item to the database
  Future<String> addQuoteItem(QuoteItem item) async {
    debugPrint('QuoteItemDatabaseService: Attempting to add quote item');
    debugPrint('QuoteItemDatabaseService: Item data: $item');
    
    if (!_baseService.isConnected) {
      debugPrint('QuoteItemDatabaseService: Database not connected');
      throw Exception('Database not connected');
    }

    try {
      // First, let's check the actual table structure
      final tableInfo = await _baseService.executeQuery('DESCRIBE quote_items');
      debugPrint('QuoteItemDatabaseService: Table structure: ${tableInfo.rows.map((row) => row.assoc()).toList()}');
      
      // Use the correct column names based on the actual table structure
      final result = await _baseService.executeQuery(
        'INSERT INTO quote_items (quote_id, dish_id, quantity, unit_price, total_price, '
        'quoted_portion_size_grams, quoted_base_food_cost_per_serving, estimated_servings, '
        'estimated_total_weight_grams, estimated_item_food_cost, percentage_take_rate) '
        'VALUES (:quoteId, :dishId, :quantity, :unitPrice, :totalPrice, :portionSize, '
        ':foodCost, :servings, :totalWeight, :itemFoodCost, :takeRate)',
        {
          'quoteId': item.quoteId.toString(),
          'dishId': item.dishId.toString(),
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'totalPrice': item.totalPrice,
          'portionSize': item.quotedPortionSizeGrams,
          'foodCost': item.quotedBaseFoodCostPerServing,
          'servings': item.estimatedServings,
          'totalWeight': item.estimatedTotalWeightGrams,
          'itemFoodCost': item.estimatedItemFoodCost,
          'takeRate': item.percentageTakeRate,
        }
      );

      final id = result.lastInsertID.toString();
      debugPrint('QuoteItemDatabaseService: Successfully added quote item with ID: $id');
      return id;
    } catch (e) {
      debugPrint('QuoteItemDatabaseService: Error adding quote item: $e');
      rethrow;
    }
  }

  /// Update an existing quote item in the database
  Future<void> updateQuoteItem(QuoteItem item) async {
    if (!_baseService.isConnected) {
      debugPrint('ERROR: Database not connected when trying to update quote item');
      throw Exception('Database not connected');
    }

    try {
      debugPrint('Attempting to update quote item with ID: ${item.id}');
      debugPrint('Update parameters: ${item.toMap()}');
      
      final result = await _baseService.executeQuery(
        '''UPDATE quote_items SET
          quote_id = :quoteId,
          dish_id = :dishId,
          quoted_portion_size_grams = :portionSize,
          quoted_base_food_cost_per_serving = :foodCost,
          percentage_take_rate = :takeRate,
          estimated_servings = :servings,
          estimated_total_weight_grams = :totalWeight,
          estimated_item_food_cost = :itemFoodCost
          WHERE item_id = :id
        ''',
        {
          'quoteId': item.quoteId,
          'dishId': item.dishId,
          'portionSize': item.quotedPortionSizeGrams,
          'foodCost': item.quotedBaseFoodCostPerServing,
          'takeRate': item.percentageTakeRate,
          'servings': item.estimatedServings,
          'totalWeight': item.estimatedTotalWeightGrams,
          'itemFoodCost': item.estimatedItemFoodCost,
          'id': item.id,
        }
      );

      debugPrint('Update result - affected rows: ${result.affectedRows}');
      
      if (result.affectedRows.toInt() <= 0) {
        debugPrint('WARNING: No rows were updated for quote item ID: ${item.id}');
        throw Exception('No quote item updated with ID: ${item.id}');
      }
      
      debugPrint('Successfully updated quote item with ID: ${item.id}');
    } catch (e) {
      debugPrint('ERROR updating quote item: $e');
      rethrow;
    }
  }

  /// Delete a quote item from the database
  Future<bool> deleteQuoteItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM quote_items WHERE quote_item_id = :id',
        {'id': BigInt.parse(id).toString()}
      );

      return result.affectedRows! > BigInt.zero;
    } catch (e) {
      debugPrint('Error deleting quote item: $e');
      return false;
    }
  }
}