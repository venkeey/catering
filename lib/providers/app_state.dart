import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../models/quote.dart' hide QuoteItem;
import '../models/quote_item.dart';
import '../models/dish.dart';
import '../models/menu_package.dart';
import '../models/package_item.dart';
import '../models/inventory_item.dart';
import '../models/supplier.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../services/database_service_interface.dart';

class AppState extends ChangeNotifier {
  final DatabaseServiceInterface _db;
  
  AppState(this._db);
  
  // Private state
  List<Client> _clients = [];
  List<Event> _events = [];
  List<Quote> _quotes = [];
  List<QuoteItem> _quoteItems = [];
  List<Dish> _dishes = [];
  List<MenuPackage> _menuPackages = [];
  List<PackageItem> _packageItems = [];
  List<InventoryItem> _inventoryItems = [];
  List<Supplier> _suppliers = [];
  List<PurchaseOrder> _purchaseOrders = [];
  List<PurchaseOrderItem> _purchaseOrderItems = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Client> get clients => List.unmodifiable(_clients);
  List<Event> get events => List.unmodifiable(_events);
  List<Quote> get quotes => List.unmodifiable(_quotes);
  List<QuoteItem> get quoteItems => List.unmodifiable(_quoteItems);
  List<Dish> get dishes => List.unmodifiable(_dishes);
  List<MenuPackage> get menuPackages => List.unmodifiable(_menuPackages);
  List<PackageItem> get packageItems => List.unmodifiable(_packageItems);
  List<InventoryItem> get inventoryItems => List.unmodifiable(_inventoryItems);
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  List<PurchaseOrderItem> get purchaseOrderItems => List.unmodifiable(_purchaseOrderItems);
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize data from database
  Future<void> initialize() async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Load all data from database
      final clientsData = await _db.getClients();
      _clients = clientsData;
      
      final eventsData = await _db.getEvents();
      _events = eventsData;
      
      final quotesData = await _db.getQuotes();
      _quotes = quotesData;
      
      final quoteItemsData = await _db.getQuoteItems();
      _quoteItems = quoteItemsData;
      
      final dishesData = await _db.getDishes();
      _dishes = dishesData;
      
      final menuPackagesData = await _db.getMenuPackages();
      _menuPackages = menuPackagesData;
      
      final packageItemsData = await _db.getPackageItems();
      _packageItems = packageItemsData;
      
      final inventoryItemsData = await _db.getInventoryItems();
      _inventoryItems = inventoryItemsData.map((data) => InventoryItem.fromMap(data)).toList();
      
      final suppliersData = await _db.getSuppliers();
      _suppliers = suppliersData.map((data) => Supplier.fromMap(data)).toList();
      
      final purchaseOrdersData = await _db.getPurchaseOrders();
      _purchaseOrders = purchaseOrdersData.map((data) => PurchaseOrder.fromMap(data)).toList();
      
