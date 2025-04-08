import 'package:flutter/foundation.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/database_helper.dart';

/// Base class for database services that handles connection and common functionality
class BaseDatabaseService {
  // Singleton pattern
  static final BaseDatabaseService _instance = BaseDatabaseService._internal();
  factory BaseDatabaseService() => _instance;
  BaseDatabaseService._internal();

  // Database connection
  MySQLConnection? _connection;
  bool _isConnected = false;
  
  // Connection settings
  String _host = 'localhost';
  int _port = 3306;
  String _user = 'flutteruser';
  String _password = 'flutterpassword';
  String _db = 'catererer_db';

  // Getters for connection settings
  bool get isConnected => _isConnected;
  String get host => _host;
  int get port => _port;
  String get user => _user;
  String get password => _password;
  String get db => _db;
  MySQLConnection? get connection => _connection;

  // Initialize connection settings from SharedPreferences
  Future<void> initialize() async {
    await loadConnectionSettings();
  }
  
  // Load connection settings from SharedPreferences
  Future<void> loadConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _host = prefs.getString('db_host') ?? 'localhost';
    _port = prefs.getInt('db_port') ?? 3306;
    _user = prefs.getString('db_user') ?? 'flutteruser';
    _password = prefs.getString('db_password') ?? 'flutterpassword';
    _db = prefs.getString('db_name') ?? 'catererer_db';
  }
  
  // Save connection settings to SharedPreferences
  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
  }) async {
    _host = host;
    _port = port;
    _user = user;
    _password = password;
    _db = db;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_host', host);
    await prefs.setInt('db_port', port);
    await prefs.setString('db_user', user);
    await prefs.setString('db_password', password);
    await prefs.setString('db_name', db);
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

  // Initialize the database schema and tables
  Future<void> initializeDatabase() async {
    if (!_isConnected) {
      throw Exception('Database not connected');
    }
    
    try {
      debugPrint('Initializing database schema...');
      await _createTablesIfNotExist();
      debugPrint('Database initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  // Create database tables if they don't exist
  Future<void> _createTablesIfNotExist() async {
    // Create clients table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS clients (
        client_id INT AUTO_INCREMENT PRIMARY KEY,
        client_name VARCHAR(255) NOT NULL,
        contact_person VARCHAR(255),
        phone1 VARCHAR(50),
        phone2 VARCHAR(50),
        email1 VARCHAR(255),
        email2 VARCHAR(255),
        billing_address TEXT,
        company_name VARCHAR(255),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create events table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS events (
        event_id INT AUTO_INCREMENT PRIMARY KEY,
        client_id INT NOT NULL,
        event_name VARCHAR(255) NOT NULL,
        event_date DATE,
        venue_address TEXT,
        event_type VARCHAR(100),
        total_guest_count INT,
        guests_male INT,
        guests_female INT,
        guests_elderly INT,
        guests_youth INT,
        guests_child INT,
        status VARCHAR(50) DEFAULT 'Planning',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE
      )
    ''');
    
    // Create dishes table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS dishes (
        dish_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        category_id VARCHAR(100),
        category VARCHAR(100),
        base_price DECIMAL(10,2),
        base_food_cost DECIMAL(10,2),
        standard_portion_size DECIMAL(10,2),
        description TEXT,
        image_url VARCHAR(255),
        dietary_tags VARCHAR(255),
        item_type VARCHAR(50) DEFAULT 'Standard',
        is_active TINYINT(1) DEFAULT 1,
        ingredients TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create menu_packages table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS menu_packages (
        package_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        base_price DECIMAL(10,2),
        is_active TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create package_items table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS package_items (
        item_id INT AUTO_INCREMENT PRIMARY KEY,
        package_id INT NOT NULL,
        dish_id INT NOT NULL,
        is_optional TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (package_id) REFERENCES menu_packages(package_id) ON DELETE CASCADE,
        FOREIGN KEY (dish_id) REFERENCES dishes(dish_id) ON DELETE CASCADE
      )
    ''');
    
    // Create quotes table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS quotes (
        quote_id INT AUTO_INCREMENT PRIMARY KEY,
        event_id INT,
        client_id INT NOT NULL,
        quote_date DATE,
        total_guest_count INT,
        guests_male INT,
        guests_female INT,
        guests_elderly INT,
        guests_youth INT,
        guests_child INT,
        calculation_method VARCHAR(50) DEFAULT 'Simple',
        overhead_percentage DECIMAL(5,2) DEFAULT 30.00,
        calculated_total_food_cost DECIMAL(10,2),
        calculated_overhead_cost DECIMAL(10,2),
        grand_total DECIMAL(10,2),
        notes TEXT,
        terms_and_conditions TEXT,
        status VARCHAR(50) DEFAULT 'Draft',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE SET NULL,
        FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE CASCADE
      )
    ''');
    
    // Create quote_items table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS quote_items (
        item_id INT AUTO_INCREMENT PRIMARY KEY,
        quote_id INT NOT NULL,
        dish_id INT NOT NULL,
        quoted_portion_size_grams DECIMAL(10,2),
        quoted_base_food_cost_per_serving DECIMAL(10,2),
        percentage_take_rate DECIMAL(5,2),
        estimated_servings INT,
        estimated_total_weight_grams DECIMAL(10,2),
        estimated_item_food_cost DECIMAL(10,2),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (quote_id) REFERENCES quotes(quote_id) ON DELETE CASCADE,
        FOREIGN KEY (dish_id) REFERENCES dishes(dish_id) ON DELETE CASCADE
      )
    ''');
    
    // Create inventory_items table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        item_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        unit VARCHAR(50) NOT NULL,
        unit_cost DECIMAL(10,2) NOT NULL,
        quantity_in_stock DECIMAL(10,2) DEFAULT 0,
        reorder_level DECIMAL(10,2) DEFAULT 0,
        supplier_id INT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    ''');
    
    // Create suppliers table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS suppliers (
        supplier_id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        contact_person VARCHAR(255),
        phone VARCHAR(50),
        email VARCHAR(255),
        address TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    
    // Create purchase_orders table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS purchase_orders (
        order_id INT AUTO_INCREMENT PRIMARY KEY,
        supplier_id INT,
        order_date DATE NOT NULL,
        expected_delivery_date DATE,
        status VARCHAR(50) DEFAULT 'Pending',
        total_amount DECIMAL(10,2) DEFAULT 0,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE SET NULL
      )
    ''');
    
    // Create purchase_order_items table
    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS purchase_order_items (
        item_id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        inventory_item_id INT,
        quantity DECIMAL(10,2) NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES purchase_orders(order_id) ON DELETE CASCADE,
        FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(item_id) ON DELETE SET NULL
      )
    ''');
  }
  
  // Test connection without storing it
  Future<bool> testConnection() async {
    try {
      debugPrint('Testing MySQL connection...');
      debugPrint('Host: $_host');
      debugPrint('Port: $_port');
      debugPrint('User: $_user');
      debugPrint('Database: $_db');
      
      final conn = await MySQLConnection.createConnection(
        host: _host,
        port: _port,
        userName: _user,
        password: _password,
        databaseName: _db,
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
  
  // Test connection with specific parameters without storing them
  Future<bool> testConnectionWithParams({
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
      final success = await testConnectionWithParams(
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
  Map<String, dynamic> prepareParams(List<dynamic> params) {
    final Map<String, dynamic> namedParams = {};
    for (var i = 0; i < params.length; i++) {
      namedParams['p$i'] = params[i];
    }
    return namedParams;
  }

  // Helper method to replace ? placeholders with named parameters
  String replacePlaceholders(String query) {
    var index = 0;
    return query.replaceAllMapped(RegExp(r'\?'), (match) {
      return ':p${index++}';
    });
  }
}