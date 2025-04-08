# Catererer App

A Flutter application for catering business management.

## Setup and Running Instructions

### Database Setup

1. Set up MySQL database:
   ```bash
   mysql -u root -p < setup_mysql.sql
   mysql -u flutteruser -pflutterpassword catererer_db < database_schema.sql
   ```

### Running as Desktop App

The app can be run directly as a desktop application:

```bash
cd catererer_app
flutter run -d windows  # or macos or linux
```

When running as a desktop app, it will connect directly to the MySQL database.

### Running as Web App

To run as a web app, you need to:

1. Start the API server:
   ```bash
   cd api_server
   dart pub get
   dart run bin/server.dart
   ```

2. Run the Flutter web app:
   ```bash
   cd catererer_app
   flutter run -d chrome
   ```

The web app will connect to the MySQL database through the API server.

## Database Configuration

Default database settings:
- Host: localhost
- Port: 3306
- Username: flutteruser
- Password: flutterpassword
- Database: catererer_db
- API URL (web only): http://localhost:8080/api

You can change these settings in the app's Settings tab.

## Testing Database Connection

You can test the database connection using:

```bash
cd catererer_app
dart run bin/mysql_client_test.dart
```

For more detailed diagnostics:

```bash
dart run bin/db_connection_test.dart
```
