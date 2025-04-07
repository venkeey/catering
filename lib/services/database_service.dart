import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/dish.dart';
import '../models/event.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/menu_package.dart';
import '../models/package_item.dart';
import '../models/inventory_item.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../utils/database_helper.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  MySQLConnection? _connection;
  bool _isConnected = false;
  
  // Connection settings
  String _host = 'localhost';
  int _port = 3306;
  String _user = 'root';
  String _password = '';
  String _db = 'catererer';

  // Getters
  bool get isConnected => _isConnected;
  String get host => _host;
  int get port => _port;
  String get user => _user;
  String get password => _password;
  String get db => _db;

  // Initialize connection settings from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('db_host') ?? 'localhost';
    _port = prefs.getInt('db_port') ?? 3306;
    _user = prefs.getString('db_user') ?? 'root';
    _password = prefs.getString('db_password') ?? '';
    _db = prefs.getString('db_name') ?? 'catererer';
  }

  // Connect to MySQL database
  Future<bool> connect() async {
    if (_isConnected) return true;

    try {
      debugPrint('Connecting to MySQL database...');
      debugPrint('Host: $_host');
      debugPrint('Port: $_port');
      debugPrint('User: $_user');
      debugPrint('Database: $_db');
      
      _connection = await MySQLConnection.createConnection(
        host: _host,
        port: _port,
        userName: _user,
        password: _password,
        databaseName: _db,
      );
      
      await _connection!.connect();
      _isConnected = true;
      debugPrint('Successfully connected to MySQL database');
      return true;
    } catch (e) {
      debugPrint('Error connecting to MySQL database: $e');
      _isConnected = false;
      return false;
    }
  }

  // Test connection without storing it
  Future<bool> testConnection({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String db,
  }) async {
    try {
      debugPrint('Testing MySQL connection...');
      debugPrint('Host: $host');
      debugPrint('Port: $port');
      debugPrint('User: $userName');
      debugPrint('Database: $db');
      
      final conn = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: db,
      );
      
      await conn.connect();
      await conn.close();
      debugPrint('Test connection successful');
      return true;
    } catch (e) {
      debugPrint('Error testing MySQL connection: $e');
      return false;
    }
  }

  // Disconnect from database
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _isConnected = false;
      debugPrint('Disconnected from MySQL database');
    }
  }

  // Update connection settings
  Future<bool> updateConnectionSettings({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String db,
  }) async {
    try {
      // Test the new connection settings
      final success = await testConnection(
        host: host,
        port: port,
        userName: userName,
        password: password,
        db: db,
      );

      if (!success) {
        return false;
      }

      // If test successful, update the settings
      _host = host;
      _port = port;
      _user = userName;
      _password = password;
      _db = db;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('db_host', host);
      await prefs.setInt('db_port', port);
      await prefs.setString('db_user', userName);
      await prefs.setString('db_password', password);
      await prefs.setString('db_name', db);

      // Reconnect with new settings
      await disconnect();
      return await connect();
    } catch (e) {
      debugPrint('Error updating connection settings: $e');
      return false;
    }
  }

  // Helper method to execute a query with parameters
  Future<IResultSet> executeQuery(String query, [Map<String, dynamic>? params]) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      if (params != null) {
        return await _connection!.execute(query, params);
      } else {
        return await _connection!.execute(query);
      }
    } catch (e) {
      debugPrint('Error executing query: $e');
      rethrow;
    }
  }

  // Helper method to convert parameters to the correct format
  Map<String, dynamic> _prepareParams(List<dynamic> params) {
    final Map<String, dynamic> namedParams = {};
    for (var i = 0; i < params.length; i++) {
      namedParams['p$i'] = params[i];
    }
    return namedParams;
  }

  // Helper method to replace ? placeholders with named parameters
  String _replacePlaceholders(String query) {
    var index = 0;
    return query.replaceAllMapped(RegExp(r'\?'), (match) {
      return ':p${index++}';
    });
  }

  // Client-related methods
  Future<List<Client>> getClients() async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute('SELECT * FROM clients');
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return Client.fromMap(fields);
      }).toList();
    } catch (e) {
      debugPrint('Error getting clients: $e');
      rethrow;
    }
  }

  Future<Client?> getClient(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM clients WHERE client_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return Client.fromMap(fields);
    } catch (e) {
      debugPrint('Error getting client: $e');
      rethrow;
    }
  }

  Future<String> addClient(Client client) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
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

      final insertId = result.rows.first.typedColAt<int>(0);
      return insertId.toString();
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<bool> updateClient(Client client) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
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

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error updating client: $e');
      return false;
    }
  }

  Future<bool> deleteClient(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        'DELETE FROM clients WHERE client_id = :id',
        {'id': id}
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error deleting client: $e');
      return false;
    }
  }

  // Event operations
  Future<List<Event>> getEventsByClient(String clientId) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM events WHERE client_id = :clientId',
        {'clientId': clientId}
      );

      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return Event.fromMap(fields);
      }).toList();
    } catch (e) {
      debugPrint('Error getting events: $e');
      rethrow;
    }
  }

  Future<Event?> getEvent(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM events WHERE event_id = :id',
        {'id': id}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return Event.fromMap(fields);
    } catch (e) {
      debugPrint('Error getting event: $e');
      rethrow;
    }
  }

  Future<String> addEvent(Event event) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''INSERT INTO events (
          client_id, event_name, event_date, venue_address, event_type,
          total_guest_count, guests_male, guests_female, guests_elderly,
          guests_youth, guests_child, status, notes
        ) VALUES (
          :clientId, :name, :date, :venue, :type,
          :totalGuests, :maleGuests, :femaleGuests, :elderlyGuests,
          :youthGuests, :childGuests, :status, :notes
        )''',
        {
          'clientId': event.clientId,
          'name': event.eventName,
          'date': event.eventDate?.toIso8601String(),
          'venue': event.venueAddress,
          'type': event.eventType,
          'totalGuests': event.totalGuestCount,
          'maleGuests': event.guestsMale,
          'femaleGuests': event.guestsFemale,
          'elderlyGuests': event.guestsElderly,
          'youthGuests': event.guestsYouth,
          'childGuests': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
        }
      );

      final insertId = result.rows.first.typedColAt<int>(0);
      return insertId.toString();
    } catch (e) {
      debugPrint('Error adding event: $e');
      rethrow;
    }
  }

  Future<bool> updateEvent(Event event) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''UPDATE events SET 
          client_id = :clientId,
          event_name = :name,
          event_date = :date,
          venue_address = :venue,
          event_type = :type,
          total_guest_count = :totalGuests,
          guests_male = :maleGuests,
          guests_female = :femaleGuests,
          guests_elderly = :elderlyGuests,
          guests_youth = :youthGuests,
          guests_child = :childGuests,
          status = :status,
          notes = :notes
          WHERE event_id = :id
        ''',
        {
          'clientId': event.clientId,
          'name': event.eventName,
          'date': event.eventDate?.toIso8601String(),
          'venue': event.venueAddress,
          'type': event.eventType,
          'totalGuests': event.totalGuestCount,
          'maleGuests': event.guestsMale,
          'femaleGuests': event.guestsFemale,
          'elderlyGuests': event.guestsElderly,
          'youthGuests': event.guestsYouth,
          'childGuests': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
          'id': event.id,
        }
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        'DELETE FROM events WHERE event_id = :id',
        {'id': id}
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // Quote operations
  Future<List<Quote>> getQuotesByClient(String clientId) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM quotes WHERE client_id = :clientId',
        {'clientId': BigInt.parse(clientId)}
      );

      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        
        // Get quote items
        final quoteItems = await _connection!.execute(
          'SELECT * FROM quote_items WHERE quote_id = :quoteId',
          {'quoteId': fields['quote_id']}
        );

        final items = await Future.wait(quoteItems.rows.map((item) async {
          final itemFields = DatabaseHelper.rowToMap(item.assoc());
          final dish = await getDish(DatabaseHelper.stringValue(itemFields['dish_id']));
          return QuoteItem.fromMap({
            'id': DatabaseHelper.stringValue(itemFields['quote_item_id']),
            'quoteId': DatabaseHelper.stringValue(itemFields['quote_id']),
            'dishId': DatabaseHelper.stringValue(itemFields['dish_id']),
            'quotedPortionSizeGrams': DatabaseHelper.doubleValue(itemFields['quoted_portion_size']),
            'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(itemFields['quoted_base_food_cost']),
            'percentageTakeRate': DatabaseHelper.doubleValue(itemFields['percentage_take_rate']),
            'estimatedServings': DatabaseHelper.intValue(itemFields['estimated_servings']),
            'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(itemFields['estimated_total_weight']),
            'estimatedItemFoodCost': DatabaseHelper.doubleValue(itemFields['estimated_item_food_cost']),
            'dish': dish.toMap(),
          });
        }));

        return Quote.fromMap({
          'id': DatabaseHelper.stringValue(fields['quote_id']),
          'eventId': DatabaseHelper.stringValue(fields['event_id']),
          'clientId': DatabaseHelper.stringValue(fields['client_id']),
          'quoteDate': DatabaseHelper.dateTimeValue(fields['quote_date'])?.toIso8601String(),
          'totalGuestCount': DatabaseHelper.intValue(fields['total_guest_count']),
          'guestsMale': DatabaseHelper.intValue(fields['guests_male']),
          'guestsFemale': DatabaseHelper.intValue(fields['guests_female']),
          'guestsElderly': DatabaseHelper.intValue(fields['guests_elderly']),
          'guestsYouth': DatabaseHelper.intValue(fields['guests_youth']),
          'guestsChild': DatabaseHelper.intValue(fields['guests_child']),
          'calculationMethod': fields['calculation_method'] ?? 'Standard',
          'overheadPercentage': DatabaseHelper.doubleValue(fields['overhead_percentage']),
          'calculatedTotalFoodCost': DatabaseHelper.doubleValue(fields['calculated_total_food_cost']),
          'calculatedOverheadCost': DatabaseHelper.doubleValue(fields['calculated_overhead_cost']),
          'grandTotal': DatabaseHelper.doubleValue(fields['grand_total']),
          'notes': fields['notes'],
          'termsAndConditions': fields['terms_and_conditions'],
          'status': fields['status'] ?? 'Draft',
          'items': items,
        });
      }));
    } catch (e) {
      debugPrint('Error getting quotes: $e');
      rethrow;
    }
  }

  Future<List<Quote>> getQuotesByEvent(String eventId) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM quotes WHERE event_id = :eventId',
        {'eventId': BigInt.parse(eventId)}
      );

      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        
        // Get quote items
        final quoteItems = await _connection!.execute(
          'SELECT * FROM quote_items WHERE quote_id = :quoteId',
          {'quoteId': fields['quote_id']}
        );

        final items = await Future.wait(quoteItems.rows.map((item) async {
          final itemFields = DatabaseHelper.rowToMap(item.assoc());
          final dish = await getDish(DatabaseHelper.stringValue(itemFields['dish_id']));
          return QuoteItem.fromMap({
            'id': DatabaseHelper.stringValue(itemFields['quote_item_id']),
            'quoteId': DatabaseHelper.stringValue(itemFields['quote_id']),
            'dishId': DatabaseHelper.stringValue(itemFields['dish_id']),
            'quotedPortionSizeGrams': DatabaseHelper.doubleValue(itemFields['quoted_portion_size']),
            'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(itemFields['quoted_base_food_cost']),
            'percentageTakeRate': DatabaseHelper.doubleValue(itemFields['percentage_take_rate']),
            'estimatedServings': DatabaseHelper.intValue(itemFields['estimated_servings']),
            'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(itemFields['estimated_total_weight']),
            'estimatedItemFoodCost': DatabaseHelper.doubleValue(itemFields['estimated_item_food_cost']),
            'dish': dish.toMap(),
          });
        }));

        return Quote.fromMap({
          'id': DatabaseHelper.stringValue(fields['quote_id']),
          'eventId': DatabaseHelper.stringValue(fields['event_id']),
          'clientId': DatabaseHelper.stringValue(fields['client_id']),
          'quoteDate': DatabaseHelper.dateTimeValue(fields['quote_date'])?.toIso8601String(),
          'totalGuestCount': DatabaseHelper.intValue(fields['total_guest_count']),
          'guestsMale': DatabaseHelper.intValue(fields['guests_male']),
          'guestsFemale': DatabaseHelper.intValue(fields['guests_female']),
          'guestsElderly': DatabaseHelper.intValue(fields['guests_elderly']),
          'guestsYouth': DatabaseHelper.intValue(fields['guests_youth']),
          'guestsChild': DatabaseHelper.intValue(fields['guests_child']),
          'calculationMethod': fields['calculation_method'] ?? 'Standard',
          'overheadPercentage': DatabaseHelper.doubleValue(fields['overhead_percentage']),
          'calculatedTotalFoodCost': DatabaseHelper.doubleValue(fields['calculated_total_food_cost']),
          'calculatedOverheadCost': DatabaseHelper.doubleValue(fields['calculated_overhead_cost']),
          'grandTotal': DatabaseHelper.doubleValue(fields['grand_total']),
          'notes': fields['notes'],
          'termsAndConditions': fields['terms_and_conditions'],
          'status': fields['status'] ?? 'Draft',
          'items': items,
        });
      }));
    } catch (e) {
      debugPrint('Error getting quotes: $e');
      rethrow;
    }
  }

  Future<Quote?> getQuote(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM quotes WHERE quote_id = :id',
        {'id': BigInt.parse(id)}
      );

      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      
      // Get quote items
      final quoteItems = await _connection!.execute(
        'SELECT * FROM quote_items WHERE quote_id = :quoteId',
        {'quoteId': fields['quote_id']}
      );

      final items = await Future.wait(quoteItems.rows.map((item) async {
        final itemFields = DatabaseHelper.rowToMap(item.assoc());
        final dish = await getDish(DatabaseHelper.stringValue(itemFields['dish_id']));
        return QuoteItem.fromMap({
          'id': DatabaseHelper.stringValue(itemFields['quote_item_id']),
          'quoteId': DatabaseHelper.stringValue(itemFields['quote_id']),
          'dishId': DatabaseHelper.stringValue(itemFields['dish_id']),
          'quotedPortionSizeGrams': DatabaseHelper.doubleValue(itemFields['quoted_portion_size']),
          'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(itemFields['quoted_base_food_cost']),
          'percentageTakeRate': DatabaseHelper.doubleValue(itemFields['percentage_take_rate']),
          'estimatedServings': DatabaseHelper.intValue(itemFields['estimated_servings']),
          'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(itemFields['estimated_total_weight']),
          'estimatedItemFoodCost': DatabaseHelper.doubleValue(itemFields['estimated_item_food_cost']),
          'dish': dish.toMap(),
        });
      }));

      return Quote.fromMap({
        'id': DatabaseHelper.stringValue(fields['quote_id']),
        'eventId': DatabaseHelper.stringValue(fields['event_id']),
        'clientId': DatabaseHelper.stringValue(fields['client_id']),
        'quoteDate': DatabaseHelper.dateTimeValue(fields['quote_date'])?.toIso8601String(),
        'totalGuestCount': DatabaseHelper.intValue(fields['total_guest_count']),
        'guestsMale': DatabaseHelper.intValue(fields['guests_male']),
        'guestsFemale': DatabaseHelper.intValue(fields['guests_female']),
        'guestsElderly': DatabaseHelper.intValue(fields['guests_elderly']),
        'guestsYouth': DatabaseHelper.intValue(fields['guests_youth']),
        'guestsChild': DatabaseHelper.intValue(fields['guests_child']),
        'calculationMethod': fields['calculation_method'] ?? 'Standard',
        'overheadPercentage': DatabaseHelper.doubleValue(fields['overhead_percentage']),
        'calculatedTotalFoodCost': DatabaseHelper.doubleValue(fields['calculated_total_food_cost']),
        'calculatedOverheadCost': DatabaseHelper.doubleValue(fields['calculated_overhead_cost']),
        'grandTotal': DatabaseHelper.doubleValue(fields['grand_total']),
        'notes': fields['notes'],
        'termsAndConditions': fields['terms_and_conditions'],
        'status': fields['status'] ?? 'Draft',
        'items': items,
      });
    } catch (e) {
      debugPrint('Error getting quote: $e');
      rethrow;
    }
  }

  Future<String> addQuote(Quote quote) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''INSERT INTO quotes (
          event_id, client_id, quote_date, total_guest_count,
          guests_male, guests_female, guests_elderly,
          guests_youth, guests_child, calculation_method,
          overhead_percentage, calculated_total_food_cost,
          calculated_overhead_cost, grand_total, notes,
          terms_and_conditions, status
        ) VALUES (
          :eventId, :clientId, :quoteDate, :totalGuestCount,
          :guestsMale, :guestsFemale, :guestsElderly,
          :guestsYouth, :guestsChild, :calculationMethod,
          :overheadPercentage, :calculatedTotalFoodCost,
          :calculatedOverheadCost, :grandTotal, :notes,
          :termsAndConditions, :status
        )''',
        {
          'eventId': quote.eventId != null ? BigInt.parse(quote.eventId!) : null,
          'clientId': BigInt.parse(quote.clientId),
          'quoteDate': quote.quoteDate.toIso8601String(),
          'totalGuestCount': quote.totalGuestCount,
          'guestsMale': quote.guestsMale,
          'guestsFemale': quote.guestsFemale,
          'guestsElderly': quote.guestsElderly,
          'guestsYouth': quote.guestsYouth,
          'guestsChild': quote.guestsChild,
          'calculationMethod': quote.calculationMethod,
          'overheadPercentage': quote.overheadPercentage,
          'calculatedTotalFoodCost': quote.calculatedTotalFoodCost,
          'calculatedOverheadCost': quote.calculatedOverheadCost,
          'grandTotal': quote.grandTotal,
          'notes': quote.notes,
          'termsAndConditions': quote.termsAndConditions,
          'status': quote.status,
        }
      );

      final insertId = result.rows.first.typedColAt<int>(0);
      return insertId.toString();
    } catch (e) {
      debugPrint('Error adding quote: $e');
      rethrow;
    }
  }

  Future<bool> updateQuote(Quote quote) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''UPDATE quotes SET
          event_id = :eventId,
          client_id = :clientId,
          quote_date = :quoteDate,
          total_guest_count = :totalGuestCount,
          guests_male = :guestsMale,
          guests_female = :guestsFemale,
          guests_elderly = :guestsElderly,
          guests_youth = :guestsYouth,
          guests_child = :guestsChild,
          calculation_method = :calculationMethod,
          overhead_percentage = :overheadPercentage,
          calculated_total_food_cost = :calculatedTotalFoodCost,
          calculated_overhead_cost = :calculatedOverheadCost,
          grand_total = :grandTotal,
          notes = :notes,
          terms_and_conditions = :termsAndConditions,
          status = :status
          WHERE quote_id = :id
        ''',
        {
          'eventId': quote.eventId != null ? BigInt.parse(quote.eventId!) : null,
          'clientId': BigInt.parse(quote.clientId),
          'quoteDate': quote.quoteDate.toIso8601String(),
          'totalGuestCount': quote.totalGuestCount,
          'guestsMale': quote.guestsMale,
          'guestsFemale': quote.guestsFemale,
          'guestsElderly': quote.guestsElderly,
          'guestsYouth': quote.guestsYouth,
          'guestsChild': quote.guestsChild,
          'calculationMethod': quote.calculationMethod,
          'overheadPercentage': quote.overheadPercentage,
          'calculatedTotalFoodCost': quote.calculatedTotalFoodCost,
          'calculatedOverheadCost': quote.calculatedOverheadCost,
          'grandTotal': quote.grandTotal,
          'notes': quote.notes,
          'termsAndConditions': quote.termsAndConditions,
          'status': quote.status,
          'id': BigInt.parse(quote.id),
        }
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error updating quote: $e');
      return false;
    }
  }

  Future<bool> deleteQuote(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        'DELETE FROM quotes WHERE quote_id = :id',
        {'id': BigInt.parse(id)}
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      return false;
    }
  }

  // Quote Item operations
  Future<List<QuoteItem>> getQuoteItems() async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute('SELECT * FROM quote_items');
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await getDish(DatabaseHelper.stringValue(fields['dish_id']));
        return QuoteItem.fromMap({
          'id': DatabaseHelper.stringValue(fields['quote_item_id']),
          'quoteId': DatabaseHelper.stringValue(fields['quote_id']),
          'dishId': DatabaseHelper.stringValue(fields['dish_id']),
          'quotedPortionSizeGrams': DatabaseHelper.doubleValue(fields['quoted_portion_size']),
          'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(fields['quoted_base_food_cost']),
          'percentageTakeRate': DatabaseHelper.doubleValue(fields['percentage_take_rate']),
          'estimatedServings': DatabaseHelper.intValue(fields['estimated_servings']),
          'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(fields['estimated_total_weight']),
          'estimatedItemFoodCost': DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
          'dish': dish.toMap(),
        });
      }));
    } catch (e) {
      debugPrint('Error getting quote items: $e');
      rethrow;
    }
  }

  Future<List<QuoteItem>> getQuoteItemsByQuoteId(String quoteId) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(
        'SELECT * FROM quote_items WHERE quote_id = :quoteId',
        {'quoteId': BigInt.parse(quoteId)}
      );
    
      return Future.wait(results.rows.map((row) async {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        final dish = await getDish(DatabaseHelper.stringValue(fields['dish_id']));
        return QuoteItem.fromMap({
          'id': DatabaseHelper.stringValue(fields['quote_item_id']),
          'quoteId': DatabaseHelper.stringValue(fields['quote_id']),
          'dishId': DatabaseHelper.stringValue(fields['dish_id']),
          'quotedPortionSizeGrams': DatabaseHelper.doubleValue(fields['quoted_portion_size']),
          'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(fields['quoted_base_food_cost']),
          'percentageTakeRate': DatabaseHelper.doubleValue(fields['percentage_take_rate']),
          'estimatedServings': DatabaseHelper.intValue(fields['estimated_servings']),
          'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(fields['estimated_total_weight']),
          'estimatedItemFoodCost': DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
          'dish': dish.toMap(),
        });
      }));
    } catch (e) {
      debugPrint('Error getting quote items: $e');
      rethrow;
    }
  }

  Future<QuoteItem?> getQuoteItemById(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      final results = await _connection!.execute(
        'SELECT * FROM quote_items WHERE quote_item_id = :id',
        {'id': BigInt.parse(id)}
      );
    
      if (results.rows.isEmpty) return null;

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      final dish = await getDish(DatabaseHelper.stringValue(fields['dish_id']));
      return QuoteItem.fromMap({
        'id': DatabaseHelper.stringValue(fields['quote_item_id']),
        'quoteId': DatabaseHelper.stringValue(fields['quote_id']),
        'dishId': DatabaseHelper.stringValue(fields['dish_id']),
        'quotedPortionSizeGrams': DatabaseHelper.doubleValue(fields['quoted_portion_size']),
        'quotedBaseFoodCostPerServing': DatabaseHelper.doubleValue(fields['quoted_base_food_cost']),
        'percentageTakeRate': DatabaseHelper.doubleValue(fields['percentage_take_rate']),
        'estimatedServings': DatabaseHelper.intValue(fields['estimated_servings']),
        'estimatedTotalWeightGrams': DatabaseHelper.doubleValue(fields['estimated_total_weight']),
        'estimatedItemFoodCost': DatabaseHelper.doubleValue(fields['estimated_item_food_cost']),
        'dish': dish.toMap(),
      });
    } catch (e) {
      debugPrint('Error getting quote item: $e');
      rethrow;
    }
  }

  Future<String> addQuoteItem(QuoteItem item) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      final result = await _connection!.execute(
        '''INSERT INTO quote_items (
          quote_id, dish_id, quoted_portion_size,
          quoted_base_food_cost, percentage_take_rate,
          estimated_servings, estimated_total_weight,
          estimated_item_food_cost
        ) VALUES (
          :quoteId, :dishId, :portionSize,
          :baseCost, :takeRate,
          :servings, :totalWeight,
          :itemCost
        )''',
        {
          'quoteId': BigInt.parse(item.quoteId),
          'dishId': BigInt.parse(item.dishId),
          'portionSize': item.quotedPortionSizeGrams,
          'baseCost': item.quotedBaseFoodCostPerServing,
          'takeRate': item.percentageTakeRate,
          'servings': item.estimatedServings,
          'totalWeight': item.estimatedTotalWeightGrams,
          'itemCost': item.estimatedItemFoodCost,
        }
      );

      final insertId = result.rows.first.typedColAt<int>(0);
      return insertId.toString();
    } catch (e) {
      debugPrint('Error adding quote item: $e');
      rethrow;
    }
  }

  Future<bool> updateQuoteItem(QuoteItem item) async {
    if (!_isConnected || item.id == null) {
      throw Exception('Database not connected or item ID is null');
    }
    
    try {
      final result = await _connection!.execute(
        '''UPDATE quote_items SET
          quote_id = :quoteId,
          dish_id = :dishId,
          quoted_portion_size = :portionSize,
          quoted_base_food_cost = :baseCost,
          percentage_take_rate = :takeRate,
          estimated_servings = :servings,
          estimated_total_weight = :totalWeight,
          estimated_item_food_cost = :itemCost
          WHERE quote_item_id = :id
        ''',
        {
          'quoteId': BigInt.parse(item.quoteId),
          'dishId': BigInt.parse(item.dishId),
          'portionSize': item.quotedPortionSizeGrams,
          'baseCost': item.quotedBaseFoodCostPerServing,
          'takeRate': item.percentageTakeRate,
          'servings': item.estimatedServings,
          'totalWeight': item.estimatedTotalWeightGrams,
          'itemCost': item.estimatedItemFoodCost,
          'id': BigInt.parse(item.id!),
        }
      );
      
      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error updating quote item: $e');
      return false;
    }
  }

  Future<bool> deleteQuoteItem(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      final result = await _connection!.execute(
        'DELETE FROM quote_items WHERE quote_item_id = :id',
        {'id': BigInt.parse(id)}
      );
    
      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error deleting quote item: $e');
      return false;
    }
  }

  // Dish operations
  Future<List<Dish>> getDishes() async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute('SELECT * FROM dishes');
      return results.rows.map((row) {
        final fields = DatabaseHelper.rowToMap(row.assoc());
        return Dish.fromMap({
          'id': DatabaseHelper.stringValue(fields['dish_id']),
          'name': fields['name'],
          'categoryId': DatabaseHelper.stringValue(fields['category_id']),
          'category': DatabaseHelper.stringValue(fields['category_id']), // TODO: Join with categories table
          'basePrice': DatabaseHelper.doubleValue(fields['base_food_cost'])! * 1.3, // 30% markup
          'baseFoodCost': DatabaseHelper.doubleValue(fields['base_food_cost']),
          'standardPortionSize': DatabaseHelper.doubleValue(fields['standard_portion_size_grams']),
          'description': fields['description'],
          'imageUrl': fields['image_url'],
          'dietaryTags': DatabaseHelper.stringListValue(fields['dietary_tags']),
          'itemType': fields['item_type'] ?? 'Standard',
          'isActive': DatabaseHelper.boolValue(fields['is_active']),
          'ingredients': {}, // TODO: Load from dish_ingredients table
          'createdAt': DatabaseHelper.stringValue(fields['created_at']),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error getting dishes: $e');
      rethrow;
    }
  }

  Future<Dish> getDish(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final results = await _connection!.execute(
        'SELECT * FROM dishes WHERE dish_id = :id',
        {'id': BigInt.parse(id)}
      );

      if (results.rows.isEmpty) {
        throw Exception('Dish not found');
      }

      final fields = DatabaseHelper.rowToMap(results.rows.first.assoc());
      return Dish.fromMap({
        'id': DatabaseHelper.stringValue(fields['dish_id']),
        'name': fields['name'],
        'categoryId': DatabaseHelper.stringValue(fields['category_id']),
        'category': DatabaseHelper.stringValue(fields['category_id']), // TODO: Join with categories table
        'basePrice': DatabaseHelper.doubleValue(fields['base_food_cost'])! * 1.3, // 30% markup
        'baseFoodCost': DatabaseHelper.doubleValue(fields['base_food_cost']),
        'standardPortionSize': DatabaseHelper.doubleValue(fields['standard_portion_size_grams']),
        'description': fields['description'],
        'imageUrl': fields['image_url'],
        'dietaryTags': DatabaseHelper.stringListValue(fields['dietary_tags']),
        'itemType': fields['item_type'] ?? 'Standard',
        'isActive': DatabaseHelper.boolValue(fields['is_active']),
        'ingredients': {}, // TODO: Load from dish_ingredients table
        'createdAt': DatabaseHelper.stringValue(fields['created_at']),
      });
    } catch (e) {
      debugPrint('Error getting dish: $e');
      rethrow;
    }
  }

  Future<String> insertDish(Dish dish) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''INSERT INTO dishes (
          name, category_id, description, standard_portion_size_grams,
          base_food_cost, image_url, dietary_tags, item_type, is_active
        ) VALUES (
          :name, :categoryId, :description, :portionSize,
          :baseCost, :imageUrl, :dietaryTags, :itemType, :isActive
        )''',
        {
          'name': dish.name,
          'categoryId': BigInt.parse(dish.categoryId),
          'description': dish.description,
          'portionSize': dish.standardPortionSize,
          'baseCost': dish.baseFoodCost,
          'imageUrl': dish.imageUrl,
          'dietaryTags': dish.dietaryTags.join(','),
          'itemType': dish.itemType,
          'isActive': dish.isActive ? 1 : 0,
        }
      );

      final insertId = result.rows.first.typedColAt<int>(0);
      return insertId.toString();
    } catch (e) {
      debugPrint('Error inserting dish: $e');
      rethrow;
    }
  }

  Future<bool> updateDish(Dish dish) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        '''UPDATE dishes SET
          name = :name,
          category_id = :categoryId,
          description = :description,
          standard_portion_size_grams = :portionSize,
          base_food_cost = :baseCost,
          image_url = :imageUrl,
          dietary_tags = :dietaryTags,
          item_type = :itemType,
          is_active = :isActive
          WHERE dish_id = :id
        ''',
        {
          'name': dish.name,
          'categoryId': BigInt.parse(dish.categoryId),
          'description': dish.description,
          'portionSize': dish.standardPortionSize,
          'baseCost': dish.baseFoodCost,
          'imageUrl': dish.imageUrl,
          'dietaryTags': dish.dietaryTags.join(','),
          'itemType': dish.itemType,
          'isActive': dish.isActive ? 1 : 0,
          'id': BigInt.parse(dish.id),
        }
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error updating dish: $e');
      return false;
    }
  }

  Future<bool> deleteDish(String id) async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }

    try {
      final result = await _connection!.execute(
        'DELETE FROM dishes WHERE dish_id = :id',
        {'id': BigInt.parse(id)}
      );

      return result.affectedRows! > 0;
    } catch (e) {
      debugPrint('Error deleting dish: $e');
      return false;
    }
  }

  // Menu Package Methods
  Future<List<MenuPackage>> getMenuPackages() async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute('SELECT * FROM menu_packages WHERE is_active = 1');
      return results.rows.map((row) => MenuPackage.fromMap(row.assoc())).toList();
    } catch (e) {
      throw Exception('Failed to get menu packages: $e');
    }
  }

  Future<MenuPackage> getMenuPackage(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM menu_packages WHERE package_id = ?',
        [id],
      );
      
      if (results.rows.isEmpty) {
        throw Exception('Menu package not found');
      }
      
      return MenuPackage.fromMap(results.rows.first.assoc());
    } catch (e) {
      throw Exception('Failed to get menu package: $e');
    }
  }

  Future<String> addMenuPackage(MenuPackage package) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final map = package.toMap();
      final id = map['id'] as String;
      
      await _connection!.execute(
        'INSERT INTO menu_packages (package_id, name, description, base_price, event_type, is_active, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          map['name'],
          map['description'],
          map['base_price'],
          map['event_type'],
          map['is_active'],
          map['created_at'],
        ],
      );
      
      return id;
    } catch (e) {
      throw Exception('Failed to add menu package: $e');
    }
  }

  Future<void> updateMenuPackage(MenuPackage package) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final map = package.toMap();
      
      await _connection!.execute(
        'UPDATE menu_packages SET name = ?, description = ?, base_price = ?, event_type = ?, is_active = ? WHERE package_id = ?',
        [
          map['name'],
          map['description'],
          map['base_price'],
          map['event_type'],
          map['is_active'],
          map['id'],
        ],
      );
    } catch (e) {
      throw Exception('Failed to update menu package: $e');
    }
  }

  Future<void> deleteMenuPackage(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'DELETE FROM menu_packages WHERE package_id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete menu package: $e');
    }
  }

  // Package Item Methods
  Future<List<PackageItem>> getPackageItems() async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute('SELECT * FROM package_items');
      return results.rows.map((row) {
        final dish = row['dish_id'] != null 
            ? Dish.fromMap(row.assoc()) 
            : null;
        return PackageItem.fromMap(row.assoc(), dish: dish);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get package items: $e');
    }
  }

  Future<PackageItem?> getPackageItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM package_items WHERE package_item_id = ?',
        [id],
      );

      if (results.rows.isEmpty) return null;

      final row = results.rows.first.assoc();
      final dish = row['dish_id'] != null 
          ? await getDish(row['dish_id'].toString())
          : null;
      return PackageItem.fromMap(row, dish: dish);
    } catch (e) {
      throw Exception('Failed to get package item: $e');
    }
  }

  Future<String> addPackageItem(PackageItem item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final map = item.toMap();
      final id = map['id'] as String;
      
      await _connection!.execute(
        'INSERT INTO package_items (package_item_id, package_id, dish_id, is_optional) VALUES (?, ?, ?, ?)',
        [
          id,
          map['package_id'],
          map['dish_id'],
          map['is_optional'],
        ],
      );
      
      return id;
    } catch (e) {
      throw Exception('Failed to add package item: $e');
    }
  }

  Future<void> updatePackageItem(PackageItem item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final map = item.toMap();
      
      await _connection!.execute(
        'UPDATE package_items SET package_id = ?, dish_id = ?, is_optional = ? WHERE package_item_id = ?',
        [
          map['package_id'],
          map['dish_id'],
          map['is_optional'],
          map['id'],
        ],
      );
    } catch (e) {
      throw Exception('Failed to update package item: $e');
    }
  }

  Future<void> deletePackageItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'DELETE FROM package_items WHERE package_item_id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete package item: $e');
    }
  }

  Future<void> deletePackageItems(String packageId) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'DELETE FROM package_items WHERE package_id = ?',
        [packageId],
      );
    } catch (e) {
      throw Exception('Failed to delete package items: $e');
    }
  }

  // Inventory Item Methods
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM inventory_items WHERE is_active = 1'
      );
      return results.rows.map((row) => row.assoc()).toList();
    } catch (e) {
      throw Exception('Failed to get inventory items: $e');
    }
  }

  Future<Map<String, dynamic>?> getInventoryItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM inventory_items WHERE id = ?',
        [id]
      );
      return results.rows.isNotEmpty ? results.rows.first.assoc() : null;
    } catch (e) {
      throw Exception('Failed to get inventory item: $e');
    }
  }

  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final result = await _connection!.execute(
        'INSERT INTO inventory_items (name, description, quantity, unit, cost_per_unit, supplier_id, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          item['name'],
          item['description'],
          item['quantity'],
          item['unit'],
          item['cost_per_unit'],
          item['supplier_id'],
          item['is_active'] ?? 1,
        ],
      );
      return result.insertId.toString();
    } catch (e) {
      throw Exception('Failed to add inventory item: $e');
    }
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE inventory_items SET name = ?, description = ?, quantity = ?, unit = ?, cost_per_unit = ?, supplier_id = ? WHERE id = ?',
        [
          item['name'],
          item['description'],
          item['quantity'],
          item['unit'],
          item['cost_per_unit'],
          item['supplier_id'],
          id,
        ],
      );
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE inventory_items SET is_active = 0 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  // Supplier Methods
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM suppliers WHERE is_active = 1'
      );
      return results.rows.map((row) => row.assoc()).toList();
    } catch (e) {
      throw Exception('Failed to get suppliers: $e');
    }
  }

  Future<Map<String, dynamic>?> getSupplier(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM suppliers WHERE id = ?',
        [id]
      );
      return results.rows.isNotEmpty ? results.rows.first.assoc() : null;
    } catch (e) {
      throw Exception('Failed to get supplier: $e');
    }
  }

  Future<String> addSupplier(Map<String, dynamic> supplier) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final result = await _connection!.execute(
        'INSERT INTO suppliers (name, contact_person, phone, email, address, is_active) VALUES (?, ?, ?, ?, ?, ?)',
        [
          supplier['name'],
          supplier['contact_person'],
          supplier['phone'],
          supplier['email'],
          supplier['address'],
          supplier['is_active'] ?? 1,
        ],
      );
      return result.insertId.toString();
    } catch (e) {
      throw Exception('Failed to add supplier: $e');
    }
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> supplier) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE suppliers SET name = ?, contact_person = ?, phone = ?, email = ?, address = ? WHERE id = ?',
        [
          supplier['name'],
          supplier['contact_person'],
          supplier['phone'],
          supplier['email'],
          supplier['address'],
          id,
        ],
      );
    } catch (e) {
      throw Exception('Failed to update supplier: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE suppliers SET is_active = 0 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }

  // Purchase Order Methods
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM purchase_orders WHERE is_active = 1'
      );
      return results.rows.map((row) => row.assoc()).toList();
    } catch (e) {
      throw Exception('Failed to get purchase orders: $e');
    }
  }

  Future<Map<String, dynamic>?> getPurchaseOrder(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM purchase_orders WHERE id = ?',
        [id]
      );
      return results.rows.isNotEmpty ? results.rows.first.assoc() : null;
    } catch (e) {
      throw Exception('Failed to get purchase order: $e');
    }
  }

  Future<String> addPurchaseOrder(Map<String, dynamic> order) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final result = await _connection!.execute(
        'INSERT INTO purchase_orders (supplier_id, order_date, status, total_amount, notes, is_active) VALUES (?, ?, ?, ?, ?, ?)',
        [
          order['supplier_id'],
          order['order_date'],
          order['status'],
          order['total_amount'],
          order['notes'],
          order['is_active'] ?? 1,
        ],
      );
      return result.insertId.toString();
    } catch (e) {
      throw Exception('Failed to add purchase order: $e');
    }
  }

  Future<void> updatePurchaseOrder(String id, Map<String, dynamic> order) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE purchase_orders SET supplier_id = ?, order_date = ?, status = ?, total_amount = ?, notes = ? WHERE id = ?',
        [
          order['supplier_id'],
          order['order_date'],
          order['status'],
          order['total_amount'],
          order['notes'],
          id,
        ],
      );
    } catch (e) {
      throw Exception('Failed to update purchase order: $e');
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE purchase_orders SET is_active = 0 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order: $e');
    }
  }

  // Purchase Order Item Methods
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String purchaseOrderId) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM purchase_order_items WHERE purchase_order_id = ? AND is_active = 1',
        [purchaseOrderId]
      );
      return results.rows.map((row) => row.assoc()).toList();
    } catch (e) {
      throw Exception('Failed to get purchase order items: $e');
    }
  }

  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final results = await _connection!.execute(
        'SELECT * FROM purchase_order_items WHERE id = ?',
        [id]
      );
      return results.rows.isNotEmpty ? results.rows.first.assoc() : null;
    } catch (e) {
      throw Exception('Failed to get purchase order item: $e');
    }
  }

  Future<String> addPurchaseOrderItem(Map<String, dynamic> item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      final result = await _connection!.execute(
        'INSERT INTO purchase_order_items (purchase_order_id, inventory_item_id, quantity, unit_price, total_price, is_active) VALUES (?, ?, ?, ?, ?, ?)',
        [
          item['purchase_order_id'],
          item['inventory_item_id'],
          item['quantity'],
          item['unit_price'],
          item['total_price'],
          item['is_active'] ?? 1,
        ],
      );
      return result.insertId.toString();
    } catch (e) {
      throw Exception('Failed to add purchase order item: $e');
    }
  }

  Future<void> updatePurchaseOrderItem(String id, Map<String, dynamic> item) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE purchase_order_items SET inventory_item_id = ?, quantity = ?, unit_price = ?, total_price = ? WHERE id = ?',
        [
          item['inventory_item_id'],
          item['quantity'],
          item['unit_price'],
          item['total_price'],
          id,
        ],
      );
    } catch (e) {
      throw Exception('Failed to update purchase order item: $e');
    }
  }

  Future<void> deletePurchaseOrderItem(String id) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE purchase_order_items SET is_active = 0 WHERE id = ?',
        [id],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order item: $e');
    }
  }

  Future<void> deletePurchaseOrderItems(String purchaseOrderId) async {
    if (!isConnected) throw Exception('Database not connected');

    try {
      await _connection!.execute(
        'UPDATE purchase_order_items SET is_active = 0 WHERE purchase_order_id = ?',
        [purchaseOrderId],
      );
    } catch (e) {
      throw Exception('Failed to delete purchase order items: $e');
    }
  }
} 