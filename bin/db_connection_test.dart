import 'package:mysql_client/mysql_client.dart';

void main() async {
  print('Starting MySQL connection diagnostic test...');
  
  // Connection parameters
  const String host = "localhost";
  const int port = 3306;
  const String userName = "flutteruser";
  const String password = "flutterpassword";
  const String databaseName = "catererer_db";
  
  MySQLConnection? conn;
  try {
    print('Step 1: Attempting to connect to MySQL server without specifying a database...');
    
    // First try connecting without a database to check if the server is accessible
    conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: userName,
      password: password,
    );
    
    await conn.connect();
    print('✓ Successfully connected to MySQL server');
    await conn.close();
    
    print('\nStep 2: Checking if database exists...');
    conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: userName,
      password: password,
    );
    
    await conn.connect();
    final dbResults = await conn.execute("SHOW DATABASES LIKE '$databaseName'");
    
    if (dbResults.rows.isEmpty) {
      print('✗ Database "$databaseName" does not exist');
      print('\nAttempting to create database...');
      try {
        await conn.execute("CREATE DATABASE IF NOT EXISTS $databaseName");
        print('✓ Database created successfully');
      } catch (e) {
        print('✗ Failed to create database: $e');
        print('  This might be due to insufficient privileges');
      }
    } else {
      print('✓ Database "$databaseName" exists');
    }
    
    await conn.close();
    
    print('\nStep 3: Testing connection to the specific database...');
    conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: userName,
      password: password,
      databaseName: databaseName,
    );
    
    await conn.connect();
    print('✓ Successfully connected to database "$databaseName"');
    
    print('\nStep 4: Checking if tables exist...');
    final tableResults = await conn.execute("SHOW TABLES");
    
    if (tableResults.rows.isEmpty) {
      print('✗ No tables found in database "$databaseName"');
      print('  You may need to run the database_schema.sql script to create tables');
    } else {
      print('✓ Found ${tableResults.rows.length} tables in database:');
      for (final row in tableResults.rows) {
        print('  - ${row.colAt(0)}');
      }
    }
    
    print('\nConnection test completed successfully!');
    
  } catch (e) {
    print('\n✗ ERROR: $e');
    
    if (e.toString().contains('Access denied')) {
      print('\nPossible solutions:');
      print('1. Check if the MySQL user "flutteruser" exists');
      print('2. Verify the password is correct');
      print('3. Ensure the user has proper permissions');
      print('\nYou can create the user with these commands in MySQL:');
      print('   CREATE USER \'flutteruser\'@\'localhost\' IDENTIFIED BY \'flutterpassword\';');
      print('   GRANT ALL PRIVILEGES ON catererer_db.* TO \'flutteruser\'@\'localhost\';');
      print('   FLUSH PRIVILEGES;');
    } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed to connect')) {
      print('\nPossible solutions:');
      print('1. Check if MySQL server is running');
      print('2. Verify the host and port are correct');
      print('3. Check if any firewall is blocking the connection');
    } else if (e.toString().contains('Unknown database')) {
      print('\nPossible solutions:');
      print('1. Create the database using the database_schema.sql script');
      print('2. Run this command in MySQL:');
      print('   CREATE DATABASE catererer_db;');
    }
  } finally {
    if (conn != null) {
      print('Closing connection...');
      await conn.close();
    }
  }
}