import 'package:uuid/uuid.dart';

class QuoteItem {
  final String? id;
  final String quoteId;
  final String dishId;
  final double? quotedPortionSizeGrams;
  final double? quotedBaseFoodCostPerServing;
  final double? percentageTakeRate;
  final int? estimatedServings;
  final double? estimatedTotalWeightGrams;
  final double? estimatedItemFoodCost;

  QuoteItem({
    this.id,
    required this.quoteId,
    required this.dishId,
    this.quotedPortionSizeGrams,
    this.quotedBaseFoodCostPerServing,
    this.percentageTakeRate,
    this.estimatedServings,
    this.estimatedTotalWeightGrams,
    this.estimatedItemFoodCost,
  });

  QuoteItem copyWith({
    String? id,
    String? quoteId,
    String? dishId,
    double? quotedPortionSizeGrams,
    double? quotedBaseFoodCostPerServing,
    double? percentageTakeRate,
    int? estimatedServings,
    double? estimatedTotalWeightGrams,
    double? estimatedItemFoodCost,
  }) {
    return QuoteItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      dishId: dishId ?? this.dishId,
      quotedPortionSizeGrams: quotedPortionSizeGrams ?? this.quotedPortionSizeGrams,
      quotedBaseFoodCostPerServing: quotedBaseFoodCostPerServing ?? this.quotedBaseFoodCostPerServing,
      percentageTakeRate: percentageTakeRate ?? this.percentageTakeRate,
      estimatedServings: estimatedServings ?? this.estimatedServings,
      estimatedTotalWeightGrams: estimatedTotalWeightGrams ?? this.estimatedTotalWeightGrams,
      estimatedItemFoodCost: estimatedItemFoodCost ?? this.estimatedItemFoodCost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? const Uuid().v4(),
      'quoteId': quoteId,
      'dishId': dishId,
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
      id: map['id'],
      quoteId: map['quoteId'],
      dishId: map['dishId'],
      quotedPortionSizeGrams: map['quotedPortionSizeGrams'],
      quotedBaseFoodCostPerServing: map['quotedBaseFoodCostPerServing'],
      percentageTakeRate: map['percentageTakeRate'],
      estimatedServings: map['estimatedServings'],
      estimatedTotalWeightGrams: map['estimatedTotalWeightGrams'],
      estimatedItemFoodCost: map['estimatedItemFoodCost'],
    );
  }
} 