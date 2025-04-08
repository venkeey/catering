import 'package:uuid/uuid.dart';

import 'package_item.dart';

class MenuPackage {
  final String? id;
  final String name;
  final String description;
  final double basePrice;
  final String eventType;
  final bool isActive;
  final DateTime createdAt;
  final List<PackageItem> packageItems;
  
  // Getter for backward compatibility
  List<PackageItem> get items => packageItems;

  MenuPackage({
    this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.eventType,
    this.isActive = true,
    DateTime? createdAt,
    List<PackageItem>? packageItems,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    packageItems = packageItems ?? [];

  MenuPackage copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    String? eventType,
    bool? isActive,
    DateTime? createdAt,
    List<PackageItem>? packageItems,
  }) {
    return MenuPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      eventType: eventType ?? this.eventType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      packageItems: packageItems ?? this.packageItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'name': name,
      'description': description,
      'base_price': basePrice,
      'event_type': eventType,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MenuPackage.fromMap(Map<String, dynamic> map, {List<PackageItem>? packageItems}) {
    return MenuPackage(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      basePrice: map['base_price'] is double ? map['base_price'] : double.parse(map['base_price'].toString()),
      eventType: map['event_type'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      packageItems: packageItems,
    );
  }
} 