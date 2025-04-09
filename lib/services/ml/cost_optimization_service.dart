import 'dart:math';
import 'package:flutter/foundation.dart';
import '../database/quote_item_database_service.dart';
import '../database/dish_database_service.dart';
import '../../models/quote_item.dart';
import '../../models/dish.dart';
import '../../models/cost_optimization.dart';

class CostOptimizationService {
  final QuoteItemDatabaseService _quoteItemService;
  final DishDatabaseService _dishService;

  CostOptimizationService(this._quoteItemService, this._dishService);

  /// Predicts optimal portion size and price based on historical data and various factors
  Future<CostOptimizationPrediction> predictOptimalCosts({
    required String dishId,
    required double baseCost,
    required int totalGuests,
    required int maleGuests,
    required int femaleGuests,
    required int elderlyGuests,
    required int youthGuests,
    required int childGuests,
    required String eventType,
    required DateTime eventDate,
  }) async {
    try {
      // Get historical data for this dish
      final historicalItems = await _getHistoricalQuoteItems(dishId);
      final dish = await _dishService.getDish(dishId);

      if (historicalItems.isEmpty) {
        return _createDefaultPrediction(
          dishId: dishId,
          baseCost: baseCost,
          standardPortionSize: dish?.standardPortionSize ?? 0.0,
        );
      }

      // Calculate various factors
      final weights = _calculateDemographicWeights(
        totalGuests: totalGuests,
        maleGuests: maleGuests,
        femaleGuests: femaleGuests,
        elderlyGuests: elderlyGuests,
        youthGuests: youthGuests,
        childGuests: childGuests,
      );

      final seasonalFactor = _calculateSeasonalFactor(eventDate);
      final eventTypeFactor = _calculateEventTypeFactor(eventType);
      final guestCountFactor = _calculateGuestCountFactor(totalGuests);

      // Calculate predictions
      final portionSize = await _predictPortionSize(
        historicalItems: historicalItems,
        weights: weights,
        standardPortionSize: dish?.standardPortionSize ?? 0.0,
      );

      final price = await _predictPrice(
        historicalItems: historicalItems,
        baseCost: baseCost,
        seasonalFactor: seasonalFactor,
        eventTypeFactor: eventTypeFactor,
        guestCountFactor: guestCountFactor,
      );

      // Calculate confidence score
      final confidenceScore = _calculateConfidenceScore(
        historicalItems: historicalItems,
        totalGuests: totalGuests,
        eventType: eventType,
      );

      // Generate recommendations
      final recommendations = _generateRecommendations(
        portionSize: portionSize,
        price: price,
        baseCost: baseCost,
        totalGuests: totalGuests,
        eventType: eventType,
        confidenceScore: confidenceScore,
      );

      // Create factors map
      final factors = {
        'seasonal': seasonalFactor,
        'eventType': eventTypeFactor,
        'guestCount': guestCountFactor,
        'maleRatio': weights['male'] ?? 0.0,
        'femaleRatio': weights['female'] ?? 0.0,
        'elderlyRatio': weights['elderly'] ?? 0.0,
        'youthRatio': weights['youth'] ?? 0.0,
        'childRatio': weights['child'] ?? 0.0,
      };

      return CostOptimizationPrediction(
        dishId: dishId,
        predictedPortionSize: portionSize,
        predictedPrice: price,
        confidenceScore: confidenceScore,
        factors: factors,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Error predicting optimal costs: $e');
      return _createDefaultPrediction(
        dishId: dishId,
        baseCost: baseCost,
        standardPortionSize: 0.0,
      );
    }
  }

  /// Creates a default prediction when historical data is not available
  CostOptimizationPrediction _createDefaultPrediction({
    required String dishId,
    required double baseCost,
    required double standardPortionSize,
  }) {
    return CostOptimizationPrediction(
      dishId: dishId,
      predictedPortionSize: standardPortionSize,
      predictedPrice: baseCost * 2.5, // Default 150% markup
      confidenceScore: 0.0,
      factors: {
        'seasonal': 1.0,
        'eventType': 1.0,
        'guestCount': 1.0,
        'maleRatio': 0.0,
        'femaleRatio': 0.0,
        'elderlyRatio': 0.0,
        'youthRatio': 0.0,
        'childRatio': 0.0,
      },
      recommendations: [
        'Insufficient historical data for accurate predictions',
        'Using standard portion size and markup',
        'Consider gathering more data for better predictions',
      ],
    );
  }

  /// Predicts optimal portion size based on historical data
  Future<double> _predictPortionSize({
    required List<QuoteItem> historicalItems,
    required Map<String, double> weights,
    required double standardPortionSize,
  }) async {
    double weightedPortionSize = 0.0;
    double totalWeight = 0.0;

    for (final item in historicalItems) {
      if (item.estimatedTotalWeightGrams != null && item.estimatedServings != null) {
        final historicalPortionSize = item.estimatedTotalWeightGrams! / item.estimatedServings!;
        final similarity = _calculateDemographicSimilarity(item, weights);
        weightedPortionSize += historicalPortionSize * similarity;
        totalWeight += similarity;
      }
    }

    if (totalWeight > 0) {
      return weightedPortionSize / totalWeight;
    }

    return standardPortionSize;
  }

  /// Predicts optimal price based on historical data
  Future<double> _predictPrice({
    required List<QuoteItem> historicalItems,
    required double baseCost,
    required double seasonalFactor,
    required double eventTypeFactor,
    required double guestCountFactor,
  }) async {
    double weightedMarkup = 0.0;
    double totalWeight = 0.0;

    for (final item in historicalItems) {
      if (item.unitPrice > 0 && item.quotedBaseFoodCostPerServing != null) {
        final historicalMarkup = item.unitPrice / item.quotedBaseFoodCostPerServing!;
        final similarity = _calculateMarketSimilarity(
          item,
          seasonalFactor,
          eventTypeFactor,
          guestCountFactor,
        );
        weightedMarkup += historicalMarkup * similarity;
        totalWeight += similarity;
      }
    }

    if (totalWeight > 0) {
      final predictedMarkup = weightedMarkup / totalWeight;
      return baseCost * predictedMarkup;
    }

    return baseCost * 2.5; // Default markup
  }

  /// Calculates confidence score for predictions
  double _calculateConfidenceScore({
    required List<QuoteItem> historicalItems,
    required int totalGuests,
    required String eventType,
  }) {
    // Base confidence on number of historical items
    double baseConfidence = min(historicalItems.length / 10, 1.0);

    // Adjust for guest count similarity
    final guestCountSimilarity = historicalItems
        .where((item) => (item.estimatedServings ?? 0) >= totalGuests * 0.8 &&
            (item.estimatedServings ?? 0) <= totalGuests * 1.2)
        .length /
        historicalItems.length;

    // Adjust for event type similarity
    final eventTypeSimilarity = historicalItems
        .where((item) => item.dishObject?.category.toLowerCase() == eventType.toLowerCase())
        .length /
        historicalItems.length;

    return (baseConfidence + guestCountSimilarity + eventTypeSimilarity) / 3;
  }

  /// Generates recommendations based on predictions
  List<String> _generateRecommendations({
    required double portionSize,
    required double price,
    required double baseCost,
    required int totalGuests,
    required String eventType,
    required double confidenceScore,
  }) {
    final recommendations = <String>[];

    // Portion size recommendations
    if (portionSize > 300) {
      recommendations.add('Consider reducing portion size to minimize waste');
    } else if (portionSize < 150) {
      recommendations.add('Consider increasing portion size to ensure guest satisfaction');
    }

    // Price recommendations
    final markup = price / baseCost;
    if (markup > 3.0) {
      recommendations.add('Current markup is high, consider competitive pricing');
    } else if (markup < 2.0) {
      recommendations.add('Current markup is low, review pricing strategy');
    }

    // Guest count recommendations
    if (totalGuests > 200) {
      recommendations.add('Large event - consider bulk discounts for ingredients');
    } else if (totalGuests < 50) {
      recommendations.add('Small event - focus on quality over quantity');
    }

    // Event type recommendations
    switch (eventType.toLowerCase()) {
      case 'wedding':
        recommendations.add('Wedding event - consider premium presentation');
        break;
      case 'corporate':
        recommendations.add('Corporate event - focus on professional service');
        break;
      case 'birthday':
        recommendations.add('Birthday event - consider festive presentation');
        break;
    }

    // Confidence score recommendations
    if (confidenceScore < 0.5) {
      recommendations.add('Low confidence in predictions - consider manual review');
    }

    return recommendations;
  }

  /// Gets historical quote items for a specific dish
  Future<List<QuoteItem>> _getHistoricalQuoteItems(String dishId) async {
    try {
      final allItems = await _quoteItemService.getQuoteItems();
      return allItems.where((item) => item.dishId.toString() == dishId).toList();
    } catch (e) {
      debugPrint('Error getting historical quote items: $e');
      return [];
    }
  }

  /// Calculates demographic weights based on guest counts
  Map<String, double> _calculateDemographicWeights({
    required int totalGuests,
    required int maleGuests,
    required int femaleGuests,
    required int elderlyGuests,
    required int youthGuests,
    required int childGuests,
  }) {
    return {
      'male': maleGuests / totalGuests,
      'female': femaleGuests / totalGuests,
      'elderly': elderlyGuests / totalGuests,
      'youth': youthGuests / totalGuests,
      'child': childGuests / totalGuests,
    };
  }

  /// Calculates similarity between historical item and current demographics
  double _calculateDemographicSimilarity(QuoteItem item, Map<String, double> weights) {
    // This is a simplified similarity calculation
    // In a real implementation, you would use more sophisticated ML algorithms
    return 1.0;
  }

  /// Calculates seasonal factor based on event date
  double _calculateSeasonalFactor(DateTime eventDate) {
    // Simple seasonal factor based on month
    final month = eventDate.month;
    if (month >= 6 && month <= 8) {
      return 1.2; // Summer premium
    } else if (month >= 11 || month <= 1) {
      return 1.1; // Holiday season premium
    }
    return 1.0;
  }

  /// Calculates event type factor
  double _calculateEventTypeFactor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'wedding':
        return 1.3;
      case 'corporate':
        return 1.2;
      case 'birthday':
        return 1.1;
      default:
        return 1.0;
    }
  }

  /// Calculates guest count factor
  double _calculateGuestCountFactor(int totalGuests) {
    if (totalGuests > 200) {
      return 0.9; // Volume discount
    } else if (totalGuests < 50) {
      return 1.1; // Small event premium
    }
    return 1.0;
  }

  /// Calculates market similarity between historical item and current factors
  double _calculateMarketSimilarity(
    QuoteItem item,
    double seasonalFactor,
    double eventTypeFactor,
    double guestCountFactor,
  ) {
    // This is a simplified similarity calculation
    // In a real implementation, you would use more sophisticated ML algorithms
    return 1.0;
  }
} 