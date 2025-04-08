import 'package:flutter/foundation.dart';
import '../../models/client.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for client-related database operations
class ClientDatabaseService {
  final BaseDatabaseService _baseService;

  ClientDatabaseService(this._baseService);

  /// Get all clients from the database
  Future<List<Client>> getClients() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM clients');
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return Client(
          id: DatabaseHelper.stringValue(fields['client_id']),
          clientName: fields['client_name'] as String? ?? '',
          contactPerson: fields['contact_person'] as String?,
          phone1: fields['phone1'] as String?,
          phone2: fields['phone2'] as String?,
          email1: fields['email1'] as String?,
          email2: fields['email2'] as String?,
          billingAddress: fields['billing_address'] as String?,
          companyName: fields['company_name'] as String?,
          notes: fields['notes'] as String?,
          createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting clients: $e');
      rethrow;
    }
  }

  /// Get a specific client by ID
  Future<Client?> getClient(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM clients WHERE client_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return Client(
        id: DatabaseHelper.stringValue(fields['client_id']),
        clientName: fields['client_name'] as String? ?? '',
        contactPerson: fields['contact_person'] as String?,
        phone1: fields['phone1'] as String?,
        phone2: fields['phone2'] as String?,
        email1: fields['email1'] as String?,
        email2: fields['email2'] as String?,
        billingAddress: fields['billing_address'] as String?,
        companyName: fields['company_name'] as String?,
        notes: fields['notes'] as String?,
        createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
      );
    } catch (e) {
      debugPrint('Error getting client: $e');
      rethrow;
    }
  }

  /// Add a new client to the database
  Future<String> addClient(Client client) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO clients (
          client_name, contact_person, phone1, phone2, email1, email2,
          billing_address, company_name, notes
        ) VALUES (
          :name, :contact, :phone1, :phone2, :email1, :email2,
          :address, :company, :notes
        )''',
        {
          'name': client.clientName,
          'contact': client.contactPerson,
          'phone1': client.phone1,
          'phone2': client.phone2,
          'email1': client.email1,
          'email2': client.email2,
          'address': client.billingAddress,
          'company': client.companyName,
          'notes': client.notes,
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  /// Update an existing client in the database
  Future<void> updateClient(Client client) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE clients SET
          client_name = :name,
          contact_person = :contact,
          phone1 = :phone1,
          phone2 = :phone2,
          email1 = :email1,
          email2 = :email2,
          billing_address = :address,
          company_name = :company,
          notes = :notes
          WHERE client_id = :id
        ''',
        {
          'name': client.clientName,
          'contact': client.contactPerson,
          'phone1': client.phone1,
          'phone2': client.phone2,
          'email1': client.email1,
          'email2': client.email2,
          'address': client.billingAddress,
          'company': client.companyName,
          'notes': client.notes,
          'id': client.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No client updated with ID: ${client.id}');
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  /// Delete a client from the database
  Future<void> deleteClient(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM clients WHERE client_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No client deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }
}