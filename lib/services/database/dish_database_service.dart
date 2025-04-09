import 'package:flutter/foundation.dart';
import '../../models/dish.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for dish-related database operations
class DishDatabaseService {
  final BaseDatabaseService _baseService;

  DishDatabaseService(this._baseService);

  /// Ensure categories are properly set up
  Future<void> ensureCategories() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Define the categories
      final categories = [
        {'id': 1, 'name': 'Starters'},
        {'id': 2, 'name': 'Main Course'},
        {'id': 3, 'name': 'Non-Veg Main Course'},
        {'id': 4, 'name': 'Rice & Breads'},
        {'id': 5, 'name': 'Desserts'},
        {'id': 6, 'name': 'Beverages'},
      ];

      // Insert or update each category
      for (final category in categories) {
        try {
          await _baseService.executeQuery('''
            INSERT INTO categories (category_id, name) 
            VALUES (:id, :name)
            ON DUPLICATE KEY UPDATE name = :name
          ''', category);
          debugPrint('DishDatabaseService: Ensured category ${category['id']}: ${category['name']}');
        } catch (e) {
          // Try alternative syntax for SQLite or other databases that don't support ON DUPLICATE KEY
          try {
            final checkResult = await _baseService.executeQuery(
              'SELECT * FROM categories WHERE category_id = :id',
              {'id': category['id']}
            );
            
            if (checkResult.rows.isEmpty) {
              // Category doesn't exist, insert it
              await _baseService.executeQuery(
                'INSERT INTO categories (category_id, name) VALUES (:id, :name)',
                category
              );
              debugPrint('DishDatabaseService: Inserted category ${category['id']}: ${category['name']}');
            } else {
              // Category exists, update it
              await _baseService.executeQuery(
                'UPDATE categories SET name = :name WHERE category_id = :id',
                category
              );
              debugPrint('DishDatabaseService: Updated category ${category['id']}: ${category['name']}');
            }
          } catch (innerError) {
            debugPrint('DishDatabaseService: Error with alternative category insert: $innerError');
            rethrow;
          }
        }
      }
      
