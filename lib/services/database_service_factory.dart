import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'database_service_interface.dart';
import 'web_database_service.dart';
import 'simple_web_database_service.dart';

/// Factory class that provides the appropriate database service based on platform
class DatabaseServiceFactory {
  // Singleton pattern
  static final DatabaseServiceFactory _instance = DatabaseServiceFactory._internal();
  factory DatabaseServiceFactory() => _instance;
  DatabaseServiceFactory._internal();
  
  /// Get the appropriate database service based on the current platform
  DatabaseServiceInterface getDatabaseService() {
    debugPrint('DatabaseServiceFactory: Getting database service for platform');
    debugPrint('DatabaseServiceFactory: Is Web Platform: ${kIsWeb}');
    
    if (kIsWeb) {
      debugPrint('DatabaseServiceFactory: Using SimpleWebDatabaseService for web platform');
      return SimpleWebDatabaseService();
    } else {
      debugPrint('DatabaseServiceFactory: Using DatabaseService for non-web platform');
      return DatabaseService();
    }
  }
}