import 'package:mysql1/mysql1.dart';

void main() async {
  print('Starting MySQL connection test...');
  
  final settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'flutteruser',
    password: 'flutterpassword',
    db: 'catererer_db',
    timeout: Duration(seconds: 30),
    maxPacketSize: 33554432,
    useSSL: false,
    useCompression: false,
  );

  MySqlConnection? conn;
  try {
    print('Attempting to connect to MySQL database...');
    print('Host: ${settings.host}');
    print('Port: ${settings.port}');
    print('User: ${settings.user}');
    print('Database: ${settings.db}');
    
    conn = await MySqlConnection.connect(settings);
    print('Successfully connected to MySQL database');
    
    // Test a simple query
    print('Executing test query...');
    final results = await conn.query('SELECT 1 as test_value');
    
    if (results.isEmpty) {
      print('Query returned no results');
      return;
    }
    
    final firstRow = results.first;
    if (!firstRow.fields.containsKey('test_value')) {
      print('Query result does not contain expected field "test_value"');
      print('Available fields: ${firstRow.fields.keys.join(', ')}');
      return;
    }
    
    final testValue = firstRow['test_value'];
    print('Query result: test_value = $testValue');
    
    if (testValue != 1) {
      print('Expected test_value to be 1, but got $testValue');
    } else {
      print('Test passed successfully!');
    }
    
  } catch (e, stackTrace) {
    print('Error during MySQL test: $e');
    print('Stack trace: $stackTrace');
  } finally {
    if (conn != null) {
      print('Closing connection...');
      await conn.close();
      print('Connection closed');
    }
  }
} 