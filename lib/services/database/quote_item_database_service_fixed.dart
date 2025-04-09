import 'package:flutter/foundation.dart';
import '../../models/quote_item.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';
import 'dish_database_service.dart';

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
          id: DatabaseHelper.bigIntValue(fields['item_id']) ?? BigInt.zero,
          quoteId: DatabaseHelper.bigIntValue(fields['quote_id']) ?? BigInt.zero,
          dishId: DatabaseHelper.bigIntValue(fields['dish_id']) ?? BigInt.zero,
          dishName: DatabaseHelper.stringValue(fields['dish_name']) ?? '',
          quantity: DatabaseHelper.doubleValue(fields['quantity']) ?? 0.0,
          unitPrice: DatabaseHelper.doubleValue(fields['unit_price']) ?? 0.0,
          totalPrice: DatabaseHelper.doubleValue(fields['total_price']) ?? 0.0,
          notes: DatabaseHelper.stringValue(fields['notes']),
          quotedPortionSizeGrams: DatabaseHelper.doubleValue(fields['quoted_portion_size_grams']),
          quotedBaseFoodCostPerServing: DatabaseHelper.doubleValue(fields['quoted_base_food_cost_per_serving']),
          percentageTakeRate: DatabaseHelper.doubleValue(fields['percentage_take_rate']),
          estimatedServings: DatabaseHelper.intValue(fields['estimated_servings']),
          estimatedTotalWeightGrams: DatabaseHelper.doubleValue(fields['estimated_total_weight_grams']),
          estimatedItemFoodCost: DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
          dishObject: null, // This will be populated later when needed
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
        {'quoteId': quoteId}
      );
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await _dishService.getDish(fields['dish_id'].toString());
        
        return QuoteItem(
          id: DatabaseHelper.bigIntValue(fields['item_id']) ?? BigInt.zero,
          quoteId: DatabaseHelper.bigIntValue(fields['quote_id']) ?? BigInt.zero,
          dishId: DatabaseHelper.bigIntValue(fields['dish_id']) ?? BigInt.zero,
          dishName: DatabaseHelper.stringValue(fields['dish_name']) ?? '',
          quantity: DatabaseHelper.doubleValue(fields['quantity']) ?? 0.0,
          unitPrice: DatabaseHelper.doubleValue(fields['unit_price']) ?? 0.0,
          totalPrice: DatabaseHelper.doubleValue(fields['total_price']) ?? 0.0,
          notes: DatabaseHelper.stringValue(fields['notes']),
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
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO quote_items (
          quote_id, dish_id, quoted_portion_size_grams, quoted_base_food_cost_per_serving,
          percentage_take_rate, estimated_servings, estimated_total_weight_grams,
          estimated_item_food_cost
        ) VALUES (
          :quoteId, :dishId, :portionSize, :foodCost,
          :takeRate, :servings, :totalWeight,
          :itemFoodCost
        )''',
        {
          'quoteId': item.quoteId,
          'dishId': item.dishId,
          'portionSize': item.quotedPortionSizeGrams,
          'foodCost': item.quotedBaseFoodCostPerServing,
          'takeRate': item.percentageTakeRate,
          'servings': item.estimatedServings,
          'totalWeight': item.estimatedTotalWeightGrams,
          'itemFoodCost': item.estimatedItemFoodCost,
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding quote item: $e');
      rethrow;
    }
  }

  /// Update an existing quote item in the database
  Future<void> updateQuoteItem(QuoteItem item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
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

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No quote item updated with ID: ${item.id}');
      }
    } catch (e) {
      debugPrint('Error updating quote item: $e');
      rethrow;
    }
  }

  /// Delete a quote item from the database
  Future<void> deleteQuoteItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM quote_items WHERE item_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No quote item deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting quote item: $e');
      rethrow;
    }
  }
}