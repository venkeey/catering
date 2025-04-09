import 'package:uuid/uuid.dart';
import 'dart:math';

import 'dish.dart';

class QuoteItem {
  final BigInt id;
  final BigInt quoteId;
  final BigInt dishId;
  final String dishName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final double? quotedPortionSizeGrams;
  final double? quotedBaseFoodCostPerServing;
  final double? percentageTakeRate;
  final int? estimatedServings;
  final double? estimatedTotalWeightGrams;
  final double? estimatedItemFoodCost;
  final Dish? dishObject;

  QuoteItem({
    BigInt? id,
    required this.quoteId,
    required this.dishId,
    required this.dishName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.quotedPortionSizeGrams,
    this.quotedBaseFoodCostPerServing,
    this.percentageTakeRate,
    this.estimatedServings,
    this.estimatedTotalWeightGrams,
    this.estimatedItemFoodCost,
    this.dishObject,
  }) : id = id ?? BigInt.from(0);

  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'quoteId': quoteId.toString(),
      'dishId': dishId.toString(),
      'dishName': dishName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
      'quotedPortionSizeGrams': quotedPortionSizeGrams,
      'quotedBaseFoodCostPerServing': quotedBaseFoodCostPerServing,
      'percentageTakeRate': percentageTakeRate,
      'estimatedServings': estimatedServings,
      'estimatedTotalWeightGrams': estimatedTotalWeightGrams,
      'estimatedItemFoodCost': estimatedItemFoodCost,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'] != null ? BigInt.parse(map['id'].toString()) : BigInt.from(0),
      quoteId: map['quoteId'] != null ? BigInt.parse(map['quoteId'].toString()) : BigInt.from(0),
      dishId: map['dishId'] != null ? BigInt.parse(map['dishId'].toString()) : BigInt.from(0),
      dishName: map['dishName'] ?? '',
      quantity: map['quantity'] is int ? (map['quantity'] as int).toDouble() : (map['quantity'] ?? 0.0),
      unitPrice: map['unitPrice'] is int ? (map['unitPrice'] as int).toDouble() : (map['unitPrice'] ?? 0.0),
      totalPrice: map['totalPrice'] is int ? (map['totalPrice'] as int).toDouble() : (map['totalPrice'] ?? 0.0),
      notes: map['notes'],
      quotedPortionSizeGrams: map['quotedPortionSizeGrams'] is int ? (map['quotedPortionSizeGrams'] as int).toDouble() : (map['quotedPortionSizeGrams'] ?? 0.0),
      quotedBaseFoodCostPerServing: map['quotedBaseFoodCostPerServing'] is int ? (map['quotedBaseFoodCostPerServing'] as int).toDouble() : (map['quotedBaseFoodCostPerServing'] ?? 0.0),
      percentageTakeRate: map['percentageTakeRate'] is int ? (map['percentageTakeRate'] as int).toDouble() : (map['percentageTakeRate'] ?? 0.0),
      estimatedServings: map['estimatedServings'],
      estimatedTotalWeightGrams: map['estimatedTotalWeightGrams'] is int ? (map['estimatedTotalWeightGrams'] as int).toDouble() : (map['estimatedTotalWeightGrams'] ?? 0.0),
      estimatedItemFoodCost: map['estimatedItemFoodCost'] is int ? (map['estimatedItemFoodCost'] as int).toDouble() : (map['estimatedItemFoodCost'] ?? 0.0),
    );
  }
} 