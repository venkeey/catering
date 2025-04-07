import 'package:uuid/uuid.dart';

class PurchaseOrder {
  final String? id;
  final String supplierId;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String status;
  final double totalAmount;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    required this.orderDate,
    this.expectedDeliveryDate,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PurchaseOrder copyWith({
    String? id,
    String? supplierId,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? status,
    double? totalAmount,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'supplier_id': supplierId,
      'order_date': orderDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'],
      supplierId: map['supplier_id'],
      orderDate: DateTime.parse(map['order_date']),
      expectedDeliveryDate: map['expected_delivery_date'] != null 
          ? DateTime.parse(map['expected_delivery_date']) 
          : null,
      status: map['status'],
      totalAmount: map['total_amount'],
      notes: map['notes'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
} 