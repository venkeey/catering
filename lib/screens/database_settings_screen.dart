import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service_factory.dart';
import '../services/database_service_interface.dart';
import '../services/database_service.dart';
import '../services/web_database_service_interface.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  State<DatabaseSettingsScreen> createState() => _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbController = TextEditingController();
  final _apiUrlController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _dbController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final dbServiceFactory = DatabaseServiceFactory();
    final dbService = dbServiceFactory.getDatabaseService();
    await dbService.loadConnectionSettings();
    
    setState(() {
      _hostController.text = dbService.host;
      _portController.text = dbService.port.toString();
      _userController.text = dbService.user;
      _passwordController.text = dbService.password;
      _dbController.text = dbService.db;
      _isConnected = dbService.isConnected;
      
      if (kIsWeb && dbService is WebDatabaseServiceInterface) {
        _apiUrlController.text = dbService.apiUrl;
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing connection...';
    });

    try {
      final dbServiceFactory = DatabaseServiceFactory();
      final dbService = dbServiceFactory.getDatabaseService();
      
      if (kIsWeb && dbService is WebDatabaseServiceInterface) {
        await dbService.saveConnectionSettings(
          host: _hostController.text,
          port: int.parse(_portController.text),
          user: _userController.text,
          password: _passwordController.text,
          db: _dbController.text,
        );
        await dbService.saveApiUrl(_apiUrlController.text);
      } else {
        await dbService.saveConnectionSettings(
          host: _hostController.text,
          port: int.parse(_portController.text),
          user: _userController.text,
          password: _passwordController.text,
          db: _dbController.text,
        );
      }

      final success = await dbService.testConnection();
      
      setState(() {
        _isLoading = false;
        _statusMessage = success 
            ? 'Connection successful!' 
            : 'Connection failed. Please check your settings.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to database...';
    });

    try {
      final dbServiceFactory = DatabaseServiceFactory();
      final dbService = dbServiceFactory.getDatabaseService();
      
      if (kIsWeb && dbService is WebDatabaseServiceInterface) {
        await dbService.saveConnectionSettings(
          host: _hostController.text,
          port: int.parse(_portController.text),
          user: _userController.text,
          password: _passwordController.text,
          db: _dbController.text,
        );
        await dbService.saveApiUrl(_apiUrlController.text);
      } else {
        await dbService.saveConnectionSettings(
          host: _hostController.text,
          port: int.parse(_portController.text),
          user: _userController.text,
          password: _passwordController.text,
          db: _dbController.text,
        );
      }

      final success = await dbService.connect();
      
      if (success && !kIsWeb && dbService is DatabaseService) {
        await dbService.initializeDatabase();
      }
      
      setState(() {
        _isLoading = false;
        _isConnected = dbService.isConnected;
        _statusMessage = success 
            ? 'Connected to database successfully!' 
            : 'Failed to connect to database.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Disconnecting...';
    });

    try {
      final dbServiceFactory = DatabaseServiceFactory();
      final dbService = dbServiceFactory.getDatabaseService();
      await dbService.disconnect();
      
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Disconnected from database.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host',
                  hintText: 'localhost',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '3306',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid port number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'root',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dbController,
                decoration: const InputDecoration(
                  labelText: 'Database Name',
                  hintText: 'catererer_db',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a database name';
                  }
                  return null;
                },
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'API URL',
                    hintText: 'http://localhost:8080/api',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the API URL';
                    }
                    if (!value.startsWith('http')) {
                      return 'URL should start with http:// or https://';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.contains('successful') 
                          ? Colors.green 
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: const Text('Test Connection'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading 
                          ? null 
                          : (_isConnected ? _disconnect : _connect),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isConnected ? Colors.red : Colors.green,
                      ),
                      child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 