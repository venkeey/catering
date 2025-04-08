import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_state.dart';
import 'screens/quotes_screen.dart';
import 'screens/database_settings_screen.dart';
import 'screens/menu_packages_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/purchase_orders_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/events_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/database_service.dart';
import 'services/database_service_factory.dart';
import 'services/simple_web_database_service.dart';

void main() {
  debugPrint('Starting application...');
  debugPrint('Is Web Platform: ${kIsWeb}');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: Building app');
    debugPrint('MyApp: Is Web Platform: ${kIsWeb}');
    
    // Use the factory to get the appropriate database service
    final dbService = kIsWeb 
        ? SimpleWebDatabaseService() 
        : DatabaseService();
    
    debugPrint('MyApp: Using database service: ${dbService.runtimeType}');
    
    return ChangeNotifierProvider(
      create: (context) => AppState(dbService),
      child: MaterialApp(
        title: 'Catererer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ClientsScreen(),
    const EventsScreen(),
    const QuotesScreen(),
    const MenuPackagesScreen(),
    const InventoryScreen(),
    const SuppliersScreen(),
    const PurchaseOrdersScreen(),
    const DatabaseSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    if (appState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Even if there's an error, we'll continue to the main app
    // The database settings can still be accessed from the bottom navigation bar

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Packages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Suppliers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 