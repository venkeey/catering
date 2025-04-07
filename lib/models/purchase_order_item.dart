import 'package:uuid/uuid.dart';

class PurchaseOrderItem {
  final String? id;
  final String purchaseOrderId;
  final String inventoryItemId;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  PurchaseOrderItem({
    this.id,
    required this.purchaseOrderId,
    required this.inventoryItemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PurchaseOrderItem copyWith({
    String? id,
    String? purchaseOrderId,
    String? inventoryItemId,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'purchase_order_id': purchaseOrderId,
      'inventory_item_id': inventoryItemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      id: map['id'],
      purchaseOrderId: map['purchase_order_id'],
      inventoryItemId: map['inventory_item_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      totalPrice: map['total_price'],
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
} 