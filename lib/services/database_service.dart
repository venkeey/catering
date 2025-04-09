import 'dart:async';
import '../models/client.dart';
import '../models/dish.dart';
import '../models/event.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/menu_package.dart';
import '../models/package_item.dart';
import 'database/base_database_service.dart';
import 'database/client_database_service.dart';
import 'database/dish_database_service.dart';
import 'database/event_database_service.dart';
import 'database/inventory_database_service.dart';
import 'database/menu_package_database_service.dart';
import 'database/package_item_database_service.dart';
import 'database/purchase_order_database_service.dart';
import 'database/quote_database_service.dart';
import 'database/quote_item_database_service.dart';
import 'database/supplier_database_service.dart';
import 'database_service_interface.dart';

/// Implementation of the DatabaseServiceInterface for MySQL database
/// This class delegates to specialized service classes for each entity type
class DatabaseService implements DatabaseServiceInterface {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  // Base service and specialized services
  final BaseDatabaseService _baseService;
  late final ClientDatabaseService _clientService;
  late final EventDatabaseService _eventService;
  late final DishDatabaseService _dishService;
  late final QuoteItemDatabaseService _quoteItemService;
  late final QuoteDatabaseService _quoteService;
  late final PackageItemDatabaseService _packageItemService;
  late final MenuPackageDatabaseService _menuPackageService;
  late final InventoryDatabaseService _inventoryService;
  late final SupplierDatabaseService _supplierService;
  late final PurchaseOrderDatabaseService _purchaseOrderService;

  DatabaseService._internal() : _baseService = BaseDatabaseService() {
    // Initialize specialized services
    _dishService = DishDatabaseService(_baseService);
    _packageItemService = PackageItemDatabaseService(_baseService, _dishService);
    _menuPackageService = MenuPackageDatabaseService(_baseService, _packageItemService);
    _clientService = ClientDatabaseService(_baseService);
    _eventService = EventDatabaseService(_baseService);
    _inventoryService = InventoryDatabaseService(_baseService);
    _supplierService = SupplierDatabaseService(_baseService);
    _purchaseOrderService = PurchaseOrderDatabaseService(_baseService);
    
    // Initialize quote services
    _quoteItemService = QuoteItemDatabaseService(_baseService, _dishService);
    _quoteService = QuoteDatabaseService(_baseService, _quoteItemService);
  }

  // Connection properties
  @override
  bool get isConnected => _baseService.isConnected;
  
  @override
  String get host => _baseService.host;
  
  @override
  int get port => _baseService.port;
  
  @override
  String get user => _baseService.user;
  
  @override
  String get password => _baseService.password;
  
  @override
  String get db => _baseService.db;

  // Connection methods
  @override
  Future<void> initialize() async {
    await _baseService.initialize();
  }
  
  @override
  Future<void> loadConnectionSettings() async {
    await _baseService.loadConnectionSettings();
  }
  
  @override
  Future<bool> connect() async {
    return await _baseService.connect();
  }
  
  @override
  Future<void> disconnect() async {
    await _baseService.disconnect();
  }
  
  @override
  Future<bool> testConnection() async {
    return await _baseService.testConnection();
  }
  
  @override
  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
  }) async {
    await _baseService.saveConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
  }

  // Initialize database schema
  Future<void> initializeDatabase() async {
    await _baseService.initializeDatabase();
  }

  // Update connection settings
  Future<bool> updateConnectionSettings({
    required String host,
    required int port,
    required String userName,
    required String password,
    required String db,
  }) async {
    return await _baseService.updateConnectionSettings(
      host: host,
      port: port,
      userName: userName,
      password: password,
      db: db,
    );
  }

  // Client methods
  @override
  Future<List<Client>> getClients() async {
    return await _clientService.getClients();
  }
  
  @override
  Future<Client?> getClient(String id) async {
    return await _clientService.getClient(id);
  }
  
  @override
  Future<String> addClient(Client client) async {
    return await _clientService.addClient(client);
  }
  
  @override
  Future<void> updateClient(Client client) async {
    await _clientService.updateClient(client);
  }
  
  @override
  Future<void> deleteClient(String id) async {
    await _clientService.deleteClient(id);
  }

  // Event methods
  @override
  Future<List<Event>> getEvents() async {
    return await _eventService.getEvents();
  }
  
  @override
  Future<Event?> getEvent(String id) async {
    return await _eventService.getEvent(id);
  }
  
  @override
  Future<String> addEvent(Event event) async {
    return await _eventService.addEvent(event);
  }
  
  @override
  Future<void> updateEvent(Event event) async {
    await _eventService.updateEvent(event);
  }
  
  @override
  Future<void> deleteEvent(String id) async {
    await _eventService.deleteEvent(id);
  }

  // Quote methods
  @override
  Future<List<Quote>> getQuotes() async {
    return await _quoteService.getQuotes();
  }
  
  @override
  Future<Quote?> getQuote(String id) async {
    return await _quoteService.getQuote(id);
  }
  
  @override
  Future<List<Quote>> getQuotesByClient(String clientId) async {
    return await _quoteService.getQuotesByClient(clientId);
  }
  
  @override
  Future<String> addQuote(Quote quote) async {
    return await _quoteService.addQuote(quote);
  }
  
  @override
  Future<void> updateQuote(Quote quote) async {
    await _quoteService.updateQuote(quote);
  }
  
  @override
  Future<void> deleteQuote(String id) async {
    await _quoteService.deleteQuote(id);
  }

  // QuoteItem methods
  @override
  Future<List<QuoteItem>> getQuoteItems() async {
    return await _quoteItemService.getQuoteItems();
  }
  
  @override
  Future<List<QuoteItem>> getQuoteItemsForQuote(String quoteId) async {
    return await _quoteItemService.getQuoteItemsForQuote(quoteId);
  }
  
  @override
  Future<String> addQuoteItem(QuoteItem item) async {
    final result = await _quoteItemService.addQuoteItem(item);
    return result.toString();
  }
  
  @override
  Future<void> updateQuoteItem(QuoteItem item) async {
    await _quoteItemService.updateQuoteItem(item);
  }
  
  @override
  Future<void> deleteQuoteItem(String id) async {
    await _quoteItemService.deleteQuoteItem(id);
  }

  // Dish methods
  @override
  Future<List<Dish>> getDishes() async {
    return await _dishService.getDishes();
  }
  
  @override
  Future<Dish?> getDish(String id) async {
    return await _dishService.getDish(id);
  }
  
  @override
  Future<String> addDish(Dish dish) async {
    return await _dishService.addDish(dish);
  }
  
  @override
  Future<void> updateDish(Dish dish) async {
    await _dishService.updateDish(dish);
  }
  
  @override
  Future<void> deleteDish(String id) async {
    await _dishService.deleteDish(id);
  }

  // MenuPackage methods
  @override
  Future<List<MenuPackage>> getMenuPackages() async {
    return await _menuPackageService.getMenuPackages();
  }
  
  @override
  Future<MenuPackage?> getMenuPackage(String id) async {
    return await _menuPackageService.getMenuPackage(id);
  }
  
  @override
  Future<String> addMenuPackage(MenuPackage package) async {
    return await _menuPackageService.addMenuPackage(package);
  }
  
  @override
  Future<void> updateMenuPackage(MenuPackage package) async {
    await _menuPackageService.updateMenuPackage(package);
  }
  
  @override
  Future<void> deleteMenuPackage(String id) async {
    await _menuPackageService.deleteMenuPackage(id);
  }

  // PackageItem methods
  @override
  Future<List<PackageItem>> getPackageItems() async {
    return await _packageItemService.getPackageItems();
  }
  
  @override
  Future<List<PackageItem>> getPackageItemsForPackage(String packageId) async {
    return await _packageItemService.getPackageItemsForPackage(packageId);
  }
  
  @override
  Future<String> addPackageItem(PackageItem item) async {
    return await _packageItemService.addPackageItem(item);
  }
  
  @override
  Future<void> updatePackageItem(PackageItem item) async {
    await _packageItemService.updatePackageItem(item);
  }
  
  @override
  Future<void> deletePackageItem(String id) async {
    await _packageItemService.deletePackageItem(id);
  }

  // Inventory methods
  @override
  Future<List<Map<String, dynamic>>> getInventoryItems() async {
    return await _inventoryService.getInventoryItems();
  }
  
  @override
  Future<Map<String, dynamic>?> getInventoryItem(String id) async {
    return await _inventoryService.getInventoryItem(id);
  }
  
  @override
  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    return await _inventoryService.addInventoryItem(item);
  }
  
  @override
  Future<void> updateInventoryItem(Map<String, dynamic> item) async {
    await _inventoryService.updateInventoryItem(item);
  }
  
  @override
  Future<void> deleteInventoryItem(String id) async {
    await _inventoryService.deleteInventoryItem(id);
  }

  // Supplier methods
  @override
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    return await _supplierService.getSuppliers();
  }
  
  @override
  Future<Map<String, dynamic>?> getSupplier(String id) async {
    return await _supplierService.getSupplier(id);
  }
  
  @override
  Future<String> addSupplier(Map<String, dynamic> supplier) async {
    return await _supplierService.addSupplier(supplier);
  }
  
  @override
  Future<void> updateSupplier(Map<String, dynamic> supplier) async {
    await _supplierService.updateSupplier(supplier);
  }
  
  @override
  Future<void> deleteSupplier(String id) async {
    await _supplierService.deleteSupplier(id);
  }

  // PurchaseOrder methods
  @override
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    return await _purchaseOrderService.getPurchaseOrders();
  }
  
  @override
  Future<Map<String, dynamic>?> getPurchaseOrder(String id) async {
    return await _purchaseOrderService.getPurchaseOrder(id);
  }
  
  @override
  Future<String> addPurchaseOrder(Map<String, dynamic> order) async {
    return await _purchaseOrderService.addPurchaseOrder(order);
  }
  
  @override
  Future<void> updatePurchaseOrder(Map<String, dynamic> order) async {
    await _purchaseOrderService.updatePurchaseOrder(order);
  }
  
  @override
  Future<void> deletePurchaseOrder(String id) async {
    await _purchaseOrderService.deletePurchaseOrder(id);
  }

  // PurchaseOrderItem methods
  @override
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String orderId) async {
    return await _purchaseOrderService.getPurchaseOrderItems(orderId);
  }
  
  @override
  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id) async {
    return await _purchaseOrderService.getPurchaseOrderItem(id);
  }
  
  @override
  Future<String> addPurchaseOrderItem(Map<String, dynamic> item) async {
    return await _purchaseOrderService.addPurchaseOrderItem(item);
  }
  
  @override
  Future<void> updatePurchaseOrderItem(Map<String, dynamic> item) async {
    await _purchaseOrderService.updatePurchaseOrderItem(item);
  }
  
  @override
  Future<void> deletePurchaseOrderItem(String id) async {
    await _purchaseOrderService.deletePurchaseOrderItem(id);
  }
}