import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
import 'database_service_interface.dart';
import 'web_database_service_interface.dart';

class WebDatabaseService implements WebDatabaseServiceInterface {
  static final WebDatabaseService _instance = WebDatabaseService._internal();
  factory WebDatabaseService() => _instance;
  WebDatabaseService._internal();

  bool _isConnected = false;
  
  // API settings
  String _apiUrl = 'http://localhost:8080/api';
  
  // Database connection settings (stored for UI display)
  String _host = 'localhost';
  int _port = 3306;
  String _user = 'flutteruser';
  String _password = 'flutterpassword';
  String _db = 'catererer_db';

  // Getters
  bool get isConnected => _isConnected;
  String get host => _host;
  int get port => _port;
  String get user => _user;
  String get password => _password;
  String get db => _db;
  String get apiUrl => _apiUrl;

  // Initialize connection settings from SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('db_host') ?? 'localhost';
    _port = prefs.getInt('db_port') ?? 3306;
    _user = prefs.getString('db_user') ?? 'flutteruser';
    _password = prefs.getString('db_password') ?? 'flutterpassword';
    _db = prefs.getString('db_name') ?? 'catererer_db';
    _apiUrl = prefs.getString('api_url') ?? 'http://localhost:8080/api';
    
    // Test connection
    await testConnection();
  }
  
  // Load connection settings from SharedPreferences
  Future<void> loadConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('db_host') ?? 'localhost';
    _port = prefs.getInt('db_port') ?? 3306;
    _user = prefs.getString('db_user') ?? 'flutteruser';
    _password = prefs.getString('db_password') ?? 'flutterpassword';
    _db = prefs.getString('db_name') ?? 'catererer_db';
    _apiUrl = prefs.getString('api_url') ?? 'http://localhost:8080/api';
  }
  
  // Save connection settings to SharedPreferences
  @override
  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
    String? apiUrl,
  }) async {
    _host = host;
    _port = port;
    _user = user;
    _password = password;
    _db = db;
    if (apiUrl != null) {
      _apiUrl = apiUrl;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_host', host);
    await prefs.setInt('db_port', port);
    await prefs.setString('db_user', user);
    await prefs.setString('db_password', password);
    await prefs.setString('db_name', db);
    await prefs.setString('api_url', _apiUrl);
  }
  
  // Save API URL to SharedPreferences
  @override
  Future<void> saveApiUrl(String apiUrl) async {
    _apiUrl = apiUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', apiUrl);
  }

  // Connect to database via API
  Future<bool> connect() async {
    try {
      final success = await testConnection();
      _isConnected = success;
      return success;
    } catch (e) {
      debugPrint('Error connecting to database via API: $e');
      _isConnected = false;
      return false;
    }
  }

  // Test connection to API
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing database connection via API...');
      final response = await http.get(Uri.parse('$_apiUrl/db-test'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          debugPrint('API connection test successful');
          _isConnected = true;
          return true;
        } else {
          debugPrint('API connection test failed: ${data['message']}');
          _isConnected = false;
          return false;
        }
      } else {
        debugPrint('API connection test failed with status code: ${response.statusCode}');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      debugPrint('Error testing API connection: $e');
      _isConnected = false;
      return false;
    }
  }
  
  // Test connection with specific parameters
  Future<bool> testConnectionWithParams({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String db,
    String? apiUrl,
  }) async {
    // In web mode, we're just testing if the API is accessible
    // The actual database connection is handled by the API server
    try {
      final url = apiUrl ?? _apiUrl;
      final response = await http.get(Uri.parse('$url/db-test'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Error testing connection with params: $e');
      return false;
    }
  }

  // Disconnect (no-op in web mode)
  Future<void> disconnect() async {
    _isConnected = false;
  }

  // Update connection settings
  Future<bool> updateConnectionSettings({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String db,
    String? apiUrl,
  }) async {
    try {
      final url = apiUrl ?? _apiUrl;
      
      // Test the connection
      final success = await testConnectionWithParams(
        host: host,
        port: port,
        userName: userName,
        password: password,
        db: db,
        apiUrl: url,
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
      if (apiUrl != null) {
        _apiUrl = apiUrl;
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('db_host', host);
      await prefs.setInt('db_port', port);
      await prefs.setString('db_user', userName);
      await prefs.setString('db_password', password);
      await prefs.setString('db_name', db);
      await prefs.setString('api_url', _apiUrl);

      return true;
    } catch (e) {
      debugPrint('Error updating connection settings: $e');
      return false;
    }
  }

  // Client-related methods
  Future<List<Client>> getClients() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/clients'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> clientsData = data['data'];
          return clientsData.map((clientData) {
            return Client.fromMap({
              'id': clientData['client_id'].toString(),
              'clientName': clientData['client_name'] ?? '',
              'contactPerson': clientData['contact_person'],
              'phone1': clientData['phone1'],
              'phone2': clientData['phone2'],
              'email1': clientData['email1'],
              'email2': clientData['email2'],
              'billingAddress': clientData['billing_address'],
              'companyName': clientData['company_name'],
              'notes': clientData['notes'],
              'createdAt': clientData['created_at'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load clients');
        }
      } else {
        throw Exception('Failed to load clients: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting clients: $e');
      rethrow;
    }
  }

  Future<Client?> getClient(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/clients/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final clientData = data['data'];
          return Client.fromMap({
            'id': clientData['client_id'].toString(),
            'clientName': clientData['client_name'] ?? '',
            'contactPerson': clientData['contact_person'],
            'phone1': clientData['phone1'],
            'phone2': clientData['phone2'],
            'email1': clientData['email1'],
            'email2': clientData['email2'],
            'billingAddress': clientData['billing_address'],
            'companyName': clientData['company_name'],
            'notes': clientData['notes'],
            'createdAt': clientData['created_at'],
          });
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting client: $e');
      return null;
    }
  }

  Future<String> addClient(Client client) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/clients'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_name': client.clientName,
          'contact_person': client.contactPerson,
          'phone1': client.phone1,
          'phone2': client.phone2,
          'email1': client.email1,
          'email2': client.email2,
          'billing_address': client.billingAddress,
          'company_name': client.companyName,
          'notes': client.notes,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add client: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding client: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client client) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/clients/${client.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_name': client.clientName,
          'contact_person': client.contactPerson,
          'phone1': client.phone1,
          'phone2': client.phone2,
          'email1': client.email1,
          'email2': client.email2,
          'billing_address': client.billingAddress,
          'company_name': client.companyName,
          'notes': client.notes,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update client: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating client: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/clients/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete client: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting client: $e');
      rethrow;
    }
  }

  // Event-related methods
  Future<List<Event>> getEvents() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/events'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> eventsData = data['data'];
          return eventsData.map((eventData) {
            return Event.fromMap({
              'id': eventData['event_id'].toString(),
              'clientId': eventData['client_id'].toString(),
              'eventName': eventData['event_name'],
              'eventDate': eventData['event_date'],
              'venueAddress': eventData['venue_address'],
              'eventType': eventData['event_type'],
              'totalGuestCount': eventData['total_guest_count'],
              'guestsMale': eventData['guests_male'],
              'guestsFemale': eventData['guests_female'],
              'guestsElderly': eventData['guests_elderly'],
              'guestsYouth': eventData['guests_youth'],
              'guestsChild': eventData['guests_child'],
              'status': eventData['status'],
              'notes': eventData['notes'],
              'createdAt': eventData['created_at'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load events');
        }
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting events: $e');
      rethrow;
    }
  }

  Future<Event?> getEvent(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/events/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final eventData = data['data'];
          return Event.fromMap({
            'id': eventData['event_id'].toString(),
            'clientId': eventData['client_id'].toString(),
            'eventName': eventData['event_name'],
            'eventDate': eventData['event_date'],
            'venueAddress': eventData['venue_address'],
            'eventType': eventData['event_type'],
            'totalGuestCount': eventData['total_guest_count'],
            'guestsMale': eventData['guests_male'],
            'guestsFemale': eventData['guests_female'],
            'guestsElderly': eventData['guests_elderly'],
            'guestsYouth': eventData['guests_youth'],
            'guestsChild': eventData['guests_child'],
            'status': eventData['status'],
            'notes': eventData['notes'],
            'createdAt': eventData['created_at'],
          });
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting event: $e');
      return null;
    }
  }

  Future<String> addEvent(Event event) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': event.clientId,
          'event_name': event.eventName,
          'event_date': event.eventDate?.toIso8601String(),
          'venue_address': event.venueAddress,
          'event_type': event.eventType,
          'total_guest_count': event.totalGuestCount,
          'guests_male': event.guestsMale,
          'guests_female': event.guestsFemale,
          'guests_elderly': event.guestsElderly,
          'guests_youth': event.guestsYouth,
          'guests_child': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/events/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': event.clientId,
          'event_name': event.eventName,
          'event_date': event.eventDate?.toIso8601String(),
          'venue_address': event.venueAddress,
          'event_type': event.eventType,
          'total_guest_count': event.totalGuestCount,
          'guests_male': event.guestsMale,
          'guests_female': event.guestsFemale,
          'guests_elderly': event.guestsElderly,
          'guests_youth': event.guestsYouth,
          'guests_child': event.guestsChild,
          'status': event.status,
          'notes': event.notes,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/events/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  // Dish-related methods
  Future<List<Dish>> getDishes() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/dishes'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> dishesData = data['data'];
          return dishesData.map((dishData) {
            return Dish.fromMap({
              'id': dishData['dish_id'].toString(),
              'name': dishData['name'] ?? '',
              'categoryId': dishData['category_id'].toString(),
              'category': dishData['category'] ?? '',
              'basePrice': dishData['base_price'],
              'baseFoodCost': dishData['base_food_cost'],
              'standardPortionSize': dishData['standard_portion_size'],
              'description': dishData['description'],
              'imageUrl': dishData['image_url'],
              'dietaryTags': dishData['dietary_tags'],
              'itemType': dishData['item_type'],
              'isActive': dishData['is_active'],
              'createdAt': dishData['created_at'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load dishes');
        }
      } else {
        throw Exception('Failed to load dishes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting dishes: $e');
      rethrow;
    }
  }

  Future<Dish?> getDish(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/dishes/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final dishData = data['data'];
          return Dish.fromMap({
            'id': dishData['dish_id'].toString(),
            'name': dishData['name'] ?? '',
            'categoryId': dishData['category_id'].toString(),
            'category': dishData['category'] ?? '',
            'basePrice': dishData['base_price'],
            'baseFoodCost': dishData['base_food_cost'],
            'standardPortionSize': dishData['standard_portion_size'],
            'description': dishData['description'],
            'imageUrl': dishData['image_url'],
            'dietaryTags': dishData['dietary_tags'],
            'itemType': dishData['item_type'],
            'isActive': dishData['is_active'],
            'createdAt': dishData['created_at'],
          });
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting dish: $e');
      return null;
    }
  }

  Future<String> addDish(Dish dish) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/dishes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': dish.name,
          'category_id': dish.categoryId,
          'category': dish.category,
          'base_price': dish.basePrice,
          'base_food_cost': dish.baseFoodCost,
          'standard_portion_size': dish.standardPortionSize,
          'description': dish.description,
          'image_url': dish.imageUrl,
          'dietary_tags': dish.dietaryTags.join(','),
          'item_type': dish.itemType,
          'is_active': dish.isActive ? 1 : 0,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add dish: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding dish: $e');
      rethrow;
    }
  }

  Future<void> updateDish(Dish dish) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/dishes/${dish.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': dish.name,
          'category_id': dish.categoryId,
          'category': dish.category,
          'base_price': dish.basePrice,
          'base_food_cost': dish.baseFoodCost,
          'standard_portion_size': dish.standardPortionSize,
          'description': dish.description,
          'image_url': dish.imageUrl,
          'dietary_tags': dish.dietaryTags.join(','),
          'item_type': dish.itemType,
          'is_active': dish.isActive ? 1 : 0,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update dish: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating dish: $e');
      rethrow;
    }
  }

  Future<void> deleteDish(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/dishes/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete dish: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting dish: $e');
      rethrow;
    }
  }

  // Quote-related methods
  Future<List<Quote>> getQuotes() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quotes'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> quotesData = data['data'];
          List<Quote> quotes = [];
          
          for (var quoteData in quotesData) {
            // First get the quote without items
            Quote quote = Quote.fromMap({
              'id': quoteData['quote_id'].toString(),
              'clientId': quoteData['client_id'].toString(),
              'eventId': quoteData['event_id']?.toString(),
              'quoteDate': quoteData['quote_date'],
              'totalGuestCount': quoteData['total_guest_count'],
              'guestsMale': quoteData['guests_male'],
              'guestsFemale': quoteData['guests_female'],
              'guestsElderly': quoteData['guests_elderly'],
              'guestsYouth': quoteData['guests_youth'],
              'guestsChild': quoteData['guests_child'],
              'calculationMethod': quoteData['calculation_method'],
              'overheadPercentage': quoteData['overhead_percentage'],
              'calculatedTotalFoodCost': quoteData['calculated_total_food_cost'],
              'calculatedOverheadCost': quoteData['calculated_overhead_cost'],
              'grandTotal': quoteData['grand_total'],
              'notes': quoteData['notes'],
              'termsAndConditions': quoteData['terms_and_conditions'],
              'status': quoteData['status'],
              'items': [], // Will be populated separately if needed
            });
            
            quotes.add(quote);
          }
          
          return quotes;
        } else {
          throw Exception(data['message'] ?? 'Failed to load quotes');
        }
      } else {
        throw Exception('Failed to load quotes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting quotes: $e');
      rethrow;
    }
  }

  Future<Quote?> getQuote(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quotes/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final quoteData = data['data'];
          
          // First get the quote without items
          Quote quote = Quote.fromMap({
            'id': quoteData['quote_id'].toString(),
            'clientId': quoteData['client_id'].toString(),
            'eventId': quoteData['event_id']?.toString(),
            'quoteDate': quoteData['quote_date'],
            'totalGuestCount': quoteData['total_guest_count'],
            'guestsMale': quoteData['guests_male'],
            'guestsFemale': quoteData['guests_female'],
            'guestsElderly': quoteData['guests_elderly'],
            'guestsYouth': quoteData['guests_youth'],
            'guestsChild': quoteData['guests_child'],
            'calculationMethod': quoteData['calculation_method'],
            'overheadPercentage': quoteData['overhead_percentage'],
            'calculatedTotalFoodCost': quoteData['calculated_total_food_cost'],
            'calculatedOverheadCost': quoteData['calculated_overhead_cost'],
            'grandTotal': quoteData['grand_total'],
            'notes': quoteData['notes'],
            'termsAndConditions': quoteData['terms_and_conditions'],
            'status': quoteData['status'],
            'items': [], // Will be populated below
          });
          
          // Get quote items if they're included in the response
          if (quoteData['items'] != null) {
            final List<dynamic> itemsData = quoteData['items'];
            List<QuoteItem> items = itemsData.map((itemData) {
              return QuoteItem.fromMap({
                'id': itemData['item_id'].toString(),
                'quoteId': itemData['quote_id'].toString(),
                'dishId': itemData['dish_id']?.toString() ?? '',
                'quotedPortionSizeGrams': itemData['quoted_portion_size_grams'],
                'quotedBaseFoodCostPerServing': itemData['quoted_base_food_cost_per_serving'],
                'percentageTakeRate': itemData['percentage_take_rate'],
                'estimatedServings': itemData['estimated_servings'],
                'estimatedTotalWeightGrams': itemData['estimated_total_weight_grams'],
                'estimatedItemFoodCost': itemData['estimated_item_food_cost'],
              });
            }).toList();
            
            // Create a new quote with the items
            return Quote.fromMap({
              'id': quote.id,
              'clientId': quote.clientId,
              'eventId': quote.eventId,
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
              'items': items,
            });
          }
          
          // If no items in response, fetch them separately
          try {
            final itemsResponse = await http.get(Uri.parse('$_apiUrl/quotes/$id/items'));
            if (itemsResponse.statusCode == 200) {
              final itemsData = json.decode(itemsResponse.body);
              if (itemsData['status'] == 'success') {
                final List<dynamic> items = itemsData['data'];
                List<QuoteItem> quoteItems = items.map((itemData) {
                  return QuoteItem.fromMap({
                    'id': itemData['item_id'].toString(),
                    'quoteId': itemData['quote_id'].toString(),
                    'dishId': itemData['dish_id']?.toString() ?? '',
                    'quotedPortionSizeGrams': itemData['quoted_portion_size_grams'],
                    'quotedBaseFoodCostPerServing': itemData['quoted_base_food_cost_per_serving'],
                    'percentageTakeRate': itemData['percentage_take_rate'],
                    'estimatedServings': itemData['estimated_servings'],
                    'estimatedTotalWeightGrams': itemData['estimated_total_weight_grams'],
                    'estimatedItemFoodCost': itemData['estimated_item_food_cost'],
                  });
                }).toList();
                
                // Create a new quote with the items
                return Quote.fromMap({
                  'id': quote.id,
                  'clientId': quote.clientId,
                  'eventId': quote.eventId,
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
                  'items': quoteItems,
                });
              }
            }
          } catch (e) {
            debugPrint('Error fetching quote items: $e');
          }
          
          return quote;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting quote: $e');
      return null;
    }
  }

  Future<String> addQuote(Quote quote) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/quotes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': quote.clientId,
          'event_id': quote.eventId,
          'quote_date': quote.quoteDate.toIso8601String(),
          'total_guest_count': quote.totalGuestCount,
          'guests_male': quote.guestsMale,
          'guests_female': quote.guestsFemale,
          'guests_elderly': quote.guestsElderly,
          'guests_youth': quote.guestsYouth,
          'guests_child': quote.guestsChild,
          'calculation_method': quote.calculationMethod,
          'overhead_percentage': quote.overheadPercentage,
          'calculated_total_food_cost': quote.calculatedTotalFoodCost,
          'calculated_overhead_cost': quote.calculatedOverheadCost,
          'grand_total': quote.grandTotal,
          'notes': quote.notes,
          'terms_and_conditions': quote.termsAndConditions,
          'status': quote.status,
          // Items will be added separately
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add quote: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding quote: $e');
      rethrow;
    }
  }

  Future<void> updateQuote(Quote quote) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/quotes/${quote.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': quote.clientId,
          'event_id': quote.eventId,
          'quote_date': quote.quoteDate.toIso8601String(),
          'total_guest_count': quote.totalGuestCount,
          'guests_male': quote.guestsMale,
          'guests_female': quote.guestsFemale,
          'guests_elderly': quote.guestsElderly,
          'guests_youth': quote.guestsYouth,
          'guests_child': quote.guestsChild,
          'calculation_method': quote.calculationMethod,
          'overhead_percentage': quote.overheadPercentage,
          'calculated_total_food_cost': quote.calculatedTotalFoodCost,
          'calculated_overhead_cost': quote.calculatedOverheadCost,
          'grand_total': quote.grandTotal,
          'notes': quote.notes,
          'terms_and_conditions': quote.termsAndConditions,
          'status': quote.status,
          // Items will be updated separately
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update quote: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating quote: $e');
      rethrow;
    }
  }

  Future<void> deleteQuote(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/quotes/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete quote: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting quote: $e');
      rethrow;
    }
  }

  // QuoteItem-related methods
  Future<List<QuoteItem>> getQuoteItems() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quote-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((itemData) {
            return QuoteItem.fromMap({
              'id': itemData['item_id'].toString(),
              'quoteId': itemData['quote_id'].toString(),
              'dishId': itemData['dish_id']?.toString() ?? '',
              'quotedPortionSizeGrams': itemData['quoted_portion_size_grams'],
              'quotedBaseFoodCostPerServing': itemData['quoted_base_food_cost_per_serving'],
              'percentageTakeRate': itemData['percentage_take_rate'],
              'estimatedServings': itemData['estimated_servings'],
              'estimatedTotalWeightGrams': itemData['estimated_total_weight_grams'],
              'estimatedItemFoodCost': itemData['estimated_item_food_cost'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load quote items');
        }
      } else {
        throw Exception('Failed to load quote items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting quote items: $e');
      rethrow;
    }
  }

  Future<List<QuoteItem>> getQuoteItemsForQuote(String quoteId) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quotes/$quoteId/items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((itemData) {
            return QuoteItem.fromMap({
              'id': itemData['item_id'].toString(),
              'quoteId': itemData['quote_id'].toString(),
              'dishId': itemData['dish_id']?.toString() ?? '',
              'quotedPortionSizeGrams': itemData['quoted_portion_size_grams'],
              'quotedBaseFoodCostPerServing': itemData['quoted_base_food_cost_per_serving'],
              'percentageTakeRate': itemData['percentage_take_rate'],
              'estimatedServings': itemData['estimated_servings'],
              'estimatedTotalWeightGrams': itemData['estimated_total_weight_grams'],
              'estimatedItemFoodCost': itemData['estimated_item_food_cost'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load quote items');
        }
      } else {
        throw Exception('Failed to load quote items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting quote items for quote: $e');
      rethrow;
    }
  }

  Future<String> addQuoteItem(QuoteItem item) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/quote-items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quote_id': item.quoteId,
          'dish_id': item.dishId,
          'quoted_portion_size_grams': item.quotedPortionSizeGrams,
          'quoted_base_food_cost_per_serving': item.quotedBaseFoodCostPerServing,
          'percentage_take_rate': item.percentageTakeRate,
          'estimated_servings': item.estimatedServings,
          'estimated_total_weight_grams': item.estimatedTotalWeightGrams,
          'estimated_item_food_cost': item.estimatedItemFoodCost,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add quote item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding quote item: $e');
      rethrow;
    }
  }

  Future<void> updateQuoteItem(QuoteItem item) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/quote-items/${item.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quote_id': item.quoteId,
          'dish_id': item.dishId,
          'quoted_portion_size_grams': item.quotedPortionSizeGrams,
          'quoted_base_food_cost_per_serving': item.quotedBaseFoodCostPerServing,
          'percentage_take_rate': item.percentageTakeRate,
          'estimated_servings': item.estimatedServings,
          'estimated_total_weight_grams': item.estimatedTotalWeightGrams,
          'estimated_item_food_cost': item.estimatedItemFoodCost,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update quote item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating quote item: $e');
      rethrow;
    }
  }

  Future<void> deleteQuoteItem(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/quote-items/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete quote item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting quote item: $e');
      rethrow;
    }
  }

  // MenuPackage-related methods
  Future<List<MenuPackage>> getMenuPackages() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/menu-packages'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> packagesData = data['data'];
          return packagesData.map((packageData) {
            return MenuPackage.fromMap({
              'id': packageData['package_id'].toString(),
              'name': packageData['name'],
              'description': packageData['description'],
              'basePrice': packageData['base_price'],
              'isActive': packageData['is_active'],
              'createdAt': packageData['created_at'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load menu packages');
        }
      } else {
        throw Exception('Failed to load menu packages: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting menu packages: $e');
      rethrow;
    }
  }

  Future<MenuPackage?> getMenuPackage(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/menu-packages/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final packageData = data['data'];
          return MenuPackage.fromMap({
            'id': packageData['package_id'].toString(),
            'name': packageData['name'],
            'description': packageData['description'],
            'basePrice': packageData['base_price'],
            'isActive': packageData['is_active'],
            'createdAt': packageData['created_at'],
          });
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting menu package: $e');
      return null;
    }
  }

  Future<String> addMenuPackage(MenuPackage package) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/menu-packages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': package.name,
          'description': package.description,
          'base_price': package.basePrice,
          'is_active': package.isActive ? 1 : 0,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add menu package: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding menu package: $e');
      rethrow;
    }
  }

  Future<void> updateMenuPackage(MenuPackage package) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/menu-packages/${package.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': package.name,
          'description': package.description,
          'base_price': package.basePrice,
          'is_active': package.isActive ? 1 : 0,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update menu package: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating menu package: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuPackage(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/menu-packages/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete menu package: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting menu package: $e');
      rethrow;
    }
  }

  // PackageItem-related methods
  Future<List<PackageItem>> getPackageItems() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/package-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((itemData) {
            return PackageItem.fromMap({
              'id': itemData['item_id'].toString(),
              'package_id': itemData['package_id'].toString(),
              'dish_id': itemData['dish_id'].toString(),
              'is_optional': itemData['is_optional'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load package items');
        }
      } else {
        throw Exception('Failed to load package items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting package items: $e');
      rethrow;
    }
  }

  Future<List<PackageItem>> getPackageItemsForPackage(String packageId) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/menu-packages/$packageId/items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((itemData) {
            return PackageItem.fromMap({
              'id': itemData['item_id'].toString(),
              'package_id': itemData['package_id'].toString(),
              'dish_id': itemData['dish_id'].toString(),
              'is_optional': itemData['is_optional'],
            });
          }).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load package items');
        }
      } else {
        throw Exception('Failed to load package items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting package items for package: $e');
      rethrow;
    }
  }

  Future<String> addPackageItem(PackageItem item) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/package-items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'package_id': item.packageId,
          'dish_id': item.dishId,
          'is_optional': item.isOptional ? 1 : 0,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add package item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding package item: $e');
      rethrow;
    }
  }

  Future<void> updatePackageItem(PackageItem item) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/package-items/${item.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'package_id': item.packageId,
          'dish_id': item.dishId,
          'is_optional': item.isOptional ? 1 : 0,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update package item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating package item: $e');
      rethrow;
    }
  }

  Future<void> deletePackageItem(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/package-items/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete package item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting package item: $e');
      rethrow;
    }
  }

  // Inventory-related methods
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/inventory'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load inventory items');
        }
      } else {
        throw Exception('Failed to load inventory items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting inventory items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getInventoryItem(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/inventory/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting inventory item: $e');
      return null;
    }
  }

  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/inventory'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add inventory item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryItem(Map<String, dynamic> item) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/inventory/${item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update inventory item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/inventory/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete inventory item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      rethrow;
    }
  }

  // Supplier-related methods
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/suppliers'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> suppliersData = data['data'];
          return suppliersData.map((supplier) => supplier as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load suppliers');
        }
      } else {
        throw Exception('Failed to load suppliers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting suppliers: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSupplier(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/suppliers/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting supplier: $e');
      return null;
    }
  }

  Future<String> addSupplier(Map<String, dynamic> supplier) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/suppliers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplier),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add supplier: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/suppliers/${supplier['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplier),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update supplier: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating supplier: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/suppliers/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete supplier: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      rethrow;
    }
  }

  // PurchaseOrder-related methods
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-orders'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> ordersData = data['data'];
          return ordersData.map((order) => order as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchase orders');
        }
      } else {
        throw Exception('Failed to load purchase orders: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting purchase orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPurchaseOrder(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-orders/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting purchase order: $e');
      return null;
    }
  }

  Future<String> addPurchaseOrder(Map<String, dynamic> order) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/purchase-orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(order),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add purchase order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding purchase order: $e');
      rethrow;
    }
  }

  Future<void> updatePurchaseOrder(Map<String, dynamic> order) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/purchase-orders/${order['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(order),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update purchase order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating purchase order: $e');
      rethrow;
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/purchase-orders/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete purchase order: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting purchase order: $e');
      rethrow;
    }
  }

  // PurchaseOrderItem-related methods
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-orders/$orderId/items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> itemsData = data['data'];
          return itemsData.map((item) => item as Map<String, dynamic>).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load purchase order items');
        }
      } else {
        throw Exception('Failed to load purchase order items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting purchase order items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id) async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-order-items/$id'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data['data'] as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting purchase order item: $e');
      return null;
    }
  }

  Future<String> addPurchaseOrderItem(Map<String, dynamic> item) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/purchase-order-items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'].toString();
      } else {
        throw Exception('Failed to add purchase order item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding purchase order item: $e');
      rethrow;
    }
  }

  Future<void> updatePurchaseOrderItem(Map<String, dynamic> item) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/purchase-order-items/${item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update purchase order item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating purchase order item: $e');
      rethrow;
    }
  }

  Future<void> deletePurchaseOrderItem(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_apiUrl/purchase-order-items/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete purchase order item: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting purchase order item: $e');
      rethrow;
    }
  }
}