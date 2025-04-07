import 'package:flutter_test/flutter_test.dart';
import 'package:mysql_client/mysql_client.dart';

void main() {
  test('MySQL Connection Test', () async {
    print('Starting MySQL connection test with mysql_client package...');
    
    MySQLConnection? conn;
    try {
      print('Attempting to connect to MySQL database...');
      
      // Create connection
      conn = await MySQLConnection.createConnection(
        host: "localhost",
        port: 3306,
        userName: "flutteruser",
        password: "flutterpassword",
        databaseName: "catererer_db",
      );
      
      print('Connecting to database...');
      await conn.connect();
      print('Successfully connected to MySQL database');
      
      // Test a simple query
      print('Executing test query...');
      final result = await conn.execute("SELECT 1 as test_value");
      
      if (result.rows.isEmpty) {
        print('Query returned no results');
        fail('Query returned no results');
        return;
      }
      
      final firstRow = result.rows.first;
      final rowMap = firstRow.assoc();
      
      if (!rowMap.containsKey('test_value')) {
        print('Query result does not contain expected field "test_value"');
        print('Available fields: ${rowMap.keys.join(', ')}');
        fail('Query result does not contain expected field "test_value"');
        return;
      }
      
      final testValue = firstRow.typedColAt<int>(0);
      print('Query result: test_value = $testValue');
      
      expect(testValue, 1, reason: 'Expected test_value to be 1');
      print('Test passed successfully!');
      
    } catch (e, stackTrace) {
      print('Error during MySQL test: $e');
      print('Stack trace: $stackTrace');
      fail('MySQL connection test failed: $e');
    } finally {
      if (conn != null) {
        print('Closing connection...');
        await conn.close();
        print('Connection closed');
      }
    }
  });
} 