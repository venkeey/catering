import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'database_service_interface.dart';
import 'web_database_service.dart';

/// Factory class that provides the appropriate database service based on platform
class DatabaseServiceFactory {
  // Singleton pattern
  static final DatabaseServiceFactory _instance = DatabaseServiceFactory._internal();
  factory DatabaseServiceFactory() => _instance;
  DatabaseServiceFactory._internal();
  
  /// Get the appropriate database service based on the current platform
  DatabaseServiceInterface getDatabaseService() {
    if (kIsWeb) {
      return WebDatabaseService();
    } else {
      return DatabaseService();
    }
  }
}