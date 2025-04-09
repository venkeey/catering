class CostOptimizationPrediction {
  final String dishId;
  final double predictedPortionSize;
  final double predictedPrice;
  final double confidenceScore;
  final Map<String, double> factors;
  final List<String> recommendations;

  CostOptimizationPrediction({
    required this.dishId,
    required this.predictedPortionSize,
    required this.predictedPrice,
    required this.confidenceScore,
    required this.factors,
    required this.recommendations,
  });

  Map<String, dynamic> toMap() {
    return {
      'dishId': dishId,
      'predictedPortionSize': predictedPortionSize,
      'predictedPrice': predictedPrice,
      'confidenceScore': confidenceScore,
      'factors': factors,
      'recommendations': recommendations,
    };
  }

  factory CostOptimizationPrediction.fromMap(Map<String, dynamic> map) {
    return CostOptimizationPrediction(
      dishId: map['dishId'] as String,
      predictedPortionSize: map['predictedPortionSize'] as double,
      predictedPrice: map['predictedPrice'] as double,
      confidenceScore: map['confidenceScore'] as double,
      factors: Map<String, double>.from(map['factors'] as Map),
      recommendations: List<String>.from(map['recommendations'] as List),
    );
  }
} 