      final purchaseOrderItemsData = await _db.getPurchaseOrderItems('');
      _purchaseOrderItems = purchaseOrderItemsData.map((data) => PurchaseOrderItem.fromMap(data)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load data: $e';
      notifyListeners();
    }
  }

  // Client methods
  Future<void> addClient(Client client) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addClient(client);
      final updatedClient = Client.fromMap({
        ...client.toMap(),
        'id': id,
      });
      _clients.add(updatedClient);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add client: $e';
      notifyListeners();
    }
  }

  Future<void> updateClient(Client client) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateClient(client);
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update client: $e';
      notifyListeners();
    }
  }

  Future<void> deleteClient(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteClient(id);
      _clients.removeWhere((c) => c.id == id);
      _events.removeWhere((e) => e.clientId == id);
      _quotes.removeWhere((q) => q.clientId == id);
      _quoteItems.removeWhere((qi) => _quotes.any((q) => q.id == qi.quoteId));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete client: $e';
      notifyListeners();
    }
  }

  // Event methods
  Future<void> addEvent(Event event) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addEvent(event);
      final updatedEvent = Event.fromMap({
        ...event.toMap(),
        'id': id,
      });
      _events.add(updatedEvent);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add event: $e';
      notifyListeners();
    }
  }

  Future<void> updateEvent(Event event) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update event: $e';
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteEvent(id);
      _events.removeWhere((e) => e.id == id);
      _quotes.removeWhere((q) => q.eventId == id);
      _quoteItems.removeWhere((qi) => _quotes.any((q) => q.id == qi.quoteId));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete event: $e';
      notifyListeners();
    }
  }

  // Quote methods
  Future<void> addQuote(Quote quote) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addQuote(quote);
      final updatedQuote = Quote.fromMap({
        ...quote.toMap(),
        'id': id,
      });
      _quotes.add(updatedQuote);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add quote: $e';
      notifyListeners();
    }
  }

  Future<void> updateQuote(Quote quote) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateQuote(quote);
      final index = _quotes.indexWhere((q) => q.id == quote.id);
      if (index != -1) {
        _quotes[index] = quote;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update quote: $e';
      notifyListeners();
    }
  }

  Future<void> deleteQuote(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteQuote(id);
      _quotes.removeWhere((q) => q.id == id);
      _quoteItems.removeWhere((qi) => qi.quoteId == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete quote: $e';
      notifyListeners();
    }
  }

  // QuoteItem methods
  Future<void> addQuoteItem(QuoteItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addQuoteItem(item);
      final updatedItem = QuoteItem.fromMap({
        ...item.toMap(),
        'id': id,
      });
      _quoteItems.add(updatedItem);
      await recalculateQuoteTotals(item.quoteId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add quote item: $e';
      notifyListeners();
    }
  }

  Future<void> updateQuoteItem(QuoteItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateQuoteItem(item);
      final index = _quoteItems.indexWhere((qi) => qi.id == item.id);
      if (index != -1) {
        _quoteItems[index] = item;
        await recalculateQuoteTotals(item.quoteId);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update quote item: $e';
      notifyListeners();
    }
  }

  Future<void> deleteQuoteItem(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final item = _quoteItems.firstWhere((qi) => qi.id == id);
      await _db.deleteQuoteItem(id);
      _quoteItems.removeWhere((qi) => qi.id == id);
      await recalculateQuoteTotals(item.quoteId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete quote item: $e';
      notifyListeners();
    }
  }

  // Dish methods
  Future<void> addDish(Dish dish) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addDish(dish);
      final updatedDish = Dish(
        id: id.toString(),
        name: dish.name,
        categoryId: dish.categoryId,
        category: dish.category,
        basePrice: dish.basePrice,
        baseFoodCost: dish.baseFoodCost,
        standardPortionSize: dish.standardPortionSize,
        description: dish.description,
        imageUrl: dish.imageUrl,
        dietaryTags: dish.dietaryTags,
        itemType: dish.itemType,
        isActive: dish.isActive,
        ingredients: dish.ingredients,
        createdAt: dish.createdAt,
      );
      _dishes.add(updatedDish);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add dish: $e';
      notifyListeners();
    }
  }

  Future<void> updateDish(Dish dish) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateDish(dish);
      final index = _dishes.indexWhere((d) => d.id == dish.id);
      if (index != -1) {
        _dishes[index] = dish;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update dish: $e';
      notifyListeners();
    }
  }

  Future<void> deleteDish(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteDish(id);
      _dishes.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete dish: $e';
      notifyListeners();
    }
  }

  // Menu Package Methods
  Future<void> addMenuPackage(MenuPackage package) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addMenuPackage(package);
      final updatedPackage = package.copyWith(id: id.toString());
      _menuPackages.add(updatedPackage);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add menu package: $e';
      notifyListeners();
    }
  }

  Future<void> updateMenuPackage(MenuPackage package) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updateMenuPackage(package);
      final index = _menuPackages.indexWhere((p) => p.id == package.id);
      if (index != -1) {
        _menuPackages[index] = package;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update menu package: $e';
      notifyListeners();
    }
  }

  Future<void> deleteMenuPackage(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteMenuPackage(id);
      _menuPackages.removeWhere((p) => p.id == id);
      _packageItems.removeWhere((pi) => pi.packageId == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete menu package: $e';
      notifyListeners();
    }
  }

  // Package Item Methods
  Future<void> addPackageItem(PackageItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addPackageItem(item);
      final updatedItem = item.copyWith(id: id);
      _packageItems.add(updatedItem);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add package item: $e';
      notifyListeners();
    }
  }

  Future<void> updatePackageItem(PackageItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.updatePackageItem(item);
      final index = _packageItems.indexWhere((pi) => pi.id == item.id);
      if (index != -1) {
        _packageItems[index] = item;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update package item: $e';
      notifyListeners();
    }
  }

  Future<void> deletePackageItem(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deletePackageItem(id);
      _packageItems.removeWhere((pi) => pi.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete package item: $e';
      notifyListeners();
    }
  }

  // Helper methods
  List<Event> getEventsForClient(String clientId) {
    return _events.where((e) => e.clientId == clientId).toList();
  }

  List<Quote> getQuotesForClient(String clientId) {
    return _quotes.where((q) => q.clientId == clientId).toList();
  }

  List<Quote> getQuotesForEvent(String eventId) {
    return _quotes.where((q) => q.eventId == eventId).toList();
  }

  List<QuoteItem> getQuoteItemsForQuote(String quoteId) {
    return _quoteItems.where((qi) => qi.quoteId == quoteId).toList();
  }

  Dish? getDishForQuoteItem(QuoteItem item) {
    return _dishes.firstWhere((d) => d.id == item.dishId);
  }

  Future<void> recalculateQuoteTotals(String quoteId) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final quote = _quotes.firstWhere((q) => q.id == quoteId);
      final items = getQuoteItemsForQuote(quoteId);
      
      double totalFoodCost = 0;
      for (final item in items) {
        final dish = getDishForQuoteItem(item);
        if (dish != null) {
          totalFoodCost += item.estimatedItemFoodCost ?? 0;
        }
      }

      final overhead = totalFoodCost * (quote.overheadPercentage / 100);
      final grandTotal = totalFoodCost + overhead;

      final updatedQuote = Quote.fromMap({
        ...quote.toMap(),
        'totalFoodCost': totalFoodCost,
        'overheadCost': overhead,
        'grandTotal': grandTotal,
      });

      await updateQuote(updatedQuote);
    } catch (e) {
      _error = 'Failed to recalculate quote totals: $e';
      notifyListeners();
    }
  }

  List<PackageItem> getPackageItemsForPackage(String packageId) {
    return _packageItems.where((pi) => pi.packageId == packageId).toList();
  }

  List<Dish> getDishesForPackage(String packageId) {
    final itemIds = getPackageItemsForPackage(packageId)
        .map((pi) => pi.dishId)
        .toList();
    return _dishes.where((d) => itemIds.contains(d.id)).toList();
  }

  // Supplier methods
  Future<void> addSupplier(Supplier supplier) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addSupplier(supplier.toMap());
      final updatedSupplier = supplier.copyWith(id: id.toString());
      _suppliers.add(updatedSupplier);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add supplier: $e';
      notifyListeners();
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      if (supplier.id == null) {
        _error = 'Cannot update supplier without an ID';
        notifyListeners();
        return;
      }
      await _db.updateSupplier(supplier.toMap());
      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = supplier;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update supplier: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSupplier(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteSupplier(id);
      _suppliers.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete supplier: $e';
      notifyListeners();
    }
  }

  // Inventory methods
  Future<void> addInventoryItem(InventoryItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addInventoryItem(item.toMap());
      final updatedItem = item.copyWith(id: id.toString());
      _inventoryItems.add(updatedItem);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add inventory item: $e';
      notifyListeners();
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      if (item.id == null) {
        _error = 'Cannot update inventory item without an ID';
        notifyListeners();
        return;
      }
      await _db.updateInventoryItem(item.toMap());
      final index = _inventoryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = item;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update inventory item: $e';
      notifyListeners();
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deleteInventoryItem(id);
      _inventoryItems.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete inventory item: $e';
      notifyListeners();
    }
  }

  // Purchase Order methods
  Future<void> addPurchaseOrder(PurchaseOrder order) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addPurchaseOrder(order.toMap());
      final updatedOrder = order.copyWith(id: id.toString());
      _purchaseOrders.add(updatedOrder);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add purchase order: $e';
      notifyListeners();
    }
  }

  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      if (order.id == null) {
        _error = 'Cannot update purchase order without an ID';
        notifyListeners();
        return;
      }
      await _db.updatePurchaseOrder(order.toMap());
      final index = _purchaseOrders.indexWhere((o) => o.id == order.id);
      if (index != -1) {
        _purchaseOrders[index] = order;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update purchase order: $e';
      notifyListeners();
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      await _db.deletePurchaseOrder(id);
      _purchaseOrders.removeWhere((o) => o.id == id);
      _purchaseOrderItems.removeWhere((i) => i.purchaseOrderId == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete purchase order: $e';
      notifyListeners();
    }
  }

  Future<void> addPurchaseOrderItem(PurchaseOrderItem item) async {
    if (!_db.isConnected) {
      _error = 'Database not connected';
      notifyListeners();
      return;
    }

    try {
      final id = await _db.addPurchaseOrderItem(item.toMap());
      final updatedItem = item.copyWith(id: id.toString());
      _purchaseOrderItems.add(updatedItem);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add purchase order item: $e';
      notifyListeners();
    }
  }
} 