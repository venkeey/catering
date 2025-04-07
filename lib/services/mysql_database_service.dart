import 'package:mysql_client/mysql_client.dart';
import 'dart:async';

class MySQLDatabaseService {
  static MySQLDatabaseService? _instance;
  MySQLConnectionPool? _pool;
  MySQLConnection? _connection;
  bool _isConnected = false;
  
  // Singleton pattern
  factory MySQLDatabaseService() {
    _instance ??= MySQLDatabaseService._internal();
    return _instance!;
  }
  
  MySQLDatabaseService._internal();
  
  // Getter for connection status
  bool get isConnected => _isConnected;
  
  // Initialize connection pool
  Future<void> initializePool({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String databaseName,
    int maxConnections = 10,
  }) async {
    try {
      _pool = MySQLConnectionPool(
        host: host,
        port: port,
        userName: userName,
        password: password,
        maxConnections: maxConnections,
        databaseName: databaseName,
      );
      
      // Test the connection
      final result = await _pool!.execute("SELECT 1 as test_value");
      if (result.rows.isNotEmpty) {
        _isConnected = true;
        print("MySQL connection pool initialized successfully");
      } else {
        _isConnected = false;
        print("MySQL connection pool initialized but test query returned no results");
      }
    } catch (e) {
      _isConnected = false;
      print("Error initializing MySQL connection pool: $e");
      rethrow;
    }
  }
  
  // Initialize single connection
  Future<void> initializeConnection({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String databaseName,
  }) async {
    try {
      _connection = await MySQLConnection.createConnection(
        host: host,
        port: port,
        userName: userName,
        password: password,
        databaseName: databaseName,
      );
      
      await _connection!.connect();
      _isConnected = true;
      print("MySQL connection initialized successfully");
    } catch (e) {
      _isConnected = false;
      print("Error initializing MySQL connection: $e");
      rethrow;
    }
  }
  
  // Execute a query using the connection pool
  Future<IResultSet> executeQuery(String query, [Map<String, dynamic>? params]) async {
    if (_pool == null) {
      throw Exception("Connection pool not initialized");
    }
    
    try {
      return await _pool!.execute(query, params ?? {});
    } catch (e) {
      print("Error executing query: $e");
      rethrow;
    }
  }
  
  // Execute a query using the single connection
  Future<IResultSet> executeQueryWithConnection(String query, [Map<String, dynamic>? params]) async {
    if (_connection == null) {
      throw Exception("Connection not initialized");
    }
    
    try {
      return await _connection!.execute(query, params ?? {});
    } catch (e) {
      print("Error executing query: $e");
      rethrow;
    }
  }
  
  // Execute a transaction
  Future<T> transaction<T>(Future<T> Function(MySQLConnection) action) async {
    if (_pool == null) {
      throw Exception("Connection pool not initialized");
    }
    
    return await _pool!.transactional(action);
  }
  
  // Close connections
  Future<void> close() async {
    if (_pool != null) {
      await _pool!.close();
      _pool = null;
    }
    
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
    
    _isConnected = false;
    print("MySQL connections closed");
  }
  
  // Helper method to convert result set to list of maps
  List<Map<String, dynamic>> resultSetToMapList(IResultSet resultSet) {
    return resultSet.rows.map((row) => row.assoc()).toList();
  }
} 