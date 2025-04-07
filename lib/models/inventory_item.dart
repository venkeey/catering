import 'package:uuid/uuid.dart';

class InventoryItem {
  final String? id;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double minimumQuantity;
  final double reorderPoint;
  final double costPerUnit;
  final DateTime? expiryDate;
  final String? supplierId;
  final bool isActive;
  final DateTime createdAt;

  InventoryItem({
    this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.minimumQuantity,
    required this.reorderPoint,
    required this.costPerUnit,
    this.expiryDate,
    this.supplierId,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? minimumQuantity,
    double? reorderPoint,
    double? costPerUnit,
    DateTime? expiryDate,
    String? supplierId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      expiryDate: expiryDate ?? this.expiryDate,
      supplierId: supplierId ?? this.supplierId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'minimum_quantity': minimumQuantity,
      'reorder_point': reorderPoint,
      'cost_per_unit': costPerUnit,
      'expiry_date': expiryDate?.toIso8601String(),
      'supplier_id': supplierId,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      quantity: map['quantity'],
      unit: map['unit'],
      minimumQuantity: map['minimum_quantity'],
      reorderPoint: map['reorder_point'],
      costPerUnit: map['cost_per_unit'],
      expiryDate: map['expiry_date'] != null ? DateTime.parse(map['expiry_date']) : null,
      supplierId: map['supplier_id'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
} 