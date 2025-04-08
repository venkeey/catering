import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web-specific base class for database services that doesn't try to connect to MySQL directly
class WebBaseDatabaseService {
  // Singleton pattern
  static final WebBaseDatabaseService _instance = WebBaseDatabaseService._internal();
  factory WebBaseDatabaseService() => _instance;
  WebBaseDatabaseService._internal();

  // Connection state
  bool _isConnected = false;
  
  // Connection settings (stored for UI display only)
  String _host = 'localhost';
  int _port = 3306;
  String _user = 'flutteruser';
  String _password = 'flutterpassword';
  String _db = 'catererer_db';
  String _apiUrl = 'http://localhost:8080/api';

  // Getters for connection settings
  bool get isConnected => _isConnected;
  String get host => _host;
  int get port => _port;
  String get user => _user;
  String get password => _password;
  String get db => _db;
  String get apiUrl => _apiUrl;

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
    _apiUrl = prefs.getString('api_url') ?? 'http://localhost:8080/api';
  }
  
  // Save connection settings to SharedPreferences
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
  
  // Set connection state
  void setConnected(bool connected) {
    _isConnected = connected;
  }
}