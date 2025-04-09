import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/quote_dish_service.dart';
import '../services/database_service.dart';

class QuoteDishAnalyzer extends StatefulWidget {
  final Quote quote;

  const QuoteDishAnalyzer({Key? key, required this.quote}) : super(key: key);

  @override
  State<QuoteDishAnalyzer> createState() => _QuoteDishAnalyzerState();
}

class _QuoteDishAnalyzerState extends State<QuoteDishAnalyzer> {
  late QuoteDishService _quoteDishService;
  Map<String, double> _nutritionInfo = {};
  Map<String, double> _optimalPortions = {};
  Map<String, List<String>> _allergenConflicts = {};
  Map<String, double> _financials = {};
  Map<String, double> _wasteEstimates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quoteDishService = QuoteDishService(DatabaseService());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Calculate all the data
    _nutritionInfo = _quoteDishService.calculateMenuNutrition(widget.quote);
    _optimalPortions = _quoteDishService.calculateOptimalPortions(widget.quote);
    _allergenConflicts = _quoteDishService.checkAllergenConflicts(widget.quote);
    _financials = _quoteDishService.calculateQuoteFinancials(widget.quote);
    _wasteEstimates = _quoteDishService.calculateFoodWasteEstimates(widget.quote);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Nutritional Analysis'),
            _buildNutritionCard(),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Optimal Portion Sizes'),
            _buildPortionsCard(),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Allergen Analysis'),
            _buildAllergensCard(),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Financial Analysis'),
            _buildFinancialsCard(),
            
            const SizedBox(height: 16),
            _buildSectionTitle('Waste Estimates'),
            _buildWasteCard(),
            
            const SizedBox(height: 16),
            _buildOptimizeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildNutritionRow('Calories', '${_nutritionInfo['calories']?.toStringAsFixed(0) ?? '0'} kcal'),
            _buildNutritionRow('Protein', '${_nutritionInfo['protein']?.toStringAsFixed(1) ?? '0'} g'),
            _buildNutritionRow('Carbohydrates', '${_nutritionInfo['carbohydrates']?.toStringAsFixed(1) ?? '0'} g'),
            _buildNutritionRow('Fat', '${_nutritionInfo['fat']?.toStringAsFixed(1) ?? '0'} g'),
            _buildNutritionRow('Fiber', '${_nutritionInfo['fiber']?.toStringAsFixed(1) ?? '0'} g'),
            _buildNutritionRow('Sugar', '${_nutritionInfo['sugar']?.toStringAsFixed(1) ?? '0'} g'),
            _buildNutritionRow('Sodium', '${_nutritionInfo['sodium']?.toStringAsFixed(1) ?? '0'} mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPortionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPortionRow('Appetizer', '${_optimalPortions['appetizer']?.toStringAsFixed(0) ?? '0'} g'),
            _buildPortionRow('Main Course', '${_optimalPortions['main']?.toStringAsFixed(0) ?? '0'} g'),
            _buildPortionRow('Side Dish', '${_optimalPortions['side']?.toStringAsFixed(0) ?? '0'} g'),
            _buildPortionRow('Dessert', '${_optimalPortions['dessert']?.toStringAsFixed(0) ?? '0'} g'),
            _buildPortionRow('Beverage', '${_optimalPortions['beverage']?.toStringAsFixed(0) ?? '0'} ml'),
          ],
        ),
      ),
    );
  }

  Widget _buildPortionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAllergensCard() {
    if (_allergenConflicts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No allergen conflicts detected.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _allergenConflicts.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key.toUpperCase()}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...entry.value.map((dish) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Text('• $dish'),
                )),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFinancialRow('Food Cost', '₹${_financials['totalFoodCost']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildFinancialRow('Overhead Cost', '₹${_financials['overheadCost']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildFinancialRow('Total Cost', '₹${_financials['totalCost']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildFinancialRow('Revenue', '₹${_financials['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildFinancialRow('Profit', '₹${_financials['profit']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildFinancialRow('Profit Margin', '${_financials['profitMargin']?.toStringAsFixed(1) ?? '0'}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildWasteCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildWasteRow('Total Food Weight', '${_wasteEstimates['totalFoodWeight']?.toStringAsFixed(0) ?? '0'} g'),
            _buildWasteRow('Estimated Waste', '${_wasteEstimates['estimatedWasteWeight']?.toStringAsFixed(0) ?? '0'} g'),
            _buildWasteRow('Waste Cost', '₹${_wasteEstimates['estimatedWasteCost']?.toStringAsFixed(2) ?? '0.00'}'),
            _buildWasteRow('Waste Percentage', '${_wasteEstimates['wastePercentage']?.toStringAsFixed(1) ?? '0'}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildOptimizeButton() {
    return ElevatedButton(
      onPressed: () async {
        // Show a dialog to enter target budget
        final TextEditingController controller = TextEditingController(
          text: _financials['totalRevenue']?.toStringAsFixed(2) ?? '0.00'
        );
        
        final result = await showDialog<double>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Optimize Menu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter target budget (per event):'),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '₹',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final value = double.tryParse(controller.text);
                  if (value != null) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text('Optimize'),
              ),
            ],
          ),
        );
        
        if (result != null) {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
          
          // Optimize the quote items
          final optimizedItems = await _quoteDishService.optimizeQuoteItems(widget.quote, result);
          
          // Close loading indicator
          Navigator.pop(context);
          
          // Show results
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Optimization Results'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Original total: ₹${_financials['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}'),
                    Text('New total: ₹${optimizedItems.fold(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    const Text('Would you like to apply these changes to your quote?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Here you would update the quote with the optimized items
                      // This would require a callback to the parent widget
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          }
        }
      },
      child: const Text('Optimize Menu'),
    );
  }
} 