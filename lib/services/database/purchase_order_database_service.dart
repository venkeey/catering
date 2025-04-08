import 'package:flutter/foundation.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for purchase order-related database operations
class PurchaseOrderDatabaseService {
  final BaseDatabaseService _baseService;

  PurchaseOrderDatabaseService(this._baseService);

  /// Get all purchase orders from the database
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM purchase_orders');
      
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final orderId = fields['order_id'].toString();
        
        // Get order items
        final orderItems = await getPurchaseOrderItems(orderId);
        
        return {
          'id': DatabaseHelper.stringValue(fields['order_id']),
          'supplierId': DatabaseHelper.stringValue(fields['supplier_id']),
          'orderDate': fields['order_date'],
          'expectedDeliveryDate': fields['expected_delivery_date'],
          'status': fields['status'],
          'totalAmount': DatabaseHelper.doubleValue(fields['total_amount']),
          'notes': fields['notes'],
          'createdAt': fields['created_at'],
          'items': orderItems,
        };
      }));
    } catch (e) {
      debugPrint('Error getting purchase orders: $e');
      rethrow;
    }
  }

  /// Get a specific purchase order by ID
  Future<Map<String, dynamic>?> getPurchaseOrder(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM purchase_orders WHERE order_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      // Get order items
      final orderItems = await getPurchaseOrderItems(id);
      
      return {
        'id': DatabaseHelper.stringValue(fields['order_id']),
        'supplierId': DatabaseHelper.stringValue(fields['supplier_id']),
        'orderDate': fields['order_date'],
        'expectedDeliveryDate': fields['expected_delivery_date'],
        'status': fields['status'],
        'totalAmount': DatabaseHelper.doubleValue(fields['total_amount']),
        'notes': fields['notes'],
        'createdAt': fields['created_at'],
        'items': orderItems,
      };
    } catch (e) {
      debugPrint('Error getting purchase order: $e');
      rethrow;
    }
  }

  /// Add a new purchase order to the database
  Future<String> addPurchaseOrder(Map<String, dynamic> order) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Insert the order
      final result = await conn.execute(
        '''INSERT INTO purchase_orders (
          supplier_id, order_date, expected_delivery_date, status,
          total_amount, notes
        ) VALUES (
          :supplierId, :orderDate, :expectedDeliveryDate, :status,
          :totalAmount, :notes
        )''',
        {
          'supplierId': order['supplierId'],
          'orderDate': order['orderDate'],
          'expectedDeliveryDate': order['expectedDeliveryDate'],
          'status': order['status'] ?? 'Pending',
          'totalAmount': order['totalAmount'] ?? 0,
          'notes': order['notes'],
        }
      );

      final orderId = result.lastInsertID.toString();
      
      // Insert order items if any
      if (order['items'] != null && (order['items'] as List).isNotEmpty) {
        for (var item in order['items'] as List) {
          await addPurchaseOrderItem({
            ...item,
            'orderId': orderId,
          });
        }
      }
      
      return orderId;
    } catch (e) {
      debugPrint('Error adding purchase order: $e');
      rethrow;
    }
  }

  /// Update an existing purchase order in the database
  Future<void> updatePurchaseOrder(Map<String, dynamic> order) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Start a transaction
      final conn = _baseService.connection!;
      
      // Update the order
      final result = await conn.execute(
        '''UPDATE purchase_orders SET
          supplier_id = :supplierId,
          order_date = :orderDate,
          expected_delivery_date = :expectedDeliveryDate,
          status = :status,
          total_amount = :totalAmount,
          notes = :notes
          WHERE order_id = :id
        ''',
        {
          'supplierId': order['supplierId'],
          'orderDate': order['orderDate'],
          'expectedDeliveryDate': order['expectedDeliveryDate'],
          'status': order['status'] ?? 'Pending',
          'totalAmount': order['totalAmount'] ?? 0,
          'notes': order['notes'],
          'id': order['id'],
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No purchase order updated with ID: ${order['id']}');
      }
      
      // Delete existing order items
      await conn.execute(
        'DELETE FROM purchase_order_items WHERE order_id = :orderId',
        {'orderId': order['id']}
      );
      
      // Insert updated order items
      if (order['items'] != null && (order['items'] as List).isNotEmpty) {
        for (var item in order['items'] as List) {
          await addPurchaseOrderItem({
            ...item,
            'orderId': order['id'],
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating purchase order: $e');
      rethrow;
    }
  }

  /// Delete a purchase order from the database
  Future<void> deletePurchaseOrder(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      // Delete order items first (should cascade, but just to be safe)
      await _baseService.executeQuery(
        'DELETE FROM purchase_order_items WHERE order_id = :id',
        {'id': id}
      );
      
      // Delete the order
      final result = await _baseService.executeQuery(
        'DELETE FROM purchase_orders WHERE order_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No purchase order deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting purchase order: $e');
      rethrow;
    }
  }

  /// Get all purchase order items for a specific order
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String orderId) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM purchase_order_items WHERE order_id = :orderId',
        {'orderId': orderId}
      );
      
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return {
          'id': DatabaseHelper.stringValue(fields['item_id']),
          'orderId': DatabaseHelper.stringValue(fields['order_id']),
          'inventoryItemId': DatabaseHelper.stringValue(fields['inventory_item_id']),
          'quantity': DatabaseHelper.doubleValue(fields['quantity']),
          'unitPrice': DatabaseHelper.doubleValue(fields['unit_price']),
          'totalPrice': DatabaseHelper.doubleValue(fields['total_price']),
          'notes': fields['notes'],
          'createdAt': fields['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting purchase order items: $e');
      rethrow;
    }
  }

  /// Get a specific purchase order item by ID
  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM purchase_order_items WHERE item_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return {
        'id': DatabaseHelper.stringValue(fields['item_id']),
        'orderId': DatabaseHelper.stringValue(fields['order_id']),
        'inventoryItemId': DatabaseHelper.stringValue(fields['inventory_item_id']),
        'quantity': DatabaseHelper.doubleValue(fields['quantity']),
        'unitPrice': DatabaseHelper.doubleValue(fields['unit_price']),
        'totalPrice': DatabaseHelper.doubleValue(fields['total_price']),
        'notes': fields['notes'],
        'createdAt': fields['created_at'],
      };
    } catch (e) {
      debugPrint('Error getting purchase order item: $e');
      rethrow;
    }
  }

  /// Add a new purchase order item to the database
  Future<String> addPurchaseOrderItem(Map<String, dynamic> item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO purchase_order_items (
          order_id, inventory_item_id, quantity, unit_price,
          total_price, notes
        ) VALUES (
          :orderId, :inventoryItemId, :quantity, :unitPrice,
          :totalPrice, :notes
        )''',
        {
          'orderId': item['orderId'],
          'inventoryItemId': item['inventoryItemId'],
          'quantity': item['quantity'],
          'unitPrice': item['unitPrice'],
          'totalPrice': item['totalPrice'],
          'notes': item['notes'],
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding purchase order item: $e');
      rethrow;
    }
  }

  /// Update an existing purchase order item in the database
  Future<void> updatePurchaseOrderItem(Map<String, dynamic> item) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE purchase_order_items SET
          order_id = :orderId,
          inventory_item_id = :inventoryItemId,
          quantity = :quantity,
          unit_price = :unitPrice,
          total_price = :totalPrice,
          notes = :notes
          WHERE item_id = :id
        ''',
        {
          'orderId': item['orderId'],
          'inventoryItemId': item['inventoryItemId'],
          'quantity': item['quantity'],
          'unitPrice': item['unitPrice'],
          'totalPrice': item['totalPrice'],
          'notes': item['notes'],
          'id': item['id'],
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No purchase order item updated with ID: ${item['id']}');
      }
    } catch (e) {
      debugPrint('Error updating purchase order item: $e');
      rethrow;
    }
  }

  /// Delete a purchase order item from the database
  Future<void> deletePurchaseOrderItem(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM purchase_order_items WHERE item_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No purchase order item deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting purchase order item: $e');
      rethrow;
    }
  }
}