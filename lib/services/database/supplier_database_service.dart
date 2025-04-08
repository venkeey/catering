import 'package:flutter/foundation.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for supplier-related database operations
class SupplierDatabaseService {
  final BaseDatabaseService _baseService;

  SupplierDatabaseService(this._baseService);

  /// Get all suppliers from the database
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM suppliers');
      
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return {
          'id': DatabaseHelper.stringValue(fields['supplier_id']),
          'name': fields['name'],
          'contactPerson': fields['contact_person'],
          'phone': fields['phone'],
          'email': fields['email'],
          'address': fields['address'],
          'notes': fields['notes'],
          'createdAt': fields['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting suppliers: $e');
      rethrow;
    }
  }

  /// Get a specific supplier by ID
  Future<Map<String, dynamic>?> getSupplier(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM suppliers WHERE supplier_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return {
        'id': DatabaseHelper.stringValue(fields['supplier_id']),
        'name': fields['name'],
        'contactPerson': fields['contact_person'],
        'phone': fields['phone'],
        'email': fields['email'],
        'address': fields['address'],
        'notes': fields['notes'],
        'createdAt': fields['created_at'],
      };
    } catch (e) {
      debugPrint('Error getting supplier: $e');
      rethrow;
    }
  }

  /// Add a new supplier to the database
  Future<String> addSupplier(Map<String, dynamic> supplier) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO suppliers (
          name, contact_person, phone, email, address, notes
        ) VALUES (
          :name, :contactPerson, :phone, :email, :address, :notes
        )''',
        {
          'name': supplier['name'],
          'contactPerson': supplier['contactPerson'],
          'phone': supplier['phone'],
          'email': supplier['email'],
          'address': supplier['address'],
          'notes': supplier['notes'],
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      rethrow;
    }
  }

  /// Update an existing supplier in the database
  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE suppliers SET
          name = :name,
          contact_person = :contactPerson,
          phone = :phone,
          email = :email,
          address = :address,
          notes = :notes
          WHERE supplier_id = :id
        ''',
        {
          'name': supplier['name'],
          'contactPerson': supplier['contactPerson'],
          'phone': supplier['phone'],
          'email': supplier['email'],
          'address': supplier['address'],
          'notes': supplier['notes'],
          'id': supplier['id'],
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No supplier updated with ID: ${supplier['id']}');
      }
    } catch (e) {
      debugPrint('Error updating supplier: $e');
      rethrow;
    }
  }

  /// Delete a supplier from the database
  Future<void> deleteSupplier(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM suppliers WHERE supplier_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No supplier deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      rethrow;
    }
  }
}