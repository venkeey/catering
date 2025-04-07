import 'package:uuid/uuid.dart';
import '../models/dish.dart';

class PackageItem {
  final String? id;
  final String packageId;
  final String dishId;
  final bool isOptional;
  final Dish? dish; // Optional loaded dish object

  PackageItem({
    this.id,
    required this.packageId,
    required this.dishId,
    this.isOptional = false,
    this.dish,
  });

  PackageItem copyWith({
    String? id,
    String? packageId,
    String? dishId,
    bool? isOptional,
    Dish? dish,
  }) {
    return PackageItem(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      dishId: dishId ?? this.dishId,
      isOptional: isOptional ?? this.isOptional,
      dish: dish ?? this.dish,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'package_id': packageId,
      'dish_id': dishId,
      'is_optional': isOptional ? 1 : 0,
    };
  }

  factory PackageItem.fromMap(Map<String, dynamic> map, {Dish? dish}) {
    return PackageItem(
      id: map['id'],
      packageId: map['package_id'],
      dishId: map['dish_id'],
      isOptional: map['is_optional'] == 1,
      dish: dish,
    );
  }
} 