      // Now update the category field in dishes table to match the category name
      await _updateDishCategories(categories);
    } catch (e) {
      debugPrint('Error ensuring categories: $e');
      rethrow;
    }
  }
  
  /// Update the category field in dishes table to match the category name
  Future<void> _updateDishCategories(List<Map<String, dynamic>> categories) async {
    try {
      debugPrint('DishDatabaseService: Updating dish categories...');
      
      // For each category, update all dishes with that category_id
      for (final category in categories) {
        final categoryId = category['id'];
        final categoryName = category['name'];
        
        try {
          final result = await _baseService.executeQuery(
            'UPDATE dishes SET category = :categoryName WHERE category_id = :categoryId',
            {
              'categoryName': categoryName,
              'categoryId': categoryId.toString(),
            }
          );
          
          debugPrint('DishDatabaseService: Updated ${result.affectedRows} dishes with category: $categoryName');
        } catch (e) {
          debugPrint('DishDatabaseService: Error updating dishes for category $categoryId: $e');
        }
      }
      
      // Debug the results
      final dishesWithCategories = await _baseService.executeQuery(
        'SELECT category_id, category, COUNT(*) as count FROM dishes GROUP BY category_id, category'
      );
      
      for (final row in dishesWithCategories.rows) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        debugPrint('DishDatabaseService: Category ID: ${fields['category_id']}, ' +
                  'Category: ${fields['category']}, ' +
                  'Count: ${fields['count']}');
      }
    } catch (e) {
      debugPrint('DishDatabaseService: Error in _updateDishCategories: $e');
    }
  }

  /// Get all dishes from the database
  Future<List<Dish>> getDishes() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    // Ensure categories are set up before getting dishes
    await ensureCategories();

    try {
      // Debug the categories first
      final categoryResults = await _baseService.executeQuery('SELECT * FROM categories');
      debugPrint('DishDatabaseService: Found ${categoryResults.rows.length} categories');
      for (final row in categoryResults.rows) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        debugPrint('DishDatabaseService: Category ID: ${fields['category_id']}, Name: ${fields['name']}');
      }

      // Now get the dishes with proper category handling
      final results = await _baseService.executeQuery('''
        SELECT d.*, c.name as category_name 
        FROM dishes d 
        LEFT JOIN categories c ON d.category_id = c.category_id
      ''');
      
      debugPrint('DishDatabaseService: Found ${results.rows.length} dishes');
      
      // First, update any dishes that have a category_id but no category name
      await _updateMissingCategoryNames();
      
      final dishes = results.rows.map((row) {
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
        // Note: The ingredients field might not exist in the current schema
        
        // Get category ID and name from the joined query
        final categoryId = fields['category_id']?.toString() ?? '';
        
        // First check if the dish already has a category field set
        String? existingCategory = fields['category'] as String?;
        if (existingCategory != null && existingCategory.trim().isNotEmpty) {
          debugPrint('DishDatabaseService: Dish ${fields['name']} already has category: $existingCategory');
          return Dish(
            id: DatabaseHelper.stringValue(fields['dish_id']),
            name: fields['name'] as String? ?? '',
            categoryId: categoryId,
            category: existingCategory,
            basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
            baseFoodCost: DatabaseHelper.doubleValue(fields['base_food_cost']) ?? 0.0,
            standardPortionSize: DatabaseHelper.doubleValue(fields['standard_portion_size_grams']) ?? 0.0,
            description: fields['description'] as String?,
            imageUrl: fields['image_url'] as String?,
            dietaryTags: dietaryTagsList,
            itemType: fields['item_type'] as String? ?? 'Standard',
            isActive: fields['is_active'] == 1,
            ingredients: ingredientsMap,
            createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
          );
        }
        
        // Make sure we have a valid category name
        String categoryName;
        if (fields['category_name'] != null && fields['category_name'].toString().trim().isNotEmpty) {
          categoryName = fields['category_name'].toString();
          
          // Update the dish's category field in the database
          _updateDishCategory(fields['dish_id'].toString(), categoryName);
        } else {
          // If category_name is null or empty, check if we have a valid category_id
          if (categoryId.isNotEmpty) {
            // Try to find the category name from our predefined categories
            final categoryIndex = int.tryParse(categoryId);
            if (categoryIndex != null && categoryIndex >= 1 && categoryIndex <= 6) {
              final categories = [
                'Starters',
                'Main Course',
                'Non-Veg Main Course',
                'Rice & Breads',
                'Desserts',
                'Beverages',
              ];
              categoryName = categories[categoryIndex - 1];
              
              // Update the dish's category field in the database
              _updateDishCategory(fields['dish_id'].toString(), categoryName);
            } else {
              categoryName = 'Uncategorized';
            }
          } else {
            categoryName = 'Uncategorized';
          }
        }
        
        debugPrint('DishDatabaseService: Dish ${fields['name']} has category: $categoryName (ID: $categoryId)');
        
        // Handle the standard_portion_size_grams field which is different from the expected field name
        final standardPortionSize = DatabaseHelper.doubleValue(fields['standard_portion_size_grams']) ?? 
                                   DatabaseHelper.doubleValue(fields['standard_portion_size']) ?? 0.0;
        
        return Dish(
          id: DatabaseHelper.stringValue(fields['dish_id']),
          name: fields['name'] as String? ?? '',
          categoryId: categoryId,
          category: categoryName,
          basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
          baseFoodCost: DatabaseHelper.doubleValue(fields['base_food_cost']) ?? 0.0,
          standardPortionSize: standardPortionSize,
          description: fields['description'] as String?,
          imageUrl: fields['image_url'] as String?,
          dietaryTags: dietaryTagsList,
          itemType: fields['item_type'] as String? ?? 'Standard',
          isActive: fields['is_active'] == 1,
          ingredients: ingredientsMap,
          createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
        );
      }).toList();
      
      // Group dishes by category to verify we have proper categorization
      final dishesByCategory = <String, List<Dish>>{};
      for (final dish in dishes) {
        if (!dishesByCategory.containsKey(dish.category)) {
          dishesByCategory[dish.category] = [];
        }
        dishesByCategory[dish.category]!.add(dish);
      }
      
      debugPrint('DishDatabaseService: Grouped dishes into ${dishesByCategory.length} categories');
      for (final category in dishesByCategory.keys) {
        debugPrint('DishDatabaseService: Category "$category" has ${dishesByCategory[category]!.length} dishes');
      }
      
      return dishes;
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
      final results = await _baseService.executeQuery('''
        SELECT d.*, c.name as category_name 
        FROM dishes d 
        LEFT JOIN categories c ON d.category_id = c.category_id
        WHERE d.dish_id = :id
      ''', {'id': id});

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
      // Note: The ingredients field might not exist in the current schema
      
      // Get category ID and name from the joined query
      final categoryId = fields['category_id']?.toString() ?? '';
      
      // Make sure we have a valid category name
      String categoryName;
      if (fields['category_name'] != null && fields['category_name'].toString().trim().isNotEmpty) {
        categoryName = fields['category_name'].toString();
      } else {
        // If category_name is null or empty, check if we have a valid category_id
        if (categoryId.isNotEmpty) {
          // Try to find the category name from our predefined categories
          final categoryIndex = int.tryParse(categoryId);
          if (categoryIndex != null && categoryIndex >= 1 && categoryIndex <= 6) {
            final categories = [
              'Starters',
              'Main Course',
              'Non-Veg Main Course',
              'Rice & Breads',
              'Desserts',
              'Beverages',
            ];
            categoryName = categories[categoryIndex - 1];
          } else {
            categoryName = 'Uncategorized';
          }
        } else {
          categoryName = 'Uncategorized';
        }
      }
      
      debugPrint('DishDatabaseService: Dish ${fields['name']} has category: $categoryName (ID: $categoryId)');
      
      // Handle the standard_portion_size_grams field which is different from the expected field name
      final standardPortionSize = DatabaseHelper.doubleValue(fields['standard_portion_size_grams']) ?? 
                                 DatabaseHelper.doubleValue(fields['standard_portion_size']) ?? 0.0;
      
      return Dish(
        id: DatabaseHelper.stringValue(fields['dish_id']),
        name: fields['name'] as String? ?? '',
        categoryId: categoryId,
        category: categoryName,
        basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
        baseFoodCost: DatabaseHelper.doubleValue(fields['base_food_cost']) ?? 0.0,
        standardPortionSize: standardPortionSize,
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
  
  /// Update a dish's category field in the database
  Future<void> _updateDishCategory(String dishId, String categoryName) async {
    try {
      await _baseService.executeQuery(
        'UPDATE dishes SET category = :categoryName WHERE dish_id = :dishId',
        {
          'categoryName': categoryName,
          'dishId': dishId,
        }
      );
      debugPrint('DishDatabaseService: Updated dish $dishId with category: $categoryName');
    } catch (e) {
      debugPrint('DishDatabaseService: Error updating dish $dishId category: $e');
    }
  }
  
  /// Update all dishes that have a category_id but no category name
  Future<void> _updateMissingCategoryNames() async {
    try {
      // Get all dishes with a category_id but no category name
      final results = await _baseService.executeQuery('''
        SELECT d.dish_id, d.category_id, c.name as category_name
        FROM dishes d
        JOIN categories c ON d.category_id = c.category_id
        WHERE (d.category IS NULL OR d.category = '')
      ''');
      
      debugPrint('DishDatabaseService: Found ${results.rows.length} dishes with missing category names');
      
      // Update each dish with the correct category name
      for (final row in results.rows) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dishId = fields['dish_id'].toString();
        final categoryName = fields['category_name'].toString();
        
        await _updateDishCategory(dishId, categoryName);
      }
    } catch (e) {
      debugPrint('DishDatabaseService: Error updating missing category names: $e');
    }
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
          standard_portion_size_grams, description, image_url, dietary_tags,
          item_type, is_active
        ) VALUES (
          :name, :categoryId, :basePrice, :baseFoodCost,
          :standardPortionSize, :description, :imageUrl, :dietaryTags,
          :itemType, :isActive
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
          standard_portion_size_grams = :standardPortionSize,
          description = :description,
          image_url = :imageUrl,
          dietary_tags = :dietaryTags,
          item_type = :itemType,
          is_active = :isActive
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