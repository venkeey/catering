import 'package:flutter/foundation.dart';
import '../../models/event.dart';
import '../../utils/database_helper.dart';
import 'base_database_service.dart';

/// Service for event-related database operations
class EventDatabaseService {
  final BaseDatabaseService _baseService;

  EventDatabaseService(this._baseService);

  /// Get all events from the database
  Future<List<Event>> getEvents() async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery('SELECT * FROM events');
      
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        
        return Event(
          id: DatabaseHelper.stringValue(fields['event_id']),
          clientId: DatabaseHelper.stringValue(fields['client_id']) ?? '',
          eventName: fields['event_name'] as String? ?? '',
          eventDate: DatabaseHelper.dateTimeValue(fields['event_date']),
          venueAddress: fields['venue_address'] as String?,
          eventType: fields['event_type'] as String?,
          totalGuestCount: DatabaseHelper.intValue(fields['total_guest_count']) ?? 0,
          guestsMale: DatabaseHelper.intValue(fields['guests_male']) ?? 0,
          guestsFemale: DatabaseHelper.intValue(fields['guests_female']) ?? 0,
          guestsElderly: DatabaseHelper.intValue(fields['guests_elderly']) ?? 0,
          guestsYouth: DatabaseHelper.intValue(fields['guests_youth']) ?? 0,
          guestsChild: DatabaseHelper.intValue(fields['guests_child']) ?? 0,
          status: fields['status'] as String? ?? 'Planning',
          notes: fields['notes'] as String?,
          createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting events: $e');
      rethrow;
    }
  }

  /// Get a specific event by ID
  Future<Event?> getEvent(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _baseService.executeQuery(
        'SELECT * FROM events WHERE event_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;
      
      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      return Event(
        id: DatabaseHelper.stringValue(fields['event_id']),
        clientId: DatabaseHelper.stringValue(fields['client_id']) ?? '',
        eventName: fields['event_name'] as String? ?? '',
        eventDate: DatabaseHelper.dateTimeValue(fields['event_date']),
        venueAddress: fields['venue_address'] as String?,
        eventType: fields['event_type'] as String?,
        totalGuestCount: DatabaseHelper.intValue(fields['total_guest_count']) ?? 0,
        guestsMale: DatabaseHelper.intValue(fields['guests_male']) ?? 0,
        guestsFemale: DatabaseHelper.intValue(fields['guests_female']) ?? 0,
        guestsElderly: DatabaseHelper.intValue(fields['guests_elderly']) ?? 0,
        guestsYouth: DatabaseHelper.intValue(fields['guests_youth']) ?? 0,
        guestsChild: DatabaseHelper.intValue(fields['guests_child']) ?? 0,
        status: fields['status'] as String? ?? 'Planning',
        notes: fields['notes'] as String?,
        createdAt: DatabaseHelper.dateTimeValue(fields['created_at']),
      );
    } catch (e) {
      debugPrint('Error getting event: $e');
      rethrow;
    }
  }

  /// Add a new event to the database
  Future<String> addEvent(Event event) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''INSERT INTO events (
          client_id, event_name, event_date, venue_address, event_type,
          total_guest_count, guests_male, guests_female, guests_elderly,
          guests_youth, guests_child, status, notes
        ) VALUES (
          :clientId, :eventName, :eventDate, :venueAddress, :eventType,
          :totalGuestCount, :guestsMale, :guestsFemale, :guestsElderly,
          :guestsYouth, :guestsChild, :status, :notes
        )''',
        {
          'clientId': event.clientId,
          'eventName': event.eventName,
          'eventDate': event.eventDate?.toIso8601String(),
          'venueAddress': event.venueAddress,
          'eventType': event.eventType,
          'totalGuestCount': event.totalGuestCount,
          'guestsMale': event.guestsMale,
          'guestsFemale': event.guestsFemale,
          'guestsElderly': event.guestsElderly,
          'guestsYouth': event.guestsYouth,
          'guestsChild': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
        }
      );

      final insertId = result.lastInsertID.toString();
      return insertId;
    } catch (e) {
      debugPrint('Error adding event: $e');
      rethrow;
    }
  }

  /// Update an existing event in the database
  Future<void> updateEvent(Event event) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        '''UPDATE events SET 
          client_id = :clientId,
          event_name = :eventName,
          event_date = :eventDate,
          venue_address = :venueAddress,
          event_type = :eventType,
          total_guest_count = :totalGuestCount,
          guests_male = :guestsMale,
          guests_female = :guestsFemale,
          guests_elderly = :guestsElderly,
          guests_youth = :guestsYouth,
          guests_child = :guestsChild,
          status = :status,
          notes = :notes
          WHERE event_id = :id
        ''',
        {
          'clientId': event.clientId,
          'eventName': event.eventName,
          'eventDate': event.eventDate?.toIso8601String(),
          'venueAddress': event.venueAddress,
          'eventType': event.eventType,
          'totalGuestCount': event.totalGuestCount,
          'guestsMale': event.guestsMale,
          'guestsFemale': event.guestsFemale,
          'guestsElderly': event.guestsElderly,
          'guestsYouth': event.guestsYouth,
          'guestsChild': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
          'id': event.id,
        }
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No event updated with ID: ${event.id}');
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  /// Delete an event from the database
  Future<void> deleteEvent(String id) async {
    if (!_baseService.isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _baseService.executeQuery(
        'DELETE FROM events WHERE event_id = :id',
        {'id': id}
      );

      if (result.affectedRows.toInt() <= 0) {
        throw Exception('No event deleted with ID: $id');
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }
}