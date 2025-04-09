import 'dart:math';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/dish.dart';
import 'database_service.dart';

/// Advanced service for managing dishes in quotes with sophisticated functionality
class QuoteDishService {
  final DatabaseService _databaseService;

  QuoteDishService(this._databaseService);

  /// Calculate optimal portion sizes based on guest demographics and event duration
  Map<String, double> calculateOptimalPortions(Quote quote) {
    // Base portion sizes in grams
    final Map<String, double> basePortions = {
      'appetizer': 100.0,
      'main': 250.0,
      'side': 150.0,
      'dessert': 120.0,
      'beverage': 250.0,
    };

    // Demographic adjustment factors
    final double maleFactor = 1.2; // Males typically eat 20% more
    final double femaleFactor = 0.9; // Females typically eat 10% less
    final double elderlyFactor = 0.8; // Elderly typically eat 20% less
    final double youthFactor = 1.1; // Youth typically eat 10% more
    final double childFactor = 0.6; // Children typically eat 40% less

    // Calculate weighted portion sizes
    final Map<String, double> optimalPortions = {};
    
    for (final entry in basePortions.entries) {
      final String category = entry.key;
      final double basePortion = entry.value;
      
      // Calculate weighted average based on demographics
      double weightedPortion = 0.0;
      int totalGuests = 0;
      
      if (quote.guestsMale > 0) {
        weightedPortion += basePortion * maleFactor * quote.guestsMale;
        totalGuests += quote.guestsMale;
      }
      
      if (quote.guestsFemale > 0) {
        weightedPortion += basePortion * femaleFactor * quote.guestsFemale;
        totalGuests += quote.guestsFemale;
      }
      
      if (quote.guestsElderly > 0) {
        weightedPortion += basePortion * elderlyFactor * quote.guestsElderly;
        totalGuests += quote.guestsElderly;
      }
      
      if (quote.guestsYouth > 0) {
        weightedPortion += basePortion * youthFactor * quote.guestsYouth;
        totalGuests += quote.guestsYouth;
      }
      
      if (quote.guestsChild > 0) {
        weightedPortion += basePortion * childFactor * quote.guestsChild;
        totalGuests += quote.guestsChild;
      }
      
      // Calculate average portion size
      optimalPortions[category] = totalGuests > 0 ? weightedPortion / totalGuests : basePortion;
    }
    
    return optimalPortions;
  }

  /// Calculate nutritional information for the entire quote menu
  Map<String, double> calculateMenuNutrition(Quote quote) {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbohydrates = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;
    double totalSodium = 0.0;
    
    for (final item in quote.items) {
      if (item.dishObject != null) {
        final Dish dish = item.dishObject!;
        final double servings = item.estimatedServings?.toDouble() ?? item.quantity;
        
        totalCalories += dish.calories * servings;
        totalProtein += dish.protein * servings;
        totalCarbohydrates += dish.carbohydrates * servings;
        totalFat += dish.fat * servings;
        totalFiber += dish.fiber * servings;
        totalSugar += dish.sugar * servings;
        totalSodium += dish.sodium * servings;
      }
    }
    
    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbohydrates': totalCarbohydrates,
      'fat': totalFat,
      'fiber': totalFiber,
      'sugar': totalSugar,
      'sodium': totalSodium,
    };
  }

  /// Generate menu recommendations based on event type, guest count, and dietary restrictions
  Future<List<Dish>> generateMenuRecommendations({
    required String eventType,
    required int guestCount,
    required int durationHours,
    required List<String> dietaryRestrictions,
    required double budget,
  }) async {
    // Get all available dishes
    final List<Dish> allDishes = await _databaseService.getDishes();
    
    // Filter dishes based on dietary restrictions
    List<Dish> filteredDishes = allDishes.where((dish) {
      for (final restriction in dietaryRestrictions) {
        if (!dish.meetsDietaryRestriction(restriction)) {
          return false;
        }
      }
      return true;
    }).toList();
    
    // Calculate dishes needed based on event type and duration
    int appetizersNeeded = 0;
    int mainsNeeded = 0;
    int sidesNeeded = 0;
    int dessertsNeeded = 0;
    int beveragesNeeded = 0;
    
    switch (eventType.toLowerCase()) {
      case 'wedding':
        appetizersNeeded = 3;
        mainsNeeded = 2;
        sidesNeeded = 3;
        dessertsNeeded = 2;
        beveragesNeeded = 3;
        break;
      case 'corporate':
        appetizersNeeded = 2;
        mainsNeeded = 1;
        sidesNeeded = 2;
        dessertsNeeded = 1;
        beveragesNeeded = 2;
        break;
      case 'birthday':
        appetizersNeeded = 2;
        mainsNeeded = 1;
        sidesNeeded = 2;
        dessertsNeeded = 1;
        beveragesNeeded = 2;
        break;
      default:
        appetizersNeeded = 2;
        mainsNeeded = 1;
        sidesNeeded = 2;
        dessertsNeeded = 1;
        beveragesNeeded = 2;
    }
    
    // Adjust for event duration
    if (durationHours > 4) {
      appetizersNeeded = (appetizersNeeded * 1.5).ceil();
      mainsNeeded = (mainsNeeded * 1.5).ceil();
      sidesNeeded = (sidesNeeded * 1.5).ceil();
      dessertsNeeded = (dessertsNeeded * 1.5).ceil();
      beveragesNeeded = (beveragesNeeded * 1.5).ceil();
    }
    
    // Calculate budget per dish
    final double budgetPerDish = budget / (appetizersNeeded + mainsNeeded + sidesNeeded + dessertsNeeded + beveragesNeeded);
    
    // Select dishes within budget
    List<Dish> recommendedDishes = [];
    
    // Helper function to select dishes by category
    void selectDishesByCategory(String category, int count) {
      final categoryDishes = filteredDishes.where((dish) => 
        dish.category.toLowerCase() == category.toLowerCase() && 
        dish.basePrice <= budgetPerDish
      ).toList();
      
      if (categoryDishes.isEmpty) return;
      
      // Sort by rating (if available) or randomly select
      categoryDishes.shuffle();
      
      for (int i = 0; i < min(count, categoryDishes.length); i++) {
        recommendedDishes.add(categoryDishes[i]);
      }
    }
    
    // Select dishes for each category
    selectDishesByCategory('appetizer', appetizersNeeded);
    selectDishesByCategory('main', mainsNeeded);
    selectDishesByCategory('side', sidesNeeded);
    selectDishesByCategory('dessert', dessertsNeeded);
    selectDishesByCategory('beverage', beveragesNeeded);
    
    return recommendedDishes;
  }

  /// Calculate food cost and profit margin for a quote
  Map<String, double> calculateQuoteFinancials(Quote quote) {
    double totalFoodCost = 0.0;
    double totalRevenue = 0.0;
    
    for (final item in quote.items) {
      totalFoodCost += item.estimatedItemFoodCost ?? 0.0;
      totalRevenue += item.totalPrice;
    }
    
    final double overheadCost = totalFoodCost * (quote.overheadPercentage / 100);
    final double totalCost = totalFoodCost + overheadCost;
    final double profit = totalRevenue - totalCost;
    final double profitMargin = totalRevenue > 0 ? (profit / totalRevenue) * 100 : 0.0;
    
    return {
      'totalFoodCost': totalFoodCost,
      'overheadCost': overheadCost,
      'totalCost': totalCost,
      'totalRevenue': totalRevenue,
      'profit': profit,
      'profitMargin': profitMargin,
    };
  }

  /// Optimize quote items to meet budget constraints
  Future<List<QuoteItem>> optimizeQuoteItems(Quote quote, double targetBudget) async {
    final List<QuoteItem> optimizedItems = List.from(quote.items);
    
    // Calculate current total
    double currentTotal = 0.0;
    for (final item in optimizedItems) {
      currentTotal += item.totalPrice;
    }
    
    // If already within budget, return as is
    if (currentTotal <= targetBudget) {
      return optimizedItems;
    }
    
    // Calculate adjustment factor
    final double adjustmentFactor = targetBudget / currentTotal;
    
    // Adjust quantities proportionally
    for (int i = 0; i < optimizedItems.length; i++) {
      final item = optimizedItems[i];
      final double newQuantity = item.quantity * adjustmentFactor;
      
      // Create new quote item with adjusted quantity
      optimizedItems[i] = QuoteItem(
        id: item.id,
        quoteId: item.quoteId,
        dishId: item.dishId,
        dishName: item.dishName,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
        totalPrice: item.unitPrice * newQuantity,
        notes: item.notes,
        quotedPortionSizeGrams: item.quotedPortionSizeGrams,
        quotedBaseFoodCostPerServing: item.quotedBaseFoodCostPerServing,
        percentageTakeRate: item.percentageTakeRate,
        estimatedServings: (newQuantity).round(),
        estimatedTotalWeightGrams: item.estimatedTotalWeightGrams != null ? 
          item.estimatedTotalWeightGrams! * adjustmentFactor : null,
        estimatedItemFoodCost: item.estimatedItemFoodCost != null ? 
          item.estimatedItemFoodCost! * adjustmentFactor : null,
        dishObject: item.dishObject,
      );
    }
    
    return optimizedItems;
  }

  /// Check for allergen conflicts in the quote menu
  Map<String, List<String>> checkAllergenConflicts(Quote quote) {
    final Map<String, List<String>> allergenConflicts = {};
    
    // Collect all allergens from dishes in the quote
    for (final item in quote.items) {
      if (item.dishObject != null) {
        final Dish dish = item.dishObject!;
        
        for (final allergen in dish.allergens) {
          if (!allergenConflicts.containsKey(allergen)) {
            allergenConflicts[allergen] = [];
          }
          
          // Check if this allergen is already in the list
          if (!allergenConflicts[allergen]!.contains(dish.name)) {
            allergenConflicts[allergen]!.add(dish.name);
          }
        }
      }
    }
    
    // Filter out allergens that only appear in one dish
    allergenConflicts.removeWhere((allergen, dishes) => dishes.length <= 1);
    
    return allergenConflicts;
  }

  /// Calculate food waste estimates for the quote
  Map<String, double> calculateFoodWasteEstimates(Quote quote) {
    double totalFoodWeight = 0.0;
    double estimatedWasteWeight = 0.0;
    double estimatedWasteCost = 0.0;
    
    for (final item in quote.items) {
      if (item.estimatedTotalWeightGrams != null) {
        totalFoodWeight += item.estimatedTotalWeightGrams!;
        
        // Estimate waste based on take rate
        final double takeRate = item.percentageTakeRate ?? 0.85; // Default 85% take rate
        final double wasteRate = 1.0 - takeRate;
        
        estimatedWasteWeight += item.estimatedTotalWeightGrams! * wasteRate;
        
        if (item.estimatedItemFoodCost != null) {
          estimatedWasteCost += item.estimatedItemFoodCost! * wasteRate;
        }
      }
    }
    
    return {
      'totalFoodWeight': totalFoodWeight,
      'estimatedWasteWeight': estimatedWasteWeight,
      'estimatedWasteCost': estimatedWasteCost,
      'wastePercentage': totalFoodWeight > 0 ? (estimatedWasteWeight / totalFoodWeight) * 100 : 0.0,
    };
  }
} 