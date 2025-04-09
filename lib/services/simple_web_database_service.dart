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
import 'database_service_interface.dart';
import 'web_database_service_interface.dart';

/// A simplified web database service that doesn't try to connect to MySQL directly
class SimpleWebDatabaseService implements WebDatabaseServiceInterface {
  // Singleton pattern
  static final SimpleWebDatabaseService _instance = SimpleWebDatabaseService._internal();
  factory SimpleWebDatabaseService() => _instance;
  SimpleWebDatabaseService._internal();

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
    
    // Automatically connect to the database
    final success = await connect();
    if (!success) {
      // If connection fails, try again with default settings
      _apiUrl = 'http://localhost:8080/api';
      await saveApiUrl(_apiUrl);
      await connect();
    }
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
      debugPrint('Connecting to database via API...');
      // In web mode, we don't try to connect directly to MySQL
      // We only check if the API is accessible
      final success = await testConnection();
      _isConnected = success;
      debugPrint('API connection ${success ? 'successful' : 'failed'}');
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
      
      // Set a timeout for the request
      final response = await http.get(
        Uri.parse('$_apiUrl/db-test')
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('API connection test timed out');
          return http.Response('{"status":"error","message":"Connection timed out"}', 408);
        }
      );
      
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
    if (!_isConnected) {
      debugPrint('Database not connected, returning empty clients list');
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/clients'))
        .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Request for clients timed out');
          return http.Response('{"status":"error","message":"Connection timed out"}', 408);
        });
      
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
          debugPrint('Failed to load clients: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('Failed to load clients: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting clients: $e');
      return [];
    }
  }

  // Event-related methods
  Future<List<Event>> getEvents() async {
    if (!_isConnected) {
      debugPrint('Database not connected, returning empty events list');
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/events'))
        .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('Request for events timed out');
          return http.Response('{"status":"error","message":"Connection timed out"}', 408);
        });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> eventsData = data['data'];
          return eventsData.map((eventData) {
            // Convert string values to appropriate types
            int? parseIntSafely(dynamic value) {
              if (value == null) return null;
              if (value is int) return value;
              if (value is String) {
                try {
                  return int.parse(value);
                } catch (e) {
                  debugPrint('Error parsing int: $value, $e');
                  return 0;
                }
              }
              return 0;
            }
            
            return Event.fromMap({
              'id': eventData['event_id'].toString(),
              'clientId': eventData['client_id'].toString(),
              'eventName': eventData['event_name'],
              'eventDate': eventData['event_date'],
              'venueAddress': eventData['venue_address'],
              'eventType': eventData['event_type'],
              'totalGuestCount': parseIntSafely(eventData['total_guest_count']),
              'guestsMale': parseIntSafely(eventData['guests_male']) ?? 0,
              'guestsFemale': parseIntSafely(eventData['guests_female']) ?? 0,
              'guestsElderly': parseIntSafely(eventData['guests_elderly']) ?? 0,
              'guestsYouth': parseIntSafely(eventData['guests_youth']) ?? 0,
              'guestsChild': parseIntSafely(eventData['guests_child']) ?? 0,
              'status': eventData['status'] ?? 'Planning',
              'notes': eventData['notes'],
              'createdAt': eventData['created_at'],
            });
          }).toList();
        } else {
          debugPrint('Failed to load events: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('Failed to load events: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting events: $e');
      return [];
    }
  }

  // Dish-related methods
  Future<List<Dish>> getDishes() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/dishes'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> dishesData = data['data'];
          return dishesData.map((dishData) {
            // Helper functions for safe type conversion
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            bool parseBoolSafely(dynamic value) {
              if (value == null) return false;
              if (value is bool) return value;
              if (value is int) return value == 1;
              if (value is String) {
                return value.toLowerCase() == 'true' || value == '1';
              }
              return false;
            }
            
            // Debug the dish data
            debugPrint('Processing dish: ${dishData['name']}');
            
            // Handle dietary tags
            List<String> processDietaryTags(dynamic tags) {
              if (tags == null) return [];
              if (tags is List) {
                return tags.map((tag) => tag.toString()).toList();
              }
              if (tags is String) {
                return tags.split(',').map((tag) => tag.trim()).toList();
              }
              return [];
            }
            
            // Handle ingredients
            Map<String, double> processIngredients(dynamic ingredients) {
              if (ingredients == null) return {};
              if (ingredients is Map) {
                Map<String, double> result = {};
                ingredients.forEach((key, value) {
                  if (value is num) {
                    result[key.toString()] = value.toDouble();
                  } else if (value is String) {
                    try {
                      result[key.toString()] = double.parse(value);
                    } catch (e) {
                      result[key.toString()] = 0.0;
                    }
                  }
                });
                return result;
              }
              return {};
            }
            
            return Dish(
              id: dishData['dish_id']?.toString() ?? '0',
              name: dishData['name'] ?? '',
              categoryId: dishData['category_id']?.toString() ?? '0',
              category: dishData['category'] ?? 'Uncategorized',
              basePrice: parseDoubleSafely(dishData['base_price']),
              baseFoodCost: parseDoubleSafely(dishData['base_food_cost']),
              standardPortionSize: parseDoubleSafely(dishData['standard_portion_size']),
              description: dishData['description'],
              imageUrl: dishData['image_url'],
              dietaryTags: processDietaryTags(dishData['dietary_tags']),
              itemType: dishData['item_type'] ?? 'Standard',
              isActive: parseBoolSafely(dishData['is_active']),
              ingredients: processIngredients(dishData['ingredients']),
              createdAt: dishData['created_at'] != null ? 
                  DateTime.parse(dishData['created_at']) : DateTime.now(),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting dishes: $e');
      return [];
    }
  }

  // Quote-related methods
  Future<List<Quote>> getQuotes() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quotes'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> quotesData = data['data'];
          return quotesData.map((quoteData) {
            // Helper functions for safe type conversion
            int parseIntSafely(dynamic value) {
              if (value == null) return 0;
              if (value is int) return value;
              if (value is String) {
                try {
                  return int.parse(value);
                } catch (e) {
                  debugPrint('Error parsing int: $value, $e');
                  return 0;
                }
              }
              return 0;
            }
            
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            return Quote(
              id: quoteData['quote_id'] != null ? BigInt.parse(quoteData['quote_id'].toString()) : BigInt.from(0),
              eventId: quoteData['event_id'] != null ? BigInt.parse(quoteData['event_id'].toString()) : null,
              clientId: quoteData['client_id'] != null ? BigInt.parse(quoteData['client_id'].toString()) : BigInt.from(0),
              quoteDate: quoteData['quote_date'] != null ? 
                  DateTime.parse(quoteData['quote_date']) : DateTime.now(),
              totalGuestCount: parseIntSafely(quoteData['total_guest_count']),
              guestsMale: parseIntSafely(quoteData['guests_male']),
              guestsFemale: parseIntSafely(quoteData['guests_female']),
              guestsElderly: parseIntSafely(quoteData['guests_elderly']),
              guestsYouth: parseIntSafely(quoteData['guests_youth']),
              guestsChild: parseIntSafely(quoteData['guests_child']),
              calculationMethod: quoteData['calculation_method'] ?? 'Simple',
              overheadPercentage: parseDoubleSafely(quoteData['overhead_percentage']),
              calculatedTotalFoodCost: parseDoubleSafely(quoteData['calculated_total_food_cost']),
              calculatedOverheadCost: parseDoubleSafely(quoteData['calculated_overhead_cost']),
              grandTotal: parseDoubleSafely(quoteData['grand_total']),
              notes: quoteData['notes'],
              termsAndConditions: quoteData['terms_and_conditions'],
              status: quoteData['status'] ?? 'Draft',
              items: [], // Items will be loaded separately
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting quotes: $e');
      return [];
    }
  }

  // QuoteItem-related methods
  Future<List<QuoteItem>> getQuoteItems() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/quote-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> quoteItemsData = data['data'];
          return quoteItemsData.map((quoteItemData) {
            // Helper functions for safe type conversion
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            int parseIntSafely(dynamic value) {
              if (value == null) return 0;
              if (value is int) return value;
              if (value is String) {
                try {
                  return int.parse(value);
                } catch (e) {
                  debugPrint('Error parsing int: $value, $e');
                  return 0;
                }
              }
              return 0;
            }
            
            // Debug the quote item data
            debugPrint('Processing quote item: ${quoteItemData['item_id']}');
            
            return QuoteItem(
              id: quoteItemData['item_id'] != null ? BigInt.parse(quoteItemData['item_id'].toString()) : BigInt.from(0),
              quoteId: quoteItemData['quote_id'] != null ? BigInt.parse(quoteItemData['quote_id'].toString()) : BigInt.from(0),
              dishId: quoteItemData['dish_id'] != null ? BigInt.parse(quoteItemData['dish_id'].toString()) : BigInt.from(0),
              dishName: quoteItemData['dish_name'] ?? '',
              quantity: parseDoubleSafely(quoteItemData['quantity']),
              unitPrice: parseDoubleSafely(quoteItemData['unit_price']),
              totalPrice: parseDoubleSafely(quoteItemData['total_price']),
              quotedPortionSizeGrams: parseDoubleSafely(quoteItemData['quoted_portion_size_grams']),
              quotedBaseFoodCostPerServing: parseDoubleSafely(quoteItemData['quoted_base_food_cost_per_serving']),
              percentageTakeRate: parseDoubleSafely(quoteItemData['percentage_take_rate']),
              estimatedServings: parseIntSafely(quoteItemData['estimated_servings']),
              estimatedTotalWeightGrams: parseDoubleSafely(quoteItemData['estimated_total_weight_grams']),
              estimatedItemFoodCost: parseDoubleSafely(quoteItemData['estimated_item_food_cost']),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting quote items: $e');
      return [];
    }
  }
  
  @override
  Future<List<QuoteItem>> getQuoteItemsForQuote(String quoteId) async {
    if (!_isConnected) {
      debugPrint('Database not connected, returning empty quote items list');
      return [];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/quote-items/quote/$quoteId')
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Request for quote items timed out');
        return http.Response('{"status":"error","message":"Connection timed out"}', 408);
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> quoteItemsData = data['data'];
          return quoteItemsData.map((quoteItemData) {
            // Helper functions for safe type conversion
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            int parseIntSafely(dynamic value) {
              if (value == null) return 0;
              if (value is int) return value;
              if (value is String) {
                try {
                  return int.parse(value);
                } catch (e) {
                  debugPrint('Error parsing int: $value, $e');
                  return 0;
                }
              }
              return 0;
            }
            
            // Debug the quote item data
            debugPrint('Processing quote item for quote: ${quoteItemData['item_id']}');
            
            return QuoteItem(
              id: quoteItemData['item_id'] != null ? BigInt.parse(quoteItemData['item_id'].toString()) : BigInt.from(0),
              quoteId: quoteItemData['quote_id'] != null ? BigInt.parse(quoteItemData['quote_id'].toString()) : BigInt.from(0),
              dishId: quoteItemData['dish_id'] != null ? BigInt.parse(quoteItemData['dish_id'].toString()) : BigInt.from(0),
              dishName: quoteItemData['dish_name'] ?? '',
              quantity: parseDoubleSafely(quoteItemData['quantity']),
              unitPrice: parseDoubleSafely(quoteItemData['unit_price']),
              totalPrice: parseDoubleSafely(quoteItemData['total_price']),
              quotedPortionSizeGrams: parseDoubleSafely(quoteItemData['quoted_portion_size_grams']),
              quotedBaseFoodCostPerServing: parseDoubleSafely(quoteItemData['quoted_base_food_cost_per_serving']),
              percentageTakeRate: parseDoubleSafely(quoteItemData['percentage_take_rate']),
              estimatedServings: parseIntSafely(quoteItemData['estimated_servings']),
              estimatedTotalWeightGrams: parseDoubleSafely(quoteItemData['estimated_total_weight_grams']),
              estimatedItemFoodCost: parseDoubleSafely(quoteItemData['estimated_item_food_cost']),
            );
          }).toList();
        } else {
          debugPrint('Failed to load quote items: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('Failed to load quote items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting quote items for quote: $e');
      return [];
    }
  }

  // MenuPackage-related methods
  Future<List<MenuPackage>> getMenuPackages() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/menu-packages'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> packagesData = data['data'];
          return packagesData.map((packageData) {
            // Helper functions for safe type conversion
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            bool parseBoolSafely(dynamic value) {
              if (value == null) return false;
              if (value is bool) return value;
              if (value is int) return value == 1;
              if (value is String) {
                return value.toLowerCase() == 'true' || value == '1';
              }
              return false;
            }
            
            return MenuPackage(
              id: packageData['package_id']?.toString(),
              name: packageData['name'] ?? '',
              description: packageData['description'] ?? '',
              basePrice: parseDoubleSafely(packageData['base_price']),
              eventType: packageData['event_type'] ?? 'Standard',
              isActive: parseBoolSafely(packageData['is_active']),
              createdAt: packageData['created_at'] != null ? 
                  DateTime.parse(packageData['created_at']) : DateTime.now(),
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting menu packages: $e');
      return [];
    }
  }

  // PackageItem-related methods
  Future<List<PackageItem>> getPackageItems() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/package-items'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> packageItemsData = data['data'];
          return packageItemsData.map((packageItemData) {
            // Make sure we have valid packageId and dishId
            String packageIdStr = packageItemData['package_id']?.toString() ?? '0';
            String dishIdStr = packageItemData['dish_id']?.toString() ?? '0';
            bool isOptional = packageItemData['is_optional'] == 1 || 
                              packageItemData['is_optional'] == '1' || 
                              packageItemData['is_optional'] == true;
            
            return PackageItem(
              id: packageItemData['item_id']?.toString(),
              packageId: packageIdStr,
              dishId: dishIdStr,
              isOptional: isOptional,
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting package items: $e');
      return [];
    }
  }
  
  @override
  Future<List<PackageItem>> getPackageItemsForPackage(String packageId) async {
    if (!_isConnected) {
      debugPrint('Database not connected, returning empty package items list');
      return [];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/package-items/package/$packageId')
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Request for package items timed out');
        return http.Response('{"status":"error","message":"Connection timed out"}', 408);
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> packageItemsData = data['data'];
          return packageItemsData.map((packageItemData) {
            // Make sure we have valid packageId and dishId
            String packageIdStr = packageItemData['package_id']?.toString() ?? packageId;
            String dishIdStr = packageItemData['dish_id']?.toString() ?? '0';
            bool isOptional = packageItemData['is_optional'] == 1 || 
                              packageItemData['is_optional'] == '1' || 
                              packageItemData['is_optional'] == true;
            
            return PackageItem(
              id: packageItemData['item_id']?.toString(),
              packageId: packageIdStr,
              dishId: dishIdStr,
              isOptional: isOptional,
            );
          }).toList();
        } else {
          debugPrint('Failed to load package items: ${data['message']}');
          return [];
        }
      } else {
        debugPrint('Failed to load package items: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting package items for package: $e');
      return [];
    }
  }

  // InventoryItem-related methods
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/inventory'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> inventoryData = data['data'];
          return List<Map<String, dynamic>>.from(inventoryData);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting inventory items: $e');
      return [];
    }
  }

  // Supplier-related methods
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/suppliers'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> suppliersData = data['data'];
          return List<Map<String, dynamic>>.from(suppliersData);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting suppliers: $e');
      return [];
    }
  }

  // PurchaseOrder-related methods
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-orders'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> purchaseOrdersData = data['data'];
          
          // Process each purchase order to ensure correct types
          return purchaseOrdersData.map<Map<String, dynamic>>((item) {
            // Helper function for safe type conversion
            double parseDoubleSafely(dynamic value) {
              if (value == null) return 0.0;
              if (value is double) return value;
              if (value is int) return value.toDouble();
              if (value is String) {
                try {
                  return double.parse(value);
                } catch (e) {
                  debugPrint('Error parsing double: $value, $e');
                  return 0.0;
                }
              }
              return 0.0;
            }
            
            // Create a new map with properly converted values
            final Map<String, dynamic> processedItem = Map<String, dynamic>.from(item);
            
            // Convert string values to appropriate types
            if (processedItem.containsKey('total_amount')) {
              processedItem['total_amount'] = parseDoubleSafely(processedItem['total_amount']);
            }
            
            return processedItem;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting purchase orders: $e');
      return [];
    }
  }

  // PurchaseOrderItem-related methods
  @override
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String orderId) async {
    if (!_isConnected) {
      return [];
    }
    
    try {
      final response = await http.get(Uri.parse('$_apiUrl/purchase-order-items/order/$orderId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> purchaseOrderItemsData = data['data'];
          return List<Map<String, dynamic>>.from(purchaseOrderItemsData);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting purchase order items: $e');
      return [];
    }
  }

  // Stub implementations for the remaining methods
  Future<String> addClient(Client client) async => '';
  Future<void> updateClient(Client client) async {}
  Future<void> deleteClient(String id) async {}
  Future<String> addEvent(Event event) async => '';
  Future<void> updateEvent(Event event) async {}
  Future<void> deleteEvent(String id) async {}
  Future<String> addQuote(Quote quote) async => '';
  Future<void> updateQuote(Quote quote) async {}
  Future<void> deleteQuote(String id) async {}
  Future<String> addQuoteItem(QuoteItem item) async => '';
  Future<void> updateQuoteItem(QuoteItem item) async {}
  Future<void> deleteQuoteItem(String id) async {}
  Future<String> addDish(Dish dish) async => '';
  Future<void> updateDish(Dish dish) async {}
  Future<void> deleteDish(String id) async {}
  Future<String> addMenuPackage(MenuPackage package) async => '';
  Future<void> updateMenuPackage(MenuPackage package) async {}
  Future<void> deleteMenuPackage(String id) async {}
  Future<String> addPackageItem(PackageItem item) async => '';
  Future<void> updatePackageItem(PackageItem item) async {}
  Future<void> deletePackageItem(String id) async {}
  Future<String> addInventoryItem(Map<String, dynamic> item) async => '';
  Future<void> updateInventoryItem(Map<String, dynamic> item) async {}
  Future<void> deleteInventoryItem(String id) async {}
  Future<String> addSupplier(Map<String, dynamic> supplier) async => '';
  Future<void> updateSupplier(Map<String, dynamic> supplier) async {}
  Future<void> deleteSupplier(String id) async {}
  Future<String> addPurchaseOrder(Map<String, dynamic> order) async => '';
  Future<void> updatePurchaseOrder(Map<String, dynamic> order) async {}
  Future<void> deletePurchaseOrder(String id) async {}
  Future<String> addPurchaseOrderItem(Map<String, dynamic> item) async => '';
  Future<void> updatePurchaseOrderItem(Map<String, dynamic> item) async {}
  Future<void> deletePurchaseOrderItem(String id) async {}
  Future<Client?> getClient(String id) async => null;
  Future<Event?> getEvent(String id) async => null;
  Future<Quote?> getQuote(String id) async => null;
  Future<QuoteItem?> getQuoteItem(String id) async => null;
  Future<Dish?> getDish(String id) async => null;
  Future<MenuPackage?> getMenuPackage(String id) async => null;
  Future<PackageItem?> getPackageItem(String id) async => null;
  Future<Map<String, dynamic>?> getInventoryItem(String id) async => null;
  Future<Map<String, dynamic>?> getSupplier(String id) async => null;
  Future<Map<String, dynamic>?> getPurchaseOrder(String id) async => null;
  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id) async => null;
  Future<void> initializeDatabase() async {}
}