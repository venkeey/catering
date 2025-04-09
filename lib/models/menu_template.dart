import 'package:uuid/uuid.dart';
import 'dish.dart';

class MenuTemplate {
  final String id;
  final String name;
  final String description;
  final String eventType;
  final List<String> dishIds;
  final Map<String, double> defaultPortions;
  final double estimatedCaloriesPerGuest;
  final Map<String, double> nutritionalBreakdown;
  final int recommendedDurationHours;
  final Map<String, double> demographicAdjustments;
  final List<String> tags;
  final bool isActive;

  MenuTemplate({
    String? id,
    required this.name,
    required this.description,
    required this.eventType,
    required this.dishIds,
    required this.defaultPortions,
    required this.estimatedCaloriesPerGuest,
    required this.nutritionalBreakdown,
    required this.recommendedDurationHours,
    required this.demographicAdjustments,
    required this.tags,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'eventType': eventType,
      'dishIds': dishIds,
      'defaultPortions': defaultPortions,
      'estimatedCaloriesPerGuest': estimatedCaloriesPerGuest,
      'nutritionalBreakdown': nutritionalBreakdown,
      'recommendedDurationHours': recommendedDurationHours,
      'demographicAdjustments': demographicAdjustments,
      'tags': tags,
      'isActive': isActive,
    };
  }

  factory MenuTemplate.fromMap(Map<String, dynamic> map) {
    return MenuTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      eventType: map['eventType'] as String,
      dishIds: List<String>.from(map['dishIds'] as List),
      defaultPortions: Map<String, double>.from(map['defaultPortions'] as Map),
      estimatedCaloriesPerGuest: map['estimatedCaloriesPerGuest'] as double,
      nutritionalBreakdown: Map<String, double>.from(map['nutritionalBreakdown'] as Map),
      recommendedDurationHours: map['recommendedDurationHours'] as int,
      demographicAdjustments: Map<String, double>.from(map['demographicAdjustments'] as Map),
      tags: List<String>.from(map['tags'] as List),
      isActive: map['isActive'] as bool,
    );
  }

  MenuTemplate copyWith({
    String? name,
    String? description,
    String? eventType,
    List<String>? dishIds,
    Map<String, double>? defaultPortions,
    double? estimatedCaloriesPerGuest,
    Map<String, double>? nutritionalBreakdown,
    int? recommendedDurationHours,
    Map<String, double>? demographicAdjustments,
    List<String>? tags,
    bool? isActive,
  }) {
    return MenuTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      dishIds: dishIds ?? this.dishIds,
      defaultPortions: defaultPortions ?? this.defaultPortions,
      estimatedCaloriesPerGuest: estimatedCaloriesPerGuest ?? this.estimatedCaloriesPerGuest,
      nutritionalBreakdown: nutritionalBreakdown ?? this.nutritionalBreakdown,
      recommendedDurationHours: recommendedDurationHours ?? this.recommendedDurationHours,
      demographicAdjustments: demographicAdjustments ?? this.demographicAdjustments,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }
} 