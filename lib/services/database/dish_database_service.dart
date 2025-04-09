import 'package:flutter/foundation.dart';
import '../../models/dish.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for dish-related database operations
class DishDatabaseService {
  final BaseDatabaseService _baseService;

  DishDatabaseService(this._baseService);

  /// Get all dishes from the database
  Future<List<Dish>> getDishes() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM dishes');
      
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        
        // Parse dietary tags from string to List<String>
        List<String> dietaryTagsList = [];
        if (fields['dietary_tags'] != null) {
          final tagsStr = fields['dietary_tags'] as String?;
          if (tagsStr != null && tagsStr.isNotEmpty) {
            dietaryTagsList = tagsStr.split(',');
          }
        }
        
        // Parse ingredients from string to Map<String, double>
        Map<String, double> ingredientsMap = {};
        if (fields['ingredients'] != null) {
          final ingredientsStr = fields['ingredients'] as String?;
          if (ingredientsStr != null && ingredientsStr.isNotEmpty) {
            // Simple parsing - in a real app, you'd want more robust parsing
            try {
              final pairs = ingredientsStr.split(',');
              for (final pair in pairs) {
                final keyValue = pair.split(':');
                if (keyValue.length == 2) {
                  final key = keyValue[0].trim();
                  final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
                  ingredientsMap[key] = value;
                }
              }
            } catch (e) {
              debugPrint('Error parsing ingredients: $e');
            }
          }
        }
        
        // Use category_id as category if category column doesn't exist
        final categoryId = fields['category_id'] as String? ?? '';
        final category = fields['category'] as String? ?? categoryId;
        
        return Dish(
          id: DatabaseHelper.stringValue(fields['dish_id']),
          name: fields['name'] as String? ?? '',
          categoryId: categoryId,
          category: category,
          basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
          baseFoodCost: DatabaseHelper.doubleValue(fields['base_food_cost']) ?? 0.0,
          standardPortionSize: DatabaseHelper.doubleValue(fields['standard_portion_size']) ?? 0.0,
          description: fields['description'] as String?,
          imageUrl: fields['image_url'] as String?,
          dietaryTags: dietaryTagsList,
          itemType: fields['item_type'] as String? ?? 'Standard',
          isActive: fields['is_active'] == 1,
          ingredients: ingredientsMap,
          createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting dishes: $e');
      rethrow;
    }
  }

  /// Get a specific dish by ID
  Future<Dish?> getDish(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM dishes WHERE dish_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      // Parse dietary tags from string to List<String>
      List<String> dietaryTagsList = [];
      if (fields['dietary_tags'] != null) {
        final tagsStr = fields['dietary_tags'] as String?;
        if (tagsStr != null && tagsStr.isNotEmpty) {
          dietaryTagsList = tagsStr.split(',');
        }
      }
      
      // Parse ingredients from string to Map<String, double>
      Map<String, double> ingredientsMap = {};
      if (fields['ingredients'] != null) {
        final ingredientsStr = fields['ingredients'] as String?;
        if (ingredientsStr != null && ingredientsStr.isNotEmpty) {
          // Simple parsing - in a real app, you'd want more robust parsing
          try {
            final pairs = ingredientsStr.split(',');
            for (final pair in pairs) {
              final keyValue = pair.split(':');
              if (keyValue.length == 2) {
                final key = keyValue[0].trim();
                final value = double.tryParse(keyValue[1].trim()) ?? 0.0;
                ingredientsMap[key] = value;
              }
            }
          } catch (e) {
            debugPrint('Error parsing ingredients: $e');
          }
        }
      }
      
      // Use category_id as category if category column doesn't exist
      final categoryId = fields['category_id'] as String? ?? '';
      final category = fields['category'] as String? ?? categoryId;
      
      return Dish(
        id: DatabaseHelper.stringValue(fields['dish_id']),
        name: fields['name'] as String? ?? '',
        categoryId: categoryId,
        category: category,
        basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
        baseFoodCost: DatabaseHelper.doubleValue(fields['base_food_cost']) ?? 0.0,
        standardPortionSize: DatabaseHelper.doubleValue(fields['standard_portion_size']) ?? 0.0,
        description: fields['description'] as String?,
        imageUrl: fields['image_url'] as String?,
        dietaryTags: dietaryTagsList,
        itemType: fields['item_type'] as String? ?? 'Standard',
        isActive: fields['is_active'] == 1,
        ingredients: ingredientsMap,
        createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
      );
    } catch (e) {
      debugPrint('Error getting dish: $e');
      rethrow;
    }
  }

  /// Helper method to serialize ingredients map to string
  String _serializeIngredients(Map<String, double> ingredients) {
    if (ingredients.isEmpty) return '';
    return ingredients.entries.map((e) => '${e.key}:${e.value}').join(',');
  }

  /// Add a new dish to the database
  Future<String> addDish(Dish dish) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO dishes (
          name, category_id, base_price, base_food_cost,
          standard_portion_size, description, image_url, dietary_tags,
          item_type, is_active, ingredients
        ) VALUES (
          :name, :categoryId, :basePrice, :baseFoodCost,
          :standardPortionSize, :description, :imageUrl, :dietaryTags,
          :itemType, :isActive, :ingredients
        )''',
        {
          'name': dish.name,
          'categoryId': dish.categoryId,
          'basePrice': dish.basePrice,
          'baseFoodCost': dish.baseFoodCost,
          'standardPortionSize': dish.standardPortionSize,
          'description': dish.description,
          'imageUrl': dish.imageUrl,
          'dietaryTags': dish.dietaryTags.join(','),
          'itemType': dish.itemType,
          'isActive': dish.isActive ? 1 : 0,
          'ingredients': _serializeIngredients(dish.ingredients),
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding dish: $e');
      rethrow;
    }
  }

  /// Update an existing dish in the database
  Future<void> updateDish(Dish dish) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE dishes SET
          name = :name,
          category_id = :categoryId,
          base_price = :basePrice,
          base_food_cost = :baseFoodCost,
          standard_portion_size = :standardPortionSize,
          description = :description,
          image_url = :imageUrl,
          dietary_tags = :dietaryTags,
          item_type = :itemType,
          is_active = :isActive,
          ingredients = :ingredients
          WHERE dish_id = :id
        ''',
        {
          'name': dish.name,
          'categoryId': dish.categoryId,
          'basePrice': dish.basePrice,
          'baseFoodCost': dish.baseFoodCost,
          'standardPortionSize': dish.standardPortionSize,
          'description': dish.description,
          'imageUrl': dish.imageUrl,
          'dietaryTags': dish.dietaryTags.join(','),
          'itemType': dish.itemType,
          'isActive': dish.isActive ? 1 : 0,
          'ingredients': _serializeIngredients(dish.ingredients),
          'id': dish.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No dish updated with ID: ${dish.id}');
      }
    } catch (e) {
      debugPrint('Error updating dish: $e');
      rethrow;
    }
  }

  /// Delete a dish from the database
  Future<void> deleteDish(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM dishes WHERE dish_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No dish deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting dish: $e');
      rethrow;
    }
  }
}