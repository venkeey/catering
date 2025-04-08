import 'database_service_interface.dart';

/// Interface for web-specific database service operations
abstract class WebDatabaseServiceInterface extends DatabaseServiceInterface {
  /// The API URL for web database operations
  String get apiUrl;
  
  /// Save connection settings
  @override
  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
  });
  
  /// Save API URL for web connection
  Future<void> saveApiUrl(String apiUrl);
}