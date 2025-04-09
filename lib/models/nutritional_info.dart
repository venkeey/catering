class NutritionalInfo {
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
  final Map<String, double> portionSize;

  NutritionalInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.vitamins,
    required this.minerals,
    required this.allergens,
    required this.portionSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'vitamins': vitamins,
      'minerals': minerals,
      'allergens': allergens,
      'portionSize': portionSize,
    };
  }

  factory NutritionalInfo.fromMap(Map<String, dynamic> map) {
    return NutritionalInfo(
      calories: map['calories'] as double,
      protein: map['protein'] as double,
      carbohydrates: map['carbohydrates'] as double,
      fat: map['fat'] as double,
      fiber: map['fiber'] as double,
      sugar: map['sugar'] as double,
      sodium: map['sodium'] as double,
      vitamins: Map<String, double>.from(map['vitamins'] as Map),
      minerals: Map<String, double>.from(map['minerals'] as Map),
      allergens: List<String>.from(map['allergens'] as List),
      portionSize: Map<String, double>.from(map['portionSize'] as Map),
    );
  }

  NutritionalInfo scale(double factor) {
    return NutritionalInfo(
      calories: calories * factor,
      protein: protein * factor,
      carbohydrates: carbohydrates * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      sugar: sugar * factor,
      sodium: sodium * factor,
      vitamins: Map.fromEntries(
        vitamins.entries.map((e) => MapEntry(e.key, e.value * factor)),
      ),
      minerals: Map.fromEntries(
        minerals.entries.map((e) => MapEntry(e.key, e.value * factor)),
      ),
      allergens: allergens,
      portionSize: Map.fromEntries(
        portionSize.entries.map((e) => MapEntry(e.key, e.value * factor)),
      ),
    );
  }

  NutritionalInfo adjustForDemographics({
    required double maleRatio,
    required double femaleRatio,
    required double elderlyRatio,
    required double youthRatio,
    required double childRatio,
  }) {
    // Define adjustment factors for different demographics
    const maleFactor = 1.2;
    const femaleFactor = 0.9;
    const elderlyFactor = 0.8;
    const youthFactor = 1.1;
    const childFactor = 0.6;

    // Calculate weighted average adjustment
    final adjustmentFactor = (maleRatio * maleFactor) +
        (femaleRatio * femaleFactor) +
        (elderlyRatio * elderlyFactor) +
        (youthRatio * youthFactor) +
        (childRatio * childFactor);

    return scale(adjustmentFactor);
  }

  NutritionalInfo adjustForDuration(int durationHours) {
    // Adjust portions based on event duration
    // Longer events might need smaller portions to prevent overeating
    double durationFactor = 1.0;
    if (durationHours > 4) {
      durationFactor = 0.8; // 20% reduction for events longer than 4 hours
    } else if (durationHours < 2) {
      durationFactor = 1.2; // 20% increase for events shorter than 2 hours
    }

    return scale(durationFactor);
  }

  Map<String, double> getMacronutrientRatios() {
    final total = protein + carbohydrates + fat;
    return {
      'protein': (protein / total) * 100,
      'carbohydrates': (carbohydrates / total) * 100,
      'fat': (fat / total) * 100,
    };
  }

  bool hasAllergen(String allergen) {
    return allergens.contains(allergen.toLowerCase());
  }

  bool meetsDietaryRestrictions(List<String> restrictions) {
    // Check if the dish meets specific dietary restrictions
    // This is a simplified implementation
    for (final restriction in restrictions) {
      switch (restriction.toLowerCase()) {
        case 'vegetarian':
          if (protein > 0 && !allergens.contains('meat')) return false;
          break;
        case 'vegan':
          if (protein > 0 && !allergens.contains('meat') && !allergens.contains('dairy')) return false;
          break;
        case 'gluten-free':
          if (allergens.contains('gluten')) return false;
          break;
        case 'dairy-free':
          if (allergens.contains('dairy')) return false;
          break;
        case 'nut-free':
          if (allergens.contains('nuts')) return false;
          break;
      }
    }
    return true;
  }
} 