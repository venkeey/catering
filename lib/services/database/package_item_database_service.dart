import 'package:flutter/foundation.dart';
import '../../models/package_item.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';
import 'dish_database_service.dart';

/// Service for package item-related database operations
class PackageItemDatabaseService {
  final BaseDatabaseService _baseService;
  final DishDatabaseService _dishService;

  PackageItemDatabaseService(this._baseService, this._dishService);

  /// Get all package items from the database
  Future<List<PackageItem>> getPackageItems() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM package_items');
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await _dishService.getDish(fields['dish_id'].toString());
        
        return PackageItem(
          id: DatabaseHelper.stringValue(fields['item_id']),
          packageId: DatabaseHelper.stringValue(fields['package_id']) ?? '',
          dishId: DatabaseHelper.stringValue(fields['dish_id']) ?? '',
          isOptional: fields['is_optional'] == 1,
          dish: dish,
        );
      }));
    } catch (e) {
      debugPrint('Error getting package items: $e');
      rethrow;
    }
  }

  /// Get all package items for a specific package
  Future<List<PackageItem>> getPackageItemsForPackage(String packageId) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM package_items WHERE package_id = :packageId',
        {'packageId': packageId}
      );
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await _dishService.getDish(fields['dish_id'].toString());
        
        return PackageItem(
          id: DatabaseHelper.stringValue(fields['item_id']),
          packageId: DatabaseHelper.stringValue(fields['package_id']) ?? '',
          dishId: DatabaseHelper.stringValue(fields['dish_id']) ?? '',
          isOptional: fields['is_optional'] == 1,
          dish: dish,
        );
      }));
    } catch (e) {
      debugPrint('Error getting package items for package: $e');
      rethrow;
    }
  }

  /// Add a new package item to the database
  Future<String> addPackageItem(PackageItem item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO package_items (
          package_id, dish_id, is_optional
        ) VALUES (
          :packageId, :dishId, :isOptional
        )''',
        {
          'packageId': item.packageId,
          'dishId': item.dishId,
          'isOptional': item.isOptional ? 1 : 0,
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding package item: $e');
      rethrow;
    }
  }

  /// Update an existing package item in the database
  Future<void> updatePackageItem(PackageItem item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE package_items SET
          package_id = :packageId,
          dish_id = :dishId,
          is_optional = :isOptional
          WHERE item_id = :id
        ''',
        {
          'packageId': item.packageId,
          'dishId': item.dishId,
          'isOptional': item.isOptional ? 1 : 0,
          'id': item.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No package item updated with ID: ${item.id}');
      }
    } catch (e) {
      debugPrint('Error updating package item: $e');
      rethrow;
    }
  }

  /// Delete a package item from the database
  Future<void> deletePackageItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM package_items WHERE item_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No package item deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting package item: $e');
      rethrow;
    }
  }
}