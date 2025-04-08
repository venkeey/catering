import 'package:uuid/uuid.dart';

class Dish {
  final String id;
  final String name;
  final String categoryId;
  final String category;
  final double basePrice;
  final double baseFoodCost;
  final double standardPortionSize;
  final String? description;
  final String? imageUrl;
  final List<String> dietaryTags;
  final String itemType;
  final bool isActive;
  final Map<String, double> ingredients;
  final DateTime createdAt;

  Dish({
    String? id,
    required this.name,
    required this.categoryId,
    required this.category,
    required this.basePrice,
    required this.baseFoodCost,
    required this.standardPortionSize,
    this.description,
    this.imageUrl,
    List<String>? dietaryTags,
    String? itemType,
    bool? isActive,
    Map<String, double>? ingredients,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        dietaryTags = dietaryTags ?? [],
        itemType = itemType ?? 'Standard',
        isActive = isActive ?? true,
        ingredients = ingredients ?? {},
        createdAt = createdAt ?? DateTime.now();

  Dish copyWith({
    String? name,
    String? categoryId,
    String? category,
    double? basePrice,
    double? baseFoodCost,
    double? standardPortionSize,
    String? description,
    String? imageUrl,
    List<String>? dietaryTags,
    String? itemType,
    bool? isActive,
    Map<String, double>? ingredients,
  }) {
    return Dish(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      baseFoodCost: baseFoodCost ?? this.baseFoodCost,
      standardPortionSize: standardPortionSize ?? this.standardPortionSize,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      itemType: itemType ?? this.itemType,
      isActive: isActive ?? this.isActive,
      ingredients: ingredients ?? this.ingredients,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'category': category,
      'basePrice': basePrice,
      'baseFoodCost': baseFoodCost,
      'standardPortionSize': standardPortionSize,
      'description': description,
      'imageUrl': imageUrl,
      'dietaryTags': dietaryTags.join(','),
      'itemType': itemType,
      'isActive': isActive ? 1 : 0,
      'ingredients': ingredients.toString(), // TODO: Proper serialization
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'],
      category: map['category'],
      basePrice: double.tryParse(map['basePrice'].toString()) ?? 0.0,
      baseFoodCost: double.tryParse(map['baseFoodCost'].toString()) ?? 0.0,
      standardPortionSize: double.tryParse(map['standardPortionSize'].toString()) ?? 0.0,
      description: map['description'],
      imageUrl: map['imageUrl'],
      dietaryTags: map['dietaryTags'] != null ? map['dietaryTags'].toString().split(',') : [],
      itemType: map['itemType'] ?? 'Standard',
      isActive: map['isActive'] == 1 || map['isActive'] == '1' || map['isActive'] == true,
      ingredients: {}, // TODO: Proper deserialization
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : null,
    );
  }
} 