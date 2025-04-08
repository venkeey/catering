import 'package:flutter/foundation.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for inventory-related database operations
class InventoryDatabaseService {
  final BaseDatabaseService _baseService;

  InventoryDatabaseService(this._baseService);

  /// Get all inventory items from the database
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM inventory_items');
      
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return {
          'id': DatabaseHelper.stringValue(fields['item_id']),
          'name': fields['name'],
          'unit': fields['unit'],
          'unitCost': DatabaseHelper.doubleValue(fields['unit_cost']),
          'quantityInStock': DatabaseHelper.doubleValue(fields['quantity_in_stock']),
          'reorderLevel': DatabaseHelper.doubleValue(fields['reorder_level']),
          'supplierId': DatabaseHelper.stringValue(fields['supplier_id']),
          'notes': fields['notes'],
          'createdAt': fields['created_at'],
          'updatedAt': fields['updated_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting inventory items: $e');
      rethrow;
    }
  }

  /// Get a specific inventory item by ID
  Future<Map<String, dynamic>?> getInventoryItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM inventory_items WHERE item_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return {
        'id': DatabaseHelper.stringValue(fields['item_id']),
        'name': fields['name'],
        'unit': fields['unit'],
        'unitCost': DatabaseHelper.doubleValue(fields['unit_cost']),
        'quantityInStock': DatabaseHelper.doubleValue(fields['quantity_in_stock']),
        'reorderLevel': DatabaseHelper.doubleValue(fields['reorder_level']),
        'supplierId': DatabaseHelper.stringValue(fields['supplier_id']),
        'notes': fields['notes'],
        'createdAt': fields['created_at'],
        'updatedAt': fields['updated_at'],
      };
    } catch (e) {
      debugPrint('Error getting inventory item: $e');
      rethrow;
    }
  }

  /// Add a new inventory item to the database
  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO inventory_items (
          name, unit, unit_cost, quantity_in_stock, reorder_level,
          supplier_id, notes
        ) VALUES (
          :name, :unit, :unitCost, :quantityInStock, :reorderLevel,
          :supplierId, :notes
        )''',
        {
          'name': item['name'],
          'unit': item['unit'],
          'unitCost': item['unitCost'],
          'quantityInStock': item['quantityInStock'] ?? 0,
          'reorderLevel': item['reorderLevel'] ?? 0,
          'supplierId': item['supplierId'],
          'notes': item['notes'],
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      rethrow;
    }
  }

  /// Update an existing inventory item in the database
  Future<void> updateInventoryItem(Map<String, dynamic> item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE inventory_items SET
          name = :name,
          unit = :unit,
          unit_cost = :unitCost,
          quantity_in_stock = :quantityInStock,
          reorder_level = :reorderLevel,
          supplier_id = :supplierId,
          notes = :notes
          WHERE item_id = :id
        ''',
        {
          'name': item['name'],
          'unit': item['unit'],
          'unitCost': item['unitCost'],
          'quantityInStock': item['quantityInStock'] ?? 0,
          'reorderLevel': item['reorderLevel'] ?? 0,
          'supplierId': item['supplierId'],
          'notes': item['notes'],
          'id': item['id'],
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No inventory item updated with ID: ${item['id']}');
      }
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  /// Delete an inventory item from the database
  Future<void> deleteInventoryItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM inventory_items WHERE item_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No inventory item deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      rethrow;
    }
  }
}