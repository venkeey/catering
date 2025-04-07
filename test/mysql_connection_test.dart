import 'package:flutter_test/flutter_test.dart';
import 'package:mysql1/mysql1.dart';

void main() {
  test('MySQL Connection Test', () async {
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
      conn = await MySqlConnection.connect(settings);
      print('Successfully connected to MySQL database');
      
      // Test a simple query
      print('Executing test query...');
      final results = await conn.query('SELECT 1 as test_value');
      
      if (results.isEmpty) {
        print('Query returned no results');
        fail('Query returned no results');
      }
      
      final firstRow = results.first;
      if (!firstRow.fields.containsKey('test_value')) {
        print('Query result does not contain expected field "test_value"');
        print('Available fields: ${firstRow.fields.keys.join(', ')}');
        fail('Query result missing expected field');
      }
      
      final testValue = firstRow['test_value'];
      print('Query result: test_value = $testValue');
      
      expect(testValue, equals(1), reason: 'Expected test query to return 1');
      
    } catch (e, stackTrace) {
      print('Error during MySQL test: $e');
      print('Stack trace: $stackTrace');
      fail('MySQL test failed: $e');
    } finally {
      if (conn != null) {
        print('Closing connection...');
        await conn.close();
        print('Connection closed');
      }
    }
  });
} 