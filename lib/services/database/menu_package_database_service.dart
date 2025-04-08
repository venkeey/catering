import 'package:flutter/foundation.dart';
import '../../models/menu_package.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';
import 'package_item_database_service.dart';

/// Service for menu package-related database operations
class MenuPackageDatabaseService {
  final BaseDatabaseService _baseService;
  final PackageItemDatabaseService _packageItemService;

  MenuPackageDatabaseService(this._baseService, this._packageItemService);

  /// Get all menu packages from the database
  Future<List<MenuPackage>> getMenuPackages() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM menu_packages');
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final packageId = fields['package_id'].toString();
        
        // Get package items
        final packageItems = await _packageItemService.getPackageItemsForPackage(packageId);
        
        return MenuPackage(
          id: DatabaseHelper.stringValue(fields['package_id']),
          name: fields['name'] as String? ?? '',
          description: fields['description'] as String? ?? '',
          basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
          eventType: fields['event_type'] as String? ?? 'Default',
          isActive: fields['is_active'] == 1,
          createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
          packageItems: packageItems,
        );
      }));
    } catch (e) {
      debugPrint('Error getting menu packages: $e');
      rethrow;
    }
  }

  /// Get a specific menu package by ID
  Future<MenuPackage?> getMenuPackage(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM menu_packages WHERE package_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      // Get package items
      final packageItems = await _packageItemService.getPackageItemsForPackage(id);
      
      return MenuPackage(
        id: DatabaseHelper.stringValue(fields['package_id']),
        name: fields['name'] as String? ?? '',
        description: fields['description'] as String? ?? '',
        basePrice: DatabaseHelper.doubleValue(fields['base_price']) ?? 0.0,
        eventType: fields['event_type'] as String? ?? 'Default',
        isActive: fields['is_active'] == 1,
        createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
        packageItems: packageItems,
      );
    } catch (e) {
      debugPrint('Error getting menu package: $e');
      rethrow;
    }
  }

  /// Add a new menu package to the database
  Future<String> addMenuPackage(MenuPackage package) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Insert the package
      final result = await conn.execute(
        '''INSERT INTO menu_packages (
          name, description, base_price, is_active
        ) VALUES (
          :name, :description, :basePrice, :isActive
        )''',
        {
          'name': package.name,
          'description': package.description,
          'basePrice': package.basePrice,
          'isActive': package.isActive ? 1 : 0,
        }
      );

      final packageId = result.lastInsertID.toString();
      
      // Insert package items if any
      if (package.items.isNotEmpty) {
        for (var item in package.items) {
          final packageItem = item.copyWith(packageId: packageId);
          await _packageItemService.addPackageItem(packageItem);
        }
      }
      
      return packageId;
    } catch (e) {
      debugPrint('Error adding menu package: $e');
      rethrow;
    }
  }

  /// Update an existing menu package in the database
  Future<void> updateMenuPackage(MenuPackage package) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Update the package
      final result = await conn.execute(
        '''UPDATE menu_packages SET
          name = :name,
          description = :description,
          base_price = :basePrice,
          is_active = :isActive
          WHERE package_id = :id
        ''',
        {
          'name': package.name,
          'description': package.description,
          'basePrice': package.basePrice,
          'isActive': package.isActive ? 1 : 0,
          'id': package.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No menu package updated with ID: ${package.id}');
      }
      
      // Delete existing package items
      await conn.execute(
        'DELETE FROM package_items WHERE package_id = :packageId',
        {'packageId': package.id}
      );
      
      // Insert updated package items
      if (package.items.isNotEmpty) {
        for (var item in package.items) {
          final packageItem = item.copyWith(packageId: package.id);
          await _packageItemService.addPackageItem(packageItem);
        }
      }
    } catch (e) {
      debugPrint('Error updating menu package: $e');
      rethrow;
    }
  }

  /// Delete a menu package from the database
  Future<void> deleteMenuPackage(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Delete package items first (should cascade, but just to be safe)
      await _baseService.executeQuery(
        'DELETE FROM package_items WHERE package_id = :id',
        {'id': id}
      );
      
      // Delete the package
      final result = await _baseService.executeQuery(
        'DELETE FROM menu_packages WHERE package_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No menu package deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting menu package: $e');
      rethrow;
    }
  }
}