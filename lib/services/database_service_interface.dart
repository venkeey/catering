import '../models/client.dart';
import '../models/dish.dart';
import '../models/event.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/menu_package.dart';
import '../models/package_item.dart';
import '../models/inventory_item.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';

/// Interface for database services
abstract class DatabaseServiceInterface {
  // Connection properties
  bool get isConnected;
  String get host;
  int get port;
  String get user;
  String get password;
  String get db;

  // Connection methods
  Future<void> initialize();
  Future<void> loadConnectionSettings();
  Future<bool> connect();
  Future<void> disconnect();
  Future<bool> testConnection();
  Future<void> saveConnectionSettings({
    required String host,
    required int port,
    required String user,
    required String password,
    required String db,
  });
  
  // Client methods
  Future<List<Client>> getClients();
  Future<Client?> getClient(String id);
  Future<String> addClient(Client client);
  Future<void> updateClient(Client client);
  Future<void> deleteClient(String id);
  
  // Event methods
  Future<List<Event>> getEvents();
  Future<Event?> getEvent(String id);
  Future<String> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(String id);
  
  // Quote methods
  Future<List<Quote>> getQuotes();
  Future<Quote?> getQuote(String id);
  Future<String> addQuote(Quote quote);
  Future<void> updateQuote(Quote quote);
  Future<void> deleteQuote(String id);
  
  // QuoteItem methods
  Future<List<QuoteItem>> getQuoteItems();
  Future<List<QuoteItem>> getQuoteItemsForQuote(String quoteId);
  Future<String> addQuoteItem(QuoteItem item);
  Future<void> updateQuoteItem(QuoteItem item);
  Future<void> deleteQuoteItem(String id);
  
  // Dish methods
  Future<List<Dish>> getDishes();
  Future<Dish?> getDish(String id);
  Future<String> addDish(Dish dish);
  Future<void> updateDish(Dish dish);
  Future<void> deleteDish(String id);
  
  // MenuPackage methods
  Future<List<MenuPackage>> getMenuPackages();
  Future<MenuPackage?> getMenuPackage(String id);
  Future<String> addMenuPackage(MenuPackage package);
  Future<void> updateMenuPackage(MenuPackage package);
  Future<void> deleteMenuPackage(String id);
  
  // PackageItem methods
  Future<List<PackageItem>> getPackageItems();
  Future<List<PackageItem>> getPackageItemsForPackage(String packageId);
  Future<String> addPackageItem(PackageItem item);
  Future<void> updatePackageItem(PackageItem item);
  Future<void> deletePackageItem(String id);
  
  // Inventory methods
  Future<List<Map<String, dynamic>>> getInventoryItems();
  Future<Map<String, dynamic>?> getInventoryItem(String id);
  Future<String> addInventoryItem(Map<String, dynamic> item);
  Future<void> updateInventoryItem(Map<String, dynamic> item);
  Future<void> deleteInventoryItem(String id);
  
  // Supplier methods
  Future<List<Map<String, dynamic>>> getSuppliers();
  Future<Map<String, dynamic>?> getSupplier(String id);
  Future<String> addSupplier(Map<String, dynamic> supplier);
  Future<void> updateSupplier(Map<String, dynamic> supplier);
  Future<void> deleteSupplier(String id);
  
  // PurchaseOrder methods
  Future<List<Map<String, dynamic>>> getPurchaseOrders();
  Future<Map<String, dynamic>?> getPurchaseOrder(String id);
  Future<String> addPurchaseOrder(Map<String, dynamic> order);
  Future<void> updatePurchaseOrder(Map<String, dynamic> order);
  Future<void> deletePurchaseOrder(String id);
  
  // PurchaseOrderItem methods
  Future<List<Map<String, dynamic>>> getPurchaseOrderItems(String orderId);
  Future<Map<String, dynamic>?> getPurchaseOrderItem(String id);
  Future<String> addPurchaseOrderItem(Map<String, dynamic> item);
  Future<void> updatePurchaseOrderItem(Map<String, dynamic> item);
  Future<void> deletePurchaseOrderItem(String id);
}