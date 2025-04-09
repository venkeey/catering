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
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final Map<String, double> vitamins;
  final Map<String, double> minerals;
  final List<String> allergens;

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
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbohydrates = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
    Map<String, double>? vitamins,
    Map<String, double>? minerals,
    List<String>? allergens,
  })  : id = id ?? const Uuid().v4(),
        dietaryTags = dietaryTags ?? [],
        itemType = itemType ?? 'Standard',
        isActive = isActive ?? true,
        ingredients = ingredients ?? {},
        createdAt = createdAt ?? DateTime.now(),
        vitamins = vitamins ?? {},
        minerals = minerals ?? {},
        allergens = allergens ?? [];

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
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    Map<String, double>? vitamins,
    Map<String, double>? minerals,
    List<String>? allergens,
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
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      vitamins: vitamins ?? this.vitamins,
      minerals: minerals ?? this.minerals,
      allergens: allergens ?? this.allergens,
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
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamins': vitamins.toString(), // TODO: Proper serialization
      'minerals': minerals.toString(), // TODO: Proper serialization
      'allergens': allergens.join(','),
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
      calories: double.tryParse(map['calories']?.toString() ?? '0') ?? 0.0,
      protein: double.tryParse(map['protein']?.toString() ?? '0') ?? 0.0,
      carbohydrates: double.tryParse(map['carbohydrates']?.toString() ?? '0') ?? 0.0,
      fat: double.tryParse(map['fat']?.toString() ?? '0') ?? 0.0,
      fiber: double.tryParse(map['fiber']?.toString() ?? '0') ?? 0.0,
      sugar: double.tryParse(map['sugar']?.toString() ?? '0') ?? 0.0,
      sodium: double.tryParse(map['sodium']?.toString() ?? '0') ?? 0.0,
      vitamins: {}, // TODO: Proper deserialization
      minerals: {}, // TODO: Proper deserialization
      allergens: map['allergens'] != null ? map['allergens'].toString().split(',') : [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : null,
    );
  }

  bool meetsDietaryRestriction(String restriction) {
    return dietaryTags.contains(restriction.toLowerCase());
  }
} 