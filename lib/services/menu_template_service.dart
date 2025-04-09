import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/menu_template.dart';
import '../models/nutritional_info.dart';
import '../models/dish.dart';
import 'database/dish_database_service.dart';

class MenuTemplateService {
  final DishDatabaseService _dishService;

  MenuTemplateService(this._dishService);

  /// Calculates portion sizes based on event duration and guest demographics
  Future<Map<String, double>> calculatePortionSizes({
    required List<String> dishIds,
    required int totalGuests,
    required int maleGuests,
    required int femaleGuests,
    required int elderlyGuests,
    required int youthGuests,
    required int childGuests,
    required int durationHours,
  }) async {
    try {
      final portionSizes = <String, double>{};
      final dishes = await Future.wait(
        dishIds.map((id) => _dishService.getDish(id)),
      );

      // Calculate demographic ratios
      final maleRatio = maleGuests / totalGuests;
      final femaleRatio = femaleGuests / totalGuests;
      final elderlyRatio = elderlyGuests / totalGuests;
      final youthRatio = youthGuests / totalGuests;
      final childRatio = childGuests / totalGuests;

      // Calculate duration factor
      double durationFactor = 1.0;
      if (durationHours > 4) {
        durationFactor = 0.8; // 20% reduction for events longer than 4 hours
      } else if (durationHours < 2) {
        durationFactor = 1.2; // 20% increase for events shorter than 2 hours
      }

      // Calculate portion sizes for each dish
      for (final dish in dishes) {
        if (dish == null) continue;

        // Base portion size
        double portionSize = dish.standardPortionSize;

        // Adjust for demographics
        portionSize *= (maleRatio * 1.2 + // Male guests typically eat 20% more
            femaleRatio * 0.9 + // Female guests typically eat 10% less
            elderlyRatio * 0.8 + // Elderly guests typically eat 20% less
            youthRatio * 1.1 + // Youth guests typically eat 10% more
            childRatio * 0.6); // Children typically eat 40% less

        // Adjust for duration
        portionSize *= durationFactor;

        // Store the calculated portion size
        portionSizes[dish.id] = portionSize;
      }

      return portionSizes;
    } catch (e) {
      debugPrint('Error calculating portion sizes: $e');
      return {};
    }
  }

  /// Calculates nutritional information for a menu
  Future<NutritionalInfo> calculateMenuNutrition({
    required List<String> dishIds,
    required Map<String, double> portionSizes,
    required int totalGuests,
    required int maleGuests,
    required int femaleGuests,
    required int elderlyGuests,
    required int youthGuests,
    required int childGuests,
    required int durationHours,
  }) async {
    try {
      final dishes = await Future.wait(
        dishIds.map((id) => _dishService.getDish(id)),
      );

      // Initialize total nutritional values
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbohydrates = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;
      double totalSodium = 0;
      final Map<String, double> totalVitamins = {};
      final Map<String, double> totalMinerals = {};
      final Set<String> allAllergens = {};

      // Calculate demographic ratios
      final maleRatio = maleGuests / totalGuests;
      final femaleRatio = femaleGuests / totalGuests;
      final elderlyRatio = elderlyGuests / totalGuests;
      final youthRatio = youthGuests / totalGuests;
      final childRatio = childGuests / totalGuests;

      // Calculate nutritional values for each dish
      for (final dish in dishes) {
        if (dish == null) continue;

        final portionSize = portionSizes[dish.id] ?? dish.standardPortionSize;
        final servings = totalGuests;

        // Scale nutritional values based on portion size and servings
        totalCalories += dish.calories * portionSize * servings;
        totalProtein += dish.protein * portionSize * servings;
        totalCarbohydrates += dish.carbohydrates * portionSize * servings;
        totalFat += dish.fat * portionSize * servings;
        totalFiber += dish.fiber * portionSize * servings;
        totalSugar += dish.sugar * portionSize * servings;
        totalSodium += dish.sodium * portionSize * servings;

        // Add vitamins and minerals
        for (final entry in dish.vitamins.entries) {
          totalVitamins[entry.key] = (totalVitamins[entry.key] ?? 0) + entry.value * portionSize * servings;
        }

        for (final entry in dish.minerals.entries) {
          totalMinerals[entry.key] = (totalMinerals[entry.key] ?? 0) + entry.value * portionSize * servings;
        }

        // Add allergens
        allAllergens.addAll(dish.allergens);
      }

      // Create nutritional info object
      final nutritionalInfo = NutritionalInfo(
        calories: totalCalories,
        protein: totalProtein,
        carbohydrates: totalCarbohydrates,
        fat: totalFat,
        fiber: totalFiber,
        sugar: totalSugar,
        sodium: totalSodium,
        vitamins: totalVitamins,
        minerals: totalMinerals,
        allergens: allAllergens.toList(),
        portionSize: portionSizes,
      );

      // Adjust for demographics
      return nutritionalInfo.adjustForDemographics(
        maleRatio: maleRatio,
        femaleRatio: femaleRatio,
        elderlyRatio: elderlyRatio,
        youthRatio: youthRatio,
        childRatio: childRatio,
      ).adjustForDuration(durationHours);
    } catch (e) {
      debugPrint('Error calculating menu nutrition: $e');
      return NutritionalInfo(
        calories: 0,
        protein: 0,
        carbohydrates: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        vitamins: {},
        minerals: {},
        allergens: [],
        portionSize: {},
      );
    }
  }

  /// Generates menu recommendations based on event type and requirements
  Future<List<MenuTemplate>> getMenuRecommendations({
    required String eventType,
    required int totalGuests,
    required int durationHours,
    required List<String> dietaryRestrictions,
    required double budget,
  }) async {
    try {
      // Get all dishes
      final allDishes = await _dishService.getDishes();

      // Filter dishes based on dietary restrictions
      final filteredDishes = allDishes.where((dish) {
        for (final restriction in dietaryRestrictions) {
          if (!dish.meetsDietaryRestriction(restriction)) {
            return false;
          }
        }
        return true;
      }).toList();

      // Group dishes by category
      final dishesByCategory = <String, List<Dish>>{};
      for (final dish in filteredDishes) {
        dishesByCategory[dish.category] = dishesByCategory[dish.category] ?? [];
        dishesByCategory[dish.category]!.add(dish);
      }

      // Create menu templates based on event type
      final templates = <MenuTemplate>[];

      switch (eventType.toLowerCase()) {
        case 'wedding':
          templates.addAll(_createWeddingMenus(
            dishesByCategory: dishesByCategory,
            totalGuests: totalGuests,
            durationHours: durationHours,
            budget: budget,
          ));
          break;
        case 'corporate':
          templates.addAll(_createCorporateMenus(
            dishesByCategory: dishesByCategory,
            totalGuests: totalGuests,
            durationHours: durationHours,
            budget: budget,
          ));
          break;
        case 'birthday':
          templates.addAll(_createBirthdayMenus(
            dishesByCategory: dishesByCategory,
            totalGuests: totalGuests,
            durationHours: durationHours,
            budget: budget,
          ));
          break;
        default:
          templates.addAll(_createGenericMenus(
            dishesByCategory: dishesByCategory,
            totalGuests: totalGuests,
            durationHours: durationHours,
            budget: budget,
          ));
      }

      return templates;
    } catch (e) {
      debugPrint('Error generating menu recommendations: $e');
      return [];
    }
  }

  /// Creates wedding menu templates
  List<MenuTemplate> _createWeddingMenus({
    required Map<String, List<Dish>> dishesByCategory,
    required int totalGuests,
    required int durationHours,
    required double budget,
  }) {
    final templates = <MenuTemplate>[];

    // Premium wedding menu
    if (budget >= totalGuests * 50) {
      templates.add(MenuTemplate(
        name: 'Premium Wedding Package',
        description: 'Elegant and sophisticated menu perfect for formal weddings',
        eventType: 'wedding',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 3),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 1200,
        nutritionalBreakdown: {
          'protein': 30,
          'carbohydrates': 40,
          'fat': 30,
        },
        recommendedDurationHours: 4,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['premium', 'formal', 'elegant'],
      ));
    }

    // Standard wedding menu
    if (budget >= totalGuests * 30) {
      templates.add(MenuTemplate(
        name: 'Standard Wedding Package',
        description: 'Beautiful and delicious menu suitable for most weddings',
        eventType: 'wedding',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 1000,
        nutritionalBreakdown: {
          'protein': 25,
          'carbohydrates': 45,
          'fat': 30,
        },
        recommendedDurationHours: 3,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['standard', 'elegant'],
      ));
    }

    // Budget wedding menu
    if (budget >= totalGuests * 20) {
      templates.add(MenuTemplate(
        name: 'Budget Wedding Package',
        description: 'Affordable yet tasty menu for budget-conscious couples',
        eventType: 'wedding',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 1),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 800,
        nutritionalBreakdown: {
          'protein': 20,
          'carbohydrates': 50,
          'fat': 30,
        },
        recommendedDurationHours: 2,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['budget', 'simple'],
      ));
    }

    return templates;
  }

  /// Creates corporate menu templates
  List<MenuTemplate> _createCorporateMenus({
    required Map<String, List<Dish>> dishesByCategory,
    required int totalGuests,
    required int durationHours,
    required double budget,
  }) {
    final templates = <MenuTemplate>[];

    // Premium corporate menu
    if (budget >= totalGuests * 40) {
      templates.add(MenuTemplate(
        name: 'Executive Corporate Package',
        description: 'Professional and sophisticated menu for important business events',
        eventType: 'corporate',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 1000,
        nutritionalBreakdown: {
          'protein': 35,
          'carbohydrates': 35,
          'fat': 30,
        },
        recommendedDurationHours: 2,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.0,
          'child': 0.0,
        },
        tags: ['premium', 'professional', 'business'],
      ));
    }

    // Standard corporate menu
    if (budget >= totalGuests * 25) {
      templates.add(MenuTemplate(
        name: 'Standard Corporate Package',
        description: 'Balanced and professional menu for business meetings',
        eventType: 'corporate',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 800,
        nutritionalBreakdown: {
          'protein': 30,
          'carbohydrates': 40,
          'fat': 30,
        },
        recommendedDurationHours: 1,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.0,
          'child': 0.0,
        },
        tags: ['standard', 'professional'],
      ));
    }

    // Budget corporate menu
    if (budget >= totalGuests * 15) {
      templates.add(MenuTemplate(
        name: 'Budget Corporate Package',
        description: 'Affordable and simple menu for casual business events',
        eventType: 'corporate',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 600,
        nutritionalBreakdown: {
          'protein': 25,
          'carbohydrates': 45,
          'fat': 30,
        },
        recommendedDurationHours: 1,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.0,
          'child': 0.0,
        },
        tags: ['budget', 'simple'],
      ));
    }

    return templates;
  }

  /// Creates birthday menu templates
  List<MenuTemplate> _createBirthdayMenus({
    required Map<String, List<Dish>> dishesByCategory,
    required int totalGuests,
    required int durationHours,
    required double budget,
  }) {
    final templates = <MenuTemplate>[];

    // Premium birthday menu
    if (budget >= totalGuests * 35) {
      templates.add(MenuTemplate(
        name: 'Premium Birthday Package',
        description: 'Fun and festive menu perfect for special birthday celebrations',
        eventType: 'birthday',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 3),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 1100,
        nutritionalBreakdown: {
          'protein': 25,
          'carbohydrates': 45,
          'fat': 30,
        },
        recommendedDurationHours: 3,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.2,
          'child': 0.7,
        },
        tags: ['premium', 'fun', 'festive'],
      ));
    }

    // Standard birthday menu
    if (budget >= totalGuests * 25) {
      templates.add(MenuTemplate(
        name: 'Standard Birthday Package',
        description: 'Delicious and fun menu for birthday parties',
        eventType: 'birthday',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 900,
        nutritionalBreakdown: {
          'protein': 20,
          'carbohydrates': 50,
          'fat': 30,
        },
        recommendedDurationHours: 2,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.2,
          'child': 0.7,
        },
        tags: ['standard', 'fun'],
      ));
    }

    // Budget birthday menu
    if (budget >= totalGuests * 15) {
      templates.add(MenuTemplate(
        name: 'Budget Birthday Package',
        description: 'Affordable and tasty menu for casual birthday celebrations',
        eventType: 'birthday',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main', 'dessert'], 1),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 700,
        nutritionalBreakdown: {
          'protein': 15,
          'carbohydrates': 55,
          'fat': 30,
        },
        recommendedDurationHours: 2,
        demographicAdjustments: {
          'male': 1.1,
          'female': 0.9,
          'elderly': 0.9,
          'youth': 1.2,
          'child': 0.7,
        },
        tags: ['budget', 'simple'],
      ));
    }

    return templates;
  }

  /// Creates generic menu templates
  List<MenuTemplate> _createGenericMenus({
    required Map<String, List<Dish>> dishesByCategory,
    required int totalGuests,
    required int durationHours,
    required double budget,
  }) {
    final templates = <MenuTemplate>[];

    // Premium generic menu
    if (budget >= totalGuests * 40) {
      templates.add(MenuTemplate(
        name: 'Premium Event Package',
        description: 'High-quality menu suitable for various events',
        eventType: 'generic',
        dishIds: _selectDishesForCategory(dishesByCategory, ['appetizer', 'main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 1000,
        nutritionalBreakdown: {
          'protein': 30,
          'carbohydrates': 40,
          'fat': 30,
        },
        recommendedDurationHours: 3,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['premium', 'versatile'],
      ));
    }

    // Standard generic menu
    if (budget >= totalGuests * 25) {
      templates.add(MenuTemplate(
        name: 'Standard Event Package',
        description: 'Balanced menu for various events',
        eventType: 'generic',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main', 'dessert'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 800,
        nutritionalBreakdown: {
          'protein': 25,
          'carbohydrates': 45,
          'fat': 30,
        },
        recommendedDurationHours: 2,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['standard', 'versatile'],
      ));
    }

    // Budget generic menu
    if (budget >= totalGuests * 15) {
      templates.add(MenuTemplate(
        name: 'Budget Event Package',
        description: 'Affordable menu for various events',
        eventType: 'generic',
        dishIds: _selectDishesForCategory(dishesByCategory, ['main'], 2),
        defaultPortions: {},
        estimatedCaloriesPerGuest: 600,
        nutritionalBreakdown: {
          'protein': 20,
          'carbohydrates': 50,
          'fat': 30,
        },
        recommendedDurationHours: 1,
        demographicAdjustments: {
          'male': 1.2,
          'female': 0.9,
          'elderly': 0.8,
          'youth': 1.1,
          'child': 0.6,
        },
        tags: ['budget', 'simple'],
      ));
    }

    return templates;
  }

  /// Helper method to select dishes for specific categories
  List<String> _selectDishesForCategory(
    Map<String, List<Dish>> dishesByCategory,
    List<String> categories,
    int dishesPerCategory,
  ) {
    final selectedDishes = <String>[];
    
    for (final category in categories) {
      final categoryDishes = dishesByCategory[category] ?? [];
      if (categoryDishes.isEmpty) continue;
      
      // Select up to dishesPerCategory dishes from this category
      final count = min(dishesPerCategory, categoryDishes.length);
      for (var i = 0; i < count; i++) {
        selectedDishes.add(categoryDishes[i].id);
      }
    }
    
    return selectedDishes;
  }
} 