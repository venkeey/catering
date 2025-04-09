import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../models/dish.dart';
import '../models/client.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../services/pdf_service_simple.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'quote_dish_analyzer.dart';

class QuoteForm extends StatefulWidget {
  final Quote? quote;

  const QuoteForm({super.key, this.quote});

  @override
  State<QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<QuoteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _totalGuestCountController;
  late TextEditingController _guestsMaleController;
  late TextEditingController _guestsFemaleController;
  late TextEditingController _guestsElderlyController;
  late TextEditingController _guestsYouthController;
  late TextEditingController _guestsChildController;
  late TextEditingController _overheadPercentageController;
  late TextEditingController _notesController;
  late TextEditingController _termsAndConditionsController;
  DateTime? _quoteDate;
  String _selectedClientId = '';
  String? _selectedEventId;
  String _selectedCalculationMethod = 'Simple';
  String _selectedStatus = 'Draft';
  String? _selectedCategory;
  String _searchQuery = '';
  String _templateName = '';
  final Map<String, double> _selectedDishes = {};
  final Map<String, double> _percentageChoiceDishes = {};

  final List<String> _calculationMethods = [
    'Simple',
    'DetailedWeight',
  ];

  final List<String> _statusOptions = [
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Revised',
  ];

  @override
  void initState() {
    super.initState();
    _totalGuestCountController = TextEditingController(
      text: widget.quote?.totalGuestCount.toString() ?? '',
    );
    _guestsMaleController = TextEditingController(
      text: widget.quote?.guestsMale.toString() ?? '0',
    );
    _guestsFemaleController = TextEditingController(
      text: widget.quote?.guestsFemale.toString() ?? '0',
    );
    _guestsElderlyController = TextEditingController(
      text: widget.quote?.guestsElderly.toString() ?? '0',
    );
    _guestsYouthController = TextEditingController(
      text: widget.quote?.guestsYouth.toString() ?? '0',
    );
    _guestsChildController = TextEditingController(
      text: widget.quote?.guestsChild.toString() ?? '0',
    );
    _overheadPercentageController = TextEditingController(
      text: widget.quote?.overheadPercentage.toString() ?? '30.0',
    );
    
    // Add listeners to update UI when values change
    _totalGuestCountController.addListener(() => setState(() {}));
    _guestsMaleController.addListener(() => setState(() {}));
    _guestsFemaleController.addListener(() => setState(() {}));
    _guestsElderlyController.addListener(() => setState(() {}));
    _guestsYouthController.addListener(() => setState(() {}));
    _guestsChildController.addListener(() => setState(() {}));
    _overheadPercentageController.addListener(() => setState(() {}));
    _notesController = TextEditingController(text: widget.quote?.notes ?? '');
    _termsAndConditionsController = TextEditingController(
      text: widget.quote?.termsAndConditions ?? '',
    );
    _quoteDate = widget.quote?.quoteDate ?? DateTime.now();
    _selectedClientId = widget.quote?.clientId.toString() ?? '';
    _selectedEventId = widget.quote?.eventId?.toString();
    _selectedCalculationMethod = widget.quote?.calculationMethod ?? 'Simple';
    _selectedStatus = widget.quote?.status ?? 'Draft';

    // Initialize selected dishes if editing an existing quote
    if (widget.quote != null) {
      _loadExistingQuoteItems();
    }
  }

  void _loadExistingQuoteItems() {
    debugPrint('QuoteForm: Loading existing quote items...');
    final appState = Provider.of<AppState>(context, listen: false);
    final quoteItems = appState.getQuoteItemsForQuote(widget.quote!.id.toString());
    debugPrint('QuoteForm: Found ${quoteItems.length} quote items');
    
    for (final item in quoteItems) {
      debugPrint('QuoteForm: Processing quote item ${item.id} for dish ${item.dishId}');
      final dish = appState.getDishForQuoteItem(item);
      if (dish != null) {
        debugPrint('QuoteForm: Found dish ${dish.name} of type ${dish.itemType}');
        if (dish.itemType == 'PercentageChoice') {
          _percentageChoiceDishes[dish.id] = item.percentageTakeRate ?? 100.0;
          debugPrint('QuoteForm: Added percentage choice dish with rate ${item.percentageTakeRate}');
        } else {
          _selectedDishes[dish.id] = item.estimatedServings?.toDouble() ?? 1.0;
          debugPrint('QuoteForm: Added regular dish with servings ${item.estimatedServings}');
        }
      } else {
        debugPrint('QuoteForm: WARNING - Dish not found for quote item ${item.id}');
      }
    }
    debugPrint('QuoteForm: Finished loading quote items. Selected dishes: ${_selectedDishes.length}, Percentage choices: ${_percentageChoiceDishes.length}');
  }

  @override
  void dispose() {
    _totalGuestCountController.dispose();
    _guestsMaleController.dispose();
    _guestsFemaleController.dispose();
    _guestsElderlyController.dispose();
    _guestsYouthController.dispose();
    _guestsChildController.dispose();
    _overheadPercentageController.dispose();
    _notesController.dispose();
    _termsAndConditionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _quoteDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _quoteDate) {
      setState(() {
        _quoteDate = picked;
      });
    }
  }

  void _toggleDishSelection(String dishId) {
    setState(() {
      if (_selectedDishes.containsKey(dishId)) {
        _selectedDishes.remove(dishId);
        _percentageChoiceDishes.remove(dishId);
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        final dish = appState.dishes.firstWhere((d) => d.id == dishId);
        
        if (dish.itemType == 'PercentageChoice') {
          _percentageChoiceDishes[dishId] = 100.0; // Default percentage
        } else {
          _selectedDishes[dishId] = 1.0; // Default quantity
        }
      }
    });
  }

  void _updateDishQuantity(String dishId, double quantity) {
    setState(() {
      _selectedDishes[dishId] = quantity;
    });
  }

  void _updatePercentageChoice(String dishId, double percentage) {
    setState(() {
      _percentageChoiceDishes[dishId] = percentage;
    });
  }
  
  void _addMenuPackage(String packageId) {
    final appState = Provider.of<AppState>(context, listen: false);
    final packageItems = appState.getPackageItemsForPackage(packageId);
    
    setState(() {
      for (final item in packageItems) {
        try {
          final dish = appState.dishes.firstWhere((d) => d.id == item.dishId);
          
          if (dish.itemType == 'PercentageChoice') {
            _percentageChoiceDishes[dish.id] = 100.0;
          } else {
            _selectedDishes[dish.id] = 1.0;
          }
        } catch (e) {
          // Skip dishes that don't exist
          debugPrint('Dish not found for package item: ${item.dishId}');
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu package added to quote')),
    );
  }
  
  void _saveAsTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this template:'),
            const SizedBox(height: 8),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _templateName = value;
                });
              },
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
              if (_templateName.isNotEmpty) {
                _saveTemplateToStorage();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _saveTemplateToStorage() async {
    final template = {
      'name': _templateName,
      'dishes': _selectedDishes.map((key, value) => MapEntry(key, value)),
      'percentageChoices': _percentageChoiceDishes.map((key, value) => MapEntry(key, value)),
      'calculationMethod': _selectedCalculationMethod,
      'overheadPercentage': _overheadPercentageController.text,
    };
    
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.saveQuoteTemplate(template);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "$_templateName" saved')),
    );
  }

  void _loadTemplate() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final templates = await appState.getQuoteTemplates();
    
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates found')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template['name'] as String),
                subtitle: Text('${(template['dishes'] as Map).length} dishes'),
                onTap: () {
                  _applyTemplate(template);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _selectedDishes.clear();
      _percentageChoiceDishes.clear();
      
      final dishes = template['dishes'] as Map;
      final percentageChoices = template['percentageChoices'] as Map;
      
      dishes.forEach((key, value) {
        _selectedDishes[key.toString()] = (value as num).toDouble();
      });
      
      percentageChoices.forEach((key, value) {
        _percentageChoiceDishes[key.toString()] = (value as num).toDouble();
      });
      
      _selectedCalculationMethod = template['calculationMethod'] as String;
      _overheadPercentageController.text = template['overheadPercentage'] as String;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template "${template['name']}" loaded')),
    );
  }
  
  void _showAIMenuOptimization({double? budgetPerGuest}) {
    // Check if we have enough guest data
    final totalGuests = int.tryParse(_totalGuestCountController.text) ?? 0;
    if (totalGuests == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter guest count information first')),
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Simulate AI processing (would connect to a real AI service in production)
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close loading indicator
      
      final appState = Provider.of<AppState>(context, listen: false);
      final dishes = appState.dishes;
      
      // Get demographic data
      final maleGuests = int.tryParse(_guestsMaleController.text) ?? 0;
      final femaleGuests = int.tryParse(_guestsFemaleController.text) ?? 0;
      final elderlyGuests = int.tryParse(_guestsElderlyController.text) ?? 0;
      final youthGuests = int.tryParse(_guestsYouthController.text) ?? 0;
      final childGuests = int.tryParse(_guestsChildController.text) ?? 0;
      
      // Calculate budget per person
      final budgetPerPerson = budgetPerGuest ?? 500.0; // Use provided budget or default to 500
      
      // Create optimized menu
      final optimizedMenu = <String, Map<String, dynamic>>{};
      final categories = <String>{};
      for (final dish in dishes) {
        categories.add(dish.category);
      }
      
      // Ensure balanced menu with at least one dish from each major category
      final selectedCategories = <String>{};
      final dishScores = <String, double>{};
      
      // Score dishes based on various factors
      for (final dish in dishes) {
        double score = 0;
        
        // Cost efficiency score
        final costEfficiency = 100 / (dish.baseFoodCost > 0 ? dish.baseFoodCost : 1);
        score += costEfficiency * 0.3;
        
        // Demographic appeal score
        if (maleGuests > femaleGuests && dish.category.contains('Meat')) {
          score += 20;
        }
        if (femaleGuests > maleGuests && dish.category.contains('Salad')) {
          score += 20;
        }
        if (elderlyGuests > totalGuests * 0.3 && dish.category.contains('Traditional')) {
          score += 15;
        }
        if (youthGuests > totalGuests * 0.3 && dish.category.contains('Fusion')) {
          score += 15;
        }
        if (childGuests > totalGuests * 0.2 && dish.category.contains('Kids')) {
          score += 25;
        }
        
        // Dietary considerations (simulated)
        if (dish.dietaryTags.contains('Vegetarian')) {
          score += 10; // Always good to have some vegetarian options
        }
        if (dish.dietaryTags.contains('Gluten-Free')) {
          score += 5; // Include some gluten-free options
        }
        
        // Seasonal bonus (simulated)
        final currentMonth = DateTime.now().month;
        if ((currentMonth >= 6 && currentMonth <= 8 && dish.category.contains('Summer')) ||
            (currentMonth >= 9 && currentMonth <= 11 && dish.category.contains('Autumn')) ||
            (currentMonth >= 12 || currentMonth <= 2 && dish.category.contains('Winter')) ||
            (currentMonth >= 3 && currentMonth <= 5 && dish.category.contains('Spring'))) {
          score += 15; // Seasonal dishes get a bonus
        }
        
        dishScores[dish.id] = score;
      }
      
      // Sort dishes by score
      final sortedDishes = dishScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Select top dishes while ensuring category balance
      final selectedDishes = <String>{};
      double totalCost = 0;
      
      // First, select at least one dish from each major category
      for (final category in ['Appetizer', 'Main Course', 'Side Dish', 'Dessert']) {
        for (final entry in sortedDishes) {
          final dish = dishes.firstWhere((d) => d.id == entry.key);
          if (dish.category.contains(category) && !selectedDishes.contains(dish.id)) {
            selectedDishes.add(dish.id);
            selectedCategories.add(dish.category);
            totalCost += dish.baseFoodCost * totalGuests;
            
            optimizedMenu[dish.id] = {
              'name': dish.name,
              'category': dish.category,
              'cost': dish.baseFoodCost,
              'score': entry.value,
              'reason': _getSelectionReason(dish, maleGuests, femaleGuests, elderlyGuests, youthGuests, childGuests),
            };
            
            break;
          }
        }
      }
      
      // Then add more dishes until we reach budget or have enough variety
      for (final entry in sortedDishes) {
        if (selectedDishes.contains(entry.key)) continue;
        
        final dish = dishes.firstWhere((d) => d.id == entry.key);
        final additionalCost = dish.baseFoodCost * totalGuests;
        
        if (totalCost + additionalCost <= budgetPerPerson * totalGuests && selectedDishes.length < 10) {
          selectedDishes.add(dish.id);
          selectedCategories.add(dish.category);
          totalCost += additionalCost;
          
          optimizedMenu[dish.id] = {
            'name': dish.name,
            'category': dish.category,
            'cost': dish.baseFoodCost,
            'score': entry.value,
            'reason': _getSelectionReason(dish, maleGuests, femaleGuests, elderlyGuests, youthGuests, childGuests),
          };
        }
      }
      
      // Show the optimized menu
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI-Optimized Menu'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Optimized for ${totalGuests} guests with a budget of ₹${budgetPerPerson.toStringAsFixed(2)} per person'),
                Text('Total estimated cost: ₹${totalCost.toStringAsFixed(2)} (₹${(totalCost / totalGuests).toStringAsFixed(2)} per person)'),
                const SizedBox(height: 8),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: optimizedMenu.length,
                    itemBuilder: (context, index) {
                      final dishId = optimizedMenu.keys.elementAt(index);
                      final dishInfo = optimizedMenu[dishId]!;
                      final dish = dishes.firstWhere((d) => d.id == dishId);
                      
                      return ListTile(
                        title: Text(dishInfo['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dishInfo['category']),
                            Text('Cost: ₹${dishInfo['cost'].toStringAsFixed(2)} per serving'),
                            Text(
                              dishInfo['reason'],
                              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            if (dish.itemType == 'PercentageChoice') {
                              setState(() {
                                _percentageChoiceDishes[dish.id] = 100.0;
                              });
                            } else {
                              setState(() {
                                _selectedDishes[dish.id] = 1.0;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                // Add all dishes from the optimized menu
                for (final dishId in optimizedMenu.keys) {
                  final dish = dishes.firstWhere((d) => d.id == dishId);
                  if (dish.itemType == 'PercentageChoice') {
                    setState(() {
                      _percentageChoiceDishes[dish.id] = 100.0;
                    });
                  } else {
                    setState(() {
                      _selectedDishes[dish.id] = 1.0;
                    });
                  }
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Optimized menu added to quote')),
                );
              },
              child: const Text('Use This Menu'),
            ),
          ],
        ),
      );
    });
  }
  
  String _getSelectionReason(Dish dish, int maleGuests, int femaleGuests, int elderlyGuests, int youthGuests, int childGuests) {
    // Generate a human-readable reason for why this dish was selected
    final reasons = <String>[];
    
    if (dish.baseFoodCost < 100) {
      reasons.add('Cost-effective option');
    }
    
    if (maleGuests > femaleGuests && dish.category.contains('Meat')) {
      reasons.add('Popular with male guests');
    }
    
    if (femaleGuests > maleGuests && dish.category.contains('Salad')) {
      reasons.add('Popular with female guests');
    }
    
    if (elderlyGuests > 0 && dish.category.contains('Traditional')) {
      reasons.add('Appeals to elderly guests');
    }
    
    if (youthGuests > 0 && dish.category.contains('Fusion')) {
      reasons.add('Modern option for younger guests');
    }
    
    if (childGuests > 0 && dish.category.contains('Kids')) {
      reasons.add('Kid-friendly option');
    }
    
    if (dish.dietaryTags.contains('Vegetarian')) {
      reasons.add('Vegetarian option');
    }
    
    if (dish.dietaryTags.contains('Gluten-Free')) {
      reasons.add('Gluten-free option');
    }
    
    if (reasons.isEmpty) {
      return 'Well-balanced menu item';
    }
    
    return reasons.join(', ');
  }
  
  Future<void> _generatePdfQuote() async {
    if (_selectedDishes.isEmpty && _percentageChoiceDishes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dishes first')),
      );
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final dishes = appState.dishes;
      final client = _selectedClientId.isNotEmpty
          ? appState.clients.firstWhere((c) => c.id == _selectedClientId)
          : null;
      final event = _selectedEventId != null
          ? appState.events.firstWhere((e) => e.id == _selectedEventId)
          : null;
      
      if (client == null) {
        throw Exception('Client not found');
      }
      
      // Calculate costs
      final totalFoodCost = _calculateTotalFoodCost();
      final overheadPercentage = double.tryParse(_overheadPercentageController.text) ?? 30.0;
      final overheadCost = totalFoodCost * (overheadPercentage / 100);
      final grandTotal = totalFoodCost + overheadCost;
      
      // Create quote items
      final quoteItems = <QuoteItem>[];
      
      // Add regular dishes
      for (final entry in _selectedDishes.entries) {
        final dishId = entry.key;
        final quantity = entry.value;
        
        final dish = dishes.firstWhere((d) => d.id == dishId);
        if (dish == null) continue;
        
        // Calculate estimated servings and costs based on guest count and demographics
        int estimatedServings = quantity.toInt();
        double estimatedTotalWeightGrams = dish.standardPortionSize * quantity;
        double estimatedItemFoodCost = dish.baseFoodCost * quantity;
        
        if (_selectedCalculationMethod == 'DetailedWeight') {
          final totalGuests = int.parse(_totalGuestCountController.text);
          final maleGuests = int.parse(_guestsMaleController.text);
          final femaleGuests = int.parse(_guestsFemaleController.text);
          final elderlyGuests = int.parse(_guestsElderlyController.text);
          final youthGuests = int.parse(_guestsYouthController.text);
          final childGuests = int.parse(_guestsChildController.text);
          
          // Calculate demographic multipliers
          final maleMultiplier = 1.2; // Male guests typically eat 20% more
          final femaleMultiplier = 0.9; // Female guests typically eat 10% less
          final elderlyMultiplier = 0.8; // Elderly guests typically eat 20% less
          final youthMultiplier = 1.1; // Youth guests typically eat 10% more
          final childMultiplier = 0.6; // Children typically eat 40% less
          
          // Calculate total multiplier based on demographics
          double totalMultiplier = 0.0;
          int totalDemographicGuests = 0;
          
          if (maleGuests > 0) {
            totalMultiplier += maleGuests * maleMultiplier;
            totalDemographicGuests += maleGuests;
          }
          
          if (femaleGuests > 0) {
            totalMultiplier += femaleGuests * femaleMultiplier;
            totalDemographicGuests += femaleGuests;
          }
          
          if (elderlyGuests > 0) {
            totalMultiplier += elderlyGuests * elderlyMultiplier;
            totalDemographicGuests += elderlyGuests;
          }
          
          if (youthGuests > 0) {
            totalMultiplier += youthGuests * youthMultiplier;
            totalDemographicGuests += youthGuests;
          }
          
          if (childGuests > 0) {
            totalMultiplier += childGuests * childMultiplier;
            totalDemographicGuests += childGuests;
          }
          
          // If no demographic breakdown is provided, use a default multiplier
          if (totalDemographicGuests == 0) {
            totalMultiplier = totalGuests * 1.0;
            totalDemographicGuests = totalGuests;
          }
          
          final averageMultiplier = totalMultiplier / totalDemographicGuests;
          
          estimatedServings = quantity.toInt();
          estimatedTotalWeightGrams = dish.standardPortionSize * quantity * averageMultiplier;
          estimatedItemFoodCost = dish.baseFoodCost * quantity * averageMultiplier;
        }
        
        final quoteItem = QuoteItem(
          quoteId: BigInt.from(0), // Will be updated when quote is saved
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: quantity,
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * quantity,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: estimatedTotalWeightGrams,
          estimatedItemFoodCost: estimatedItemFoodCost,
          dishObject: dish,
        );
        
        quoteItems.add(quoteItem);
      }
      
      // Add percentage choice dishes
      for (final entry in _percentageChoiceDishes.entries) {
        final dishId = entry.key;
        final percentage = entry.value;
        
        final dish = dishes.firstWhere((d) => d.id == dishId);
        if (dish == null) continue;
        
        // Calculate estimated servings and costs based on guest count and demographics
        int estimatedServings = ((int.parse(_totalGuestCountController.text) * percentage) / 100.0).round();
        double estimatedTotalWeightGrams = dish.standardPortionSize * estimatedServings;
        double estimatedItemFoodCost = dish.baseFoodCost * estimatedServings;
        
        if (_selectedCalculationMethod == 'DetailedWeight') {
          final totalGuests = int.parse(_totalGuestCountController.text);
          final maleGuests = int.parse(_guestsMaleController.text);
          final femaleGuests = int.parse(_guestsFemaleController.text);
          final elderlyGuests = int.parse(_guestsElderlyController.text);
          final youthGuests = int.parse(_guestsYouthController.text);
          final childGuests = int.parse(_guestsChildController.text);
          
          // Calculate demographic multipliers
          final maleMultiplier = 1.2; // Male guests typically eat 20% more
          final femaleMultiplier = 0.9; // Female guests typically eat 10% less
          final elderlyMultiplier = 0.8; // Elderly guests typically eat 20% less
          final youthMultiplier = 1.1; // Youth guests typically eat 10% more
          final childMultiplier = 0.6; // Children typically eat 40% less
          
          // Calculate total multiplier based on demographics
          double totalMultiplier = 0.0;
          int totalDemographicGuests = 0;
          
          if (maleGuests > 0) {
            totalMultiplier += maleGuests * maleMultiplier;
            totalDemographicGuests += maleGuests;
          }
          
          if (femaleGuests > 0) {
            totalMultiplier += femaleGuests * femaleMultiplier;
            totalDemographicGuests += femaleGuests;
          }
          
          if (elderlyGuests > 0) {
            totalMultiplier += elderlyGuests * elderlyMultiplier;
            totalDemographicGuests += elderlyGuests;
          }
          
          if (youthGuests > 0) {
            totalMultiplier += youthGuests * youthMultiplier;
            totalDemographicGuests += youthGuests;
          }
          
          if (childGuests > 0) {
            totalMultiplier += childGuests * childMultiplier;
            totalDemographicGuests += childGuests;
          }
          
          // If no demographic breakdown is provided, use a default multiplier
          if (totalDemographicGuests == 0) {
            totalMultiplier = totalGuests * 1.0;
            totalDemographicGuests = totalGuests;
          }
          
          final averageMultiplier = totalMultiplier / totalDemographicGuests;
          
          estimatedServings = ((totalGuests * percentage) / 100.0).round();
          estimatedTotalWeightGrams = dish.standardPortionSize * estimatedServings * averageMultiplier;
          estimatedItemFoodCost = dish.baseFoodCost * estimatedServings * averageMultiplier;
        }
        
        final quoteItem = QuoteItem(
          quoteId: BigInt.from(0), // Will be updated when quote is saved
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: estimatedServings.toDouble(),
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * estimatedServings,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: estimatedTotalWeightGrams,
          estimatedItemFoodCost: estimatedItemFoodCost,
          percentageTakeRate: percentage,
          dishObject: dish,
        );
        
        quoteItems.add(quoteItem);
      }
      
      // Create a quote object for the PDF service
      final quote = Quote(
        id: widget.quote?.id ?? BigInt.from(DateTime.now().millisecondsSinceEpoch),
        eventId: _selectedEventId != null ? BigInt.parse(_selectedEventId!) : null,
        clientId: BigInt.parse(_selectedClientId),
        quoteDate: _quoteDate ?? DateTime.now(),
        totalGuestCount: int.parse(_totalGuestCountController.text),
        guestsMale: int.parse(_guestsMaleController.text),
        guestsFemale: int.parse(_guestsFemaleController.text),
        guestsElderly: int.parse(_guestsElderlyController.text),
        guestsYouth: int.parse(_guestsYouthController.text),
        guestsChild: int.parse(_guestsChildController.text),
        calculationMethod: _selectedCalculationMethod,
        overheadPercentage: overheadPercentage,
        calculatedTotalFoodCost: totalFoodCost,
        calculatedOverheadCost: overheadCost,
        grandTotal: grandTotal,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        termsAndConditions: _termsAndConditionsController.text.isEmpty
            ? null
            : _termsAndConditionsController.text,
        status: _selectedStatus,
        items: quoteItems,
      );
      
      // Get selected dishes
      final selectedDishes = <Dish>[];
      for (final dishId in {..._selectedDishes.keys, ..._percentageChoiceDishes.keys}) {
        try {
          final dish = dishes.firstWhere((d) => d.id == dishId);
          selectedDishes.add(dish);
        } catch (e) {
          // Skip dishes that don't exist
          debugPrint('Dish not found: $dishId');
        }
      }
      
      // Generate PDF using the service
      final pdfService = PdfServiceSimple.create();
      final file = await pdfService.generateQuotePdf(
        quote: quote,
        client: client,
        event: event,
        selectedDishes: selectedDishes,
        dishQuantities: _selectedDishes,
        percentageChoices: _percentageChoiceDishes,
      );
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Show preview and print options
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Quote PDF Generated'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('The quote PDF has been generated successfully.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Save the Uint8List to a temporary file
                      final tempFile = File('${(await getTemporaryDirectory()).path}/quote_${quote.id}.pdf');
                      await tempFile.writeAsBytes(file);
                      OpenFile.open(tempFile.path);
                    },
                    child: const Text('Open'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Save the Uint8List to a temporary file
                      final tempFile = File('${(await getTemporaryDirectory()).path}/quote_${quote.id}.pdf');
                      await tempFile.writeAsBytes(file);
                      Share.shareXFiles(
                        [XFile(tempFile.path)],
                        subject: 'Quote for ${client.clientName}',
                      );
                    },
                    child: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }
  
  void _showBudgetCalculator() {
    // Initialize controllers with current values
    final totalGuestCount = int.tryParse(_totalGuestCountController.text) ?? 0;
    final budgetPerGuestController = TextEditingController(text: '500');
    final totalBudgetController = TextEditingController(text: (totalGuestCount * 500).toString());
    
    // Calculate current quote cost
    final totalFoodCost = _calculateTotalFoodCost();
    final overheadPercentage = double.tryParse(_overheadPercentageController.text) ?? 30.0;
    final overheadCost = totalFoodCost * (overheadPercentage / 100);
    final grandTotal = totalFoodCost + overheadCost;
    final currentCostPerGuest = totalGuestCount > 0 ? grandTotal / totalGuestCount : 0;
    
    // Budget allocation percentages
    double foodPercentage = 70.0;
    double beveragePercentage = 15.0;
    double staffingPercentage = 10.0;
    double decorationPercentage = 5.0;
    
    // Function to update budget allocations
    void updateAllocations() {
      final totalBudget = double.tryParse(totalBudgetController.text) ?? 0;
      setState(() {
        foodPercentage = (totalFoodCost / totalBudget * 100).clamp(0, 100);
        beveragePercentage = 15.0;
        staffingPercentage = 10.0;
        decorationPercentage = 5.0;
        
        // Adjust if food cost exceeds total budget
        if (foodPercentage > 80) {
          foodPercentage = 80.0;
          beveragePercentage = 10.0;
          staffingPercentage = 7.0;
          decorationPercentage = 3.0;
        }
      });
    }
    
    // Show budget calculator dialog
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Function to update budget values
          void updateBudgetValues(bool fromPerGuest) {
            if (fromPerGuest) {
              final perGuest = double.tryParse(budgetPerGuestController.text) ?? 0;
              totalBudgetController.text = (perGuest * totalGuestCount).toString();
            } else {
              final total = double.tryParse(totalBudgetController.text) ?? 0;
              budgetPerGuestController.text = totalGuestCount > 0 
                  ? (total / totalGuestCount).toStringAsFixed(2)
                  : '0';
            }
            updateAllocations();
          }
          
          return AlertDialog(
            title: const Text('Budget Calculator'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guest count info
                    Text('Total Guests: $totalGuestCount'),
                    const SizedBox(height: 16),
                    
                    // Current quote cost
                    const Text('Current Quote Cost:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Total: ₹${grandTotal.toStringAsFixed(2)}'),
                    Text('Per Guest: ₹${currentCostPerGuest.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    
                    // Budget inputs
                    const Text('Budget Planning:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: budgetPerGuestController,
                            decoration: const InputDecoration(
                              labelText: 'Budget per Guest',
                              prefixText: '₹',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateBudgetValues(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: totalBudgetController,
                            decoration: const InputDecoration(
                              labelText: 'Total Budget',
                              prefixText: '₹',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateBudgetValues(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Budget allocation
                    const Text('Suggested Budget Allocation:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    // Food allocation
                    Row(
                      children: [
                        const Text('Food:'),
                        Expanded(
                          child: Slider(
                            value: foodPercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${foodPercentage.round()}%',
                            onChanged: (value) {
                              setState(() {
                                foodPercentage = value;
                                // Adjust other percentages proportionally
                                final remaining = 100 - foodPercentage;
                                final total = beveragePercentage + staffingPercentage + decorationPercentage;
                                if (total > 0) {
                                  beveragePercentage = remaining * (beveragePercentage / total);
                                  staffingPercentage = remaining * (staffingPercentage / total);
                                  decorationPercentage = remaining * (decorationPercentage / total);
                                }
                              });
                            },
                          ),
                        ),
                        Text('${foodPercentage.round()}%'),
                        const SizedBox(width: 8),
                        Text('₹${((double.tryParse(totalBudgetController.text) ?? 0) * foodPercentage / 100).toStringAsFixed(2)}'),
                      ],
                    ),
                    
                    // Beverage allocation
                    Row(
                      children: [
                        const Text('Beverages:'),
                        Expanded(
                          child: Slider(
                            value: beveragePercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${beveragePercentage.round()}%',
                            onChanged: (value) {
                              setState(() {
                                beveragePercentage = value;
                                // Adjust other percentages proportionally
                                final remaining = 100 - beveragePercentage;
                                final total = foodPercentage + staffingPercentage + decorationPercentage;
                                if (total > 0) {
                                  foodPercentage = remaining * (foodPercentage / total);
                                  staffingPercentage = remaining * (staffingPercentage / total);
                                  decorationPercentage = remaining * (decorationPercentage / total);
                                }
                              });
                            },
                          ),
                        ),
                        Text('${beveragePercentage.round()}%'),
                        const SizedBox(width: 8),
                        Text('₹${((double.tryParse(totalBudgetController.text) ?? 0) * beveragePercentage / 100).toStringAsFixed(2)}'),
                      ],
                    ),
                    
                    // Staffing allocation
                    Row(
                      children: [
                        const Text('Staffing:'),
                        Expanded(
                          child: Slider(
                            value: staffingPercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${staffingPercentage.round()}%',
                            onChanged: (value) {
                              setState(() {
                                staffingPercentage = value;
                                // Adjust other percentages proportionally
                                final remaining = 100 - staffingPercentage;
                                final total = foodPercentage + beveragePercentage + decorationPercentage;
                                if (total > 0) {
                                  foodPercentage = remaining * (foodPercentage / total);
                                  beveragePercentage = remaining * (beveragePercentage / total);
                                  decorationPercentage = remaining * (decorationPercentage / total);
                                }
                              });
                            },
                          ),
                        ),
                        Text('${staffingPercentage.round()}%'),
                        const SizedBox(width: 8),
                        Text('₹${((double.tryParse(totalBudgetController.text) ?? 0) * staffingPercentage / 100).toStringAsFixed(2)}'),
                      ],
                    ),
                    
                    // Decoration allocation
                    Row(
                      children: [
                        const Text('Decoration:'),
                        Expanded(
                          child: Slider(
                            value: decorationPercentage,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${decorationPercentage.round()}%',
                            onChanged: (value) {
                              setState(() {
                                decorationPercentage = value;
                                // Adjust other percentages proportionally
                                final remaining = 100 - decorationPercentage;
                                final total = foodPercentage + beveragePercentage + staffingPercentage;
                                if (total > 0) {
                                  foodPercentage = remaining * (foodPercentage / total);
                                  beveragePercentage = remaining * (beveragePercentage / total);
                                  staffingPercentage = remaining * (staffingPercentage / total);
                                }
                              });
                            },
                          ),
                        ),
                        Text('${decorationPercentage.round()}%'),
                        const SizedBox(width: 8),
                        Text('₹${((double.tryParse(totalBudgetController.text) ?? 0) * decorationPercentage / 100).toStringAsFixed(2)}'),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Budget status
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: grandTotal > (double.tryParse(totalBudgetController.text) ?? 0) 
                            ? Colors.red.shade100 
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            grandTotal > (double.tryParse(totalBudgetController.text) ?? 0) 
                                ? Icons.warning 
                                : Icons.check_circle,
                            color: grandTotal > (double.tryParse(totalBudgetController.text) ?? 0) 
                                ? Colors.red 
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              grandTotal > (double.tryParse(totalBudgetController.text) ?? 0) 
                                  ? 'Current quote exceeds budget by ₹${(grandTotal - (double.tryParse(totalBudgetController.text) ?? 0)).toStringAsFixed(2)}' 
                                  : 'Current quote is within budget with ₹${((double.tryParse(totalBudgetController.text) ?? 0) - grandTotal).toStringAsFixed(2)} remaining',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  // Apply the budget to the quote
                  final foodBudget = (double.tryParse(totalBudgetController.text) ?? 0) * foodPercentage / 100;
                  final currentFoodCost = totalFoodCost;
                  
                  if (currentFoodCost > foodBudget) {
                    // Show warning that current menu exceeds food budget
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Budget Warning'),
                        content: Text(
                          'Your current menu cost (₹${currentFoodCost.toStringAsFixed(2)}) exceeds the food budget (₹${foodBudget.toStringAsFixed(2)})\n\nWould you like to optimize your menu to fit within the budget?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('No, Keep Current Menu'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                              // Call the AI menu optimization with budget constraint
                              _showAIMenuOptimization(budgetPerGuest: double.tryParse(budgetPerGuestController.text) ?? 500);
                            },
                            child: const Text('Yes, Optimize Menu'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Budget of ₹${(double.tryParse(totalBudgetController.text) ?? 0).toStringAsFixed(2)} applied')),
                    );
                  }
                },
                child: const Text('Apply Budget'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showSeasonalMenuSuggestions() {

    final appState = Provider.of<AppState>(context, listen: false);
    final dishes = appState.dishes;
    
    // Determine current season
    final now = DateTime.now();
    final month = now.month;
    String currentSeason;
    String nextSeason;
    
    if (month >= 3 && month <= 5) {
      currentSeason = 'Spring';
      nextSeason = 'Summer';
    } else if (month >= 6 && month <= 8) {
      currentSeason = 'Summer';
      nextSeason = 'Autumn';
    } else if (month >= 9 && month <= 11) {
      currentSeason = 'Autumn';
      nextSeason = 'Winter';
    } else {
      currentSeason = 'Winter';
      nextSeason = 'Spring';
    }
    
    // Define seasonal ingredients and themes
    final Map<String, List<String>> seasonalIngredients = {
      'Spring': ['Asparagus', 'Peas', 'Artichokes', 'Strawberries', 'Rhubarb', 'Mint', 'Lamb'],
      'Summer': ['Tomatoes', 'Corn', 'Zucchini', 'Berries', 'Watermelon', 'Basil', 'Grilled meats'],
      'Autumn': ['Pumpkin', 'Apples', 'Pears', 'Mushrooms', 'Sweet potatoes', 'Cinnamon', 'Sage'],
      'Winter': ['Citrus', 'Root vegetables', 'Brussels sprouts', 'Pomegranate', 'Kale', 'Rosemary', 'Slow-cooked meats'],
    };
    
    // Filter dishes that match current season ingredients
    final currentSeasonDishes = <Dish>[];
    final nextSeasonDishes = <Dish>[];
    
    for (final dish in dishes) {
      // Check if dish contains any of the current season's ingredients in its name or description
      bool matchesCurrentSeason = false;
      bool matchesNextSeason = false;
      
      // Check current season
      for (final ingredient in seasonalIngredients[currentSeason]!) {
        if (dish.name.toLowerCase().contains(ingredient.toLowerCase()) ||
            (dish.description?.toLowerCase().contains(ingredient.toLowerCase()) ?? false)) {
          matchesCurrentSeason = true;
          break;
        }
      }
      
      // Check next season
      for (final ingredient in seasonalIngredients[nextSeason]!) {
        if (dish.name.toLowerCase().contains(ingredient.toLowerCase()) ||
            (dish.description?.toLowerCase().contains(ingredient.toLowerCase()) ?? false)) {
          matchesNextSeason = true;
          break;
        }
      }
      
      // Add to appropriate list
      if (matchesCurrentSeason) {
        currentSeasonDishes.add(dish);
      } else if (matchesNextSeason) {
        nextSeasonDishes.add(dish);
      }
    }
    
    // Show seasonal menu suggestions
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: const Text('Seasonal Menu Suggestions'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: currentSeason),
                    Tab(text: 'Upcoming: $nextSeason'),
                  ],
                  labelColor: Theme.of(context).primaryColor,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Current season tab
                      currentSeasonDishes.isEmpty
                          ? const Center(child: Text('No seasonal dishes found'))
                          : ListView.builder(
                              itemCount: currentSeasonDishes.length,
                              itemBuilder: (context, index) {
                                final dish = currentSeasonDishes[index];
                                return ListTile(
                                  title: Text(dish.name),
                                  subtitle: Text(dish.category),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      if (dish.itemType == 'PercentageChoice') {
                                        setState(() {
                                          _percentageChoiceDishes[dish.id] = 100.0;
                                        });
                                      } else {
                                        setState(() {
                                          _selectedDishes[dish.id] = 1.0;
                                        });
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${dish.name} added to quote')),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                      
                      // Next season tab
                      nextSeasonDishes.isEmpty
                          ? Center(child: Text('No upcoming $nextSeason dishes found'))
                          : ListView.builder(
                              itemCount: nextSeasonDishes.length,
                              itemBuilder: (context, index) {
                                final dish = nextSeasonDishes[index];
                                return ListTile(
                                  title: Text(dish.name),
                                  subtitle: Text('${dish.category} - Coming soon!'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      if (dish.itemType == 'PercentageChoice') {
                                        setState(() {
                                          _percentageChoiceDishes[dish.id] = 100.0;
                                        });
                                      } else {
                                        setState(() {
                                          _selectedDishes[dish.id] = 1.0;
                                        });
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${dish.name} added to quote')),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Seasonal Ingredients for $currentSeason:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(seasonalIngredients[currentSeason]!.join(', ')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _shareQuote() async {
    if (_selectedDishes.isEmpty && _percentageChoiceDishes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dishes first')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final dishes = appState.dishes;
      final client = _selectedClientId.isNotEmpty
          ? appState.clients.firstWhere((c) => c.id == _selectedClientId)
          : null;
      final event = _selectedEventId != null
          ? appState.events.firstWhere((e) => e.id == _selectedEventId)
          : null;

      if (client == null) {
        throw Exception('Client not found');
      }

      // Calculate costs
      final totalFoodCost = _calculateTotalFoodCost();
      final overheadPercentage = double.tryParse(_overheadPercentageController.text) ?? 30.0;
      final overheadCost = totalFoodCost * (overheadPercentage / 100);
      final grandTotal = totalFoodCost + overheadCost;

      // Create quote object
      final quote = Quote(
        id: widget.quote?.id ?? BigInt.from(DateTime.now().millisecondsSinceEpoch),
        eventId: _selectedEventId != null ? BigInt.parse(_selectedEventId!) : null,
        clientId: BigInt.parse(_selectedClientId),
        quoteDate: _quoteDate ?? DateTime.now(),
        totalGuestCount: int.parse(_totalGuestCountController.text),
        guestsMale: int.parse(_guestsMaleController.text),
        guestsFemale: int.parse(_guestsFemaleController.text),
        guestsElderly: int.parse(_guestsElderlyController.text),
        guestsYouth: int.parse(_guestsYouthController.text),
        guestsChild: int.parse(_guestsChildController.text),
        calculationMethod: _selectedCalculationMethod,
        overheadPercentage: overheadPercentage,
        calculatedTotalFoodCost: totalFoodCost,
        calculatedOverheadCost: overheadCost,
        grandTotal: grandTotal,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        termsAndConditions: _termsAndConditionsController.text.isEmpty
            ? null
            : _termsAndConditionsController.text,
        status: _selectedStatus,
        items: [],
      );

      // Get selected dishes
      final selectedDishes = <Dish>[];
      for (final dishId in {..._selectedDishes.keys, ..._percentageChoiceDishes.keys}) {
        try {
          final dish = dishes.firstWhere((d) => d.id == dishId);
          selectedDishes.add(dish);
        } catch (e) {
          debugPrint('Dish not found: $dishId');
        }
      }

      // Generate PDF
      final pdfService = PdfServiceSimple.create();
      final file = await pdfService.generateQuotePdf(
        quote: quote,
        client: client,
        event: event,
        selectedDishes: selectedDishes,
        dishQuantities: _selectedDishes,
        percentageChoices: _percentageChoiceDishes,
      );

      // Close loading indicator
      Navigator.pop(context);

      // Share the PDF
      if (!mounted) return;
      // Save the Uint8List to a temporary file
      final tempFile = File('${(await getTemporaryDirectory()).path}/quote_${quote.id}.pdf');
      await tempFile.writeAsBytes(file);
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Quote for ${client.clientName}',
      );
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing quote: $e')),
      );
    }
  }
  
  void _showMenuBalanceAnalysis() {
    if (_selectedDishes.isEmpty && _percentageChoiceDishes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dishes first')),
      );
      return;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final dishes = appState.dishes;
    
    // Analyze menu balance
    final categoryCount = <String, int>{};
    final dietaryCount = <String, int>{};
    final priceRanges = <String, int>{
      'Budget': 0,
      'Mid-range': 0,
      'Premium': 0,
    };
    
    double totalCost = 0;
    int totalDishes = 0;
    
    // Count dishes by category and dietary restrictions
    for (final dishId in {..._selectedDishes.keys, ..._percentageChoiceDishes.keys}) {
      try {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        
        // Count by category
        categoryCount[dish.category] = (categoryCount[dish.category] ?? 0) + 1;
        
        // Count by dietary tags
        for (final tag in dish.dietaryTags) {
          dietaryCount[tag] = (dietaryCount[tag] ?? 0) + 1;
        }
        
        // Count by price range
        if (dish.baseFoodCost < 100) {
          priceRanges['Budget'] = priceRanges['Budget']! + 1;
        } else if (dish.baseFoodCost < 300) {
          priceRanges['Mid-range'] = priceRanges['Mid-range']! + 1;
        } else {
          priceRanges['Premium'] = priceRanges['Premium']! + 1;
        }
        
        totalCost += dish.baseFoodCost;
        totalDishes++;
      } catch (e) {
        // Skip dishes that don't exist
        debugPrint('Dish not found for analysis: $dishId');
      }
    }
    
    // Calculate average cost per dish
    final averageCost = totalDishes > 0 ? totalCost / totalDishes : 0;
    
    // Identify missing categories
    final essentialCategories = ['Appetizer', 'Main Course', 'Side Dish', 'Dessert'];
    final missingCategories = <String>[];
    
    for (final category in essentialCategories) {
      bool found = false;
      for (final existingCategory in categoryCount.keys) {
        if (existingCategory.contains(category)) {
          found = true;
          break;
        }
      }
      if (!found) {
        missingCategories.add(category);
      }
    }
    
    // Generate recommendations
    final recommendations = <String>[];
    
    if (missingCategories.isNotEmpty) {
      recommendations.add('Consider adding: ${missingCategories.join(', ')}');
    }
    
    if (dietaryCount['Vegetarian'] == null || dietaryCount['Vegetarian']! < 2) {
      recommendations.add('Add more vegetarian options');
    }
    
    if (priceRanges['Premium']! > totalDishes * 0.5) {
      recommendations.add('Menu is expensive - consider adding more budget-friendly options');
    }
    
    if (priceRanges['Budget']! > totalDishes * 0.7) {
      recommendations.add('Menu is very budget-focused - consider adding some premium options');
    }
    
    // Show the analysis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menu Balance Analysis'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total dishes: $totalDishes'),
                Text('Average cost per dish: ₹${averageCost.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                
                const Text('Category Distribution:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...categoryCount.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('${e.key}: ${e.value} dishes'),
                )),
                const SizedBox(height: 16),
                
                const Text('Dietary Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...dietaryCount.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('${e.key}: ${e.value} dishes'),
                )),
                const SizedBox(height: 16),
                
                const Text('Price Range:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...priceRanges.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('${e.key}: ${e.value} dishes'),
                )),
                const SizedBox(height: 16),
                
                if (recommendations.isNotEmpty) ...[  
                  const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text('• $r'),
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showDishRecommendations() {
    // Check if we have enough demographic data to make recommendations
    final totalGuests = int.tryParse(_totalGuestCountController.text) ?? 0;
    final maleGuests = int.tryParse(_guestsMaleController.text) ?? 0;
    final femaleGuests = int.tryParse(_guestsFemaleController.text) ?? 0;
    final elderlyGuests = int.tryParse(_guestsElderlyController.text) ?? 0;
    final youthGuests = int.tryParse(_guestsYouthController.text) ?? 0;
    final childGuests = int.tryParse(_guestsChildController.text) ?? 0;
    
    if (totalGuests == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter guest count information first')),
      );
      return;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final dishes = appState.dishes;
    
    // Calculate demographic percentages
    final malePercent = totalGuests > 0 ? (maleGuests / totalGuests) * 100 : 0;
    final femalePercent = totalGuests > 0 ? (femaleGuests / totalGuests) * 100 : 0;
    final elderlyPercent = totalGuests > 0 ? (elderlyGuests / totalGuests) * 100 : 0;
    final youthPercent = totalGuests > 0 ? (youthGuests / totalGuests) * 100 : 0;
    final childPercent = totalGuests > 0 ? (childGuests / totalGuests) * 100 : 0;
    
    // Simple recommendation algorithm
    final recommendations = <String, double>{};
    
    // Recommend dishes based on demographics
    for (final dish in dishes) {
      double score = 0;
      
      // These are simplified rules - in a real app, you'd have more sophisticated logic
      if (malePercent > 40 && dish.category.contains('Meat')) {
        score += 2;
      }
      
      if (femalePercent > 40 && dish.category.contains('Salad')) {
        score += 2;
      }
      
      if (elderlyPercent > 30 && dish.category.contains('Traditional')) {
        score += 2;
      }
      
      if (youthPercent > 30 && dish.category.contains('Fusion')) {
        score += 2;
      }
      
      if (childPercent > 20 && dish.category.contains('Kids')) {
        score += 3;
      }
      
      // Add some variety
      if (!_selectedDishes.containsKey(dish.id) && !_percentageChoiceDishes.containsKey(dish.id)) {
        score += 1;
      }
      
      if (score > 0) {
        recommendations[dish.id] = score;
      }
    }
    
    // Sort recommendations by score
    final sortedRecommendations = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5 recommendations
    final topRecommendations = sortedRecommendations.take(5).toList();
    
    if (topRecommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recommendations available based on current guest demographics')),
      );
      return;
    }
    
    // Show recommendations dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommended Dishes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: topRecommendations.length,
            itemBuilder: (context, index) {
              final dishId = topRecommendations[index].key;
              final dish = dishes.firstWhere((d) => d.id == dishId);
              return ListTile(
                title: Text(dish.name),
                subtitle: Text(dish.category),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (dish.itemType == 'PercentageChoice') {
                      setState(() {
                        _percentageChoiceDishes[dish.id] = 100.0;
                      });
                    } else {
                      setState(() {
                        _selectedDishes[dish.id] = 1.0;
                      });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${dish.name} added to quote')),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Add all recommended dishes
              for (final rec in topRecommendations) {
                final dishId = rec.key;
                final dish = dishes.firstWhere((d) => d.id == dishId);
                if (dish.itemType == 'PercentageChoice') {
                  setState(() {
                    _percentageChoiceDishes[dish.id] = 100.0;
                  });
                } else {
                  setState(() {
                    _selectedDishes[dish.id] = 1.0;
                  });
                }
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All recommended dishes added')),
              );
            },
            child: const Text('Add All'),
          ),
        ],
      ),
    );
  }
  

  List<Widget> _buildCategorizedDishList(List<Dish> dishes) {
    final dishByCategory = <String, List<Dish>>{};
    final result = <Widget>[];
    
    // Group dishes by category
    for (final dish in dishes) {
      if (!dishByCategory.containsKey(dish.category)) {
        dishByCategory[dish.category] = [];
      }
      dishByCategory[dish.category]!.add(dish);
    }
    
    // Create widgets for each category
    for (final entry in dishByCategory.entries) {
      // Add category header
      result.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      
      // Add dishes in this category
      for (final dish in entry.value) {
        final isSelected = _selectedDishes.containsKey(dish.id) || 
                          _percentageChoiceDishes.containsKey(dish.id);
        final isPercentageChoice = dish.itemType == 'PercentageChoice';
        
        result.add(_buildDishCard(dish, isSelected, isPercentageChoice));
      }
    }
    
    return result;
  }
  
  Widget _buildDishCard(Dish dish, bool isSelected, bool isPercentageChoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        title: Text(dish.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${dish.category} - ₹${dish.baseFoodCost.toStringAsFixed(2)}'),
            if (dish.description != null && dish.description!.isNotEmpty)
              Text(
                dish.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (dish.dietaryTags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: dish.dietaryTags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
          ],
        ),
        trailing: isSelected
            ? isPercentageChoice
                ? SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _percentageChoiceDishes[dish.id]?.toString() ?? '100',
                      decoration: const InputDecoration(
                        labelText: '%',
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final percentage = double.tryParse(value);
                        if (percentage != null) {
                          _updatePercentageChoice(dish.id, percentage);
                        }
                      },
                    ),
                  )
                : SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _selectedDishes[dish.id]?.toString() ?? '1',
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final quantity = double.tryParse(value);
                        if (quantity != null) {
                          _updateDishQuantity(dish.id, quantity);
                        }
                      },
                    ),
                  )
            : null,
        onTap: () => _toggleDishSelection(dish.id),
        selected: isSelected,
      ),
    );
  }

  double _calculateTotalFoodCost() {
    final appState = Provider.of<AppState>(context, listen: false);
    final dishes = appState.dishes;
    double totalCost = 0.0;
    
    if (_selectedCalculationMethod == 'Simple') {
      // Simple calculation method
      for (final dishId in _selectedDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final quantity = _selectedDishes[dishId] ?? 1.0;
        totalCost += dish.baseFoodCost * quantity;
      }
      
      // Add percentage choice dishes
      for (final dishId in _percentageChoiceDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final percentage = _percentageChoiceDishes[dishId] ?? 100.0;
        final totalGuests = int.tryParse(_totalGuestCountController.text) ?? 0;
        final servings = (totalGuests * percentage) / 100.0;
        totalCost += dish.baseFoodCost * servings;
      }
    } else {
      // Detailed weight-based calculation
      final totalGuests = int.tryParse(_totalGuestCountController.text) ?? 0;
      final maleGuests = int.tryParse(_guestsMaleController.text) ?? 0;
      final femaleGuests = int.tryParse(_guestsFemaleController.text) ?? 0;
      final elderlyGuests = int.tryParse(_guestsElderlyController.text) ?? 0;
      final youthGuests = int.tryParse(_guestsYouthController.text) ?? 0;
      final childGuests = int.tryParse(_guestsChildController.text) ?? 0;
      
      // Demographic multipliers (configurable in a real app)
      const maleMultiplier = 1.2;
      const femaleMultiplier = 0.9;
      const elderlyMultiplier = 0.8;
      const youthMultiplier = 1.1;
      const childMultiplier = 0.6;
      
      // Calculate average portion size based on demographics
      double totalMultiplier = 0.0;
      int totalDemographicGuests = 0;
      
      if (maleGuests > 0) {
        totalMultiplier += maleGuests * maleMultiplier;
        totalDemographicGuests += maleGuests;
      }
      
      if (femaleGuests > 0) {
        totalMultiplier += femaleGuests * femaleMultiplier;
        totalDemographicGuests += femaleGuests;
      }
      
      if (elderlyGuests > 0) {
        totalMultiplier += elderlyGuests * elderlyMultiplier;
        totalDemographicGuests += elderlyGuests;
      }
      
      if (youthGuests > 0) {
        totalMultiplier += youthGuests * youthMultiplier;
        totalDemographicGuests += youthGuests;
      }
      
      if (childGuests > 0) {
        totalMultiplier += childGuests * childMultiplier;
        totalDemographicGuests += childGuests;
      }
      
      // If no demographic breakdown is provided, use a default multiplier
      if (totalDemographicGuests == 0) {
        totalMultiplier = totalGuests * 1.0;
        totalDemographicGuests = totalGuests;
      }
      
      final averageMultiplier = totalMultiplier / totalDemographicGuests;
      
      // Calculate cost for each dish
      for (final dishId in _selectedDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final quantity = _selectedDishes[dishId] ?? 1.0;
        final adjustedQuantity = quantity * averageMultiplier;
        totalCost += dish.baseFoodCost * adjustedQuantity;
      }
      
      // Add percentage choice dishes
      for (final dishId in _percentageChoiceDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final percentage = _percentageChoiceDishes[dishId] ?? 100.0;
        final servings = (totalGuests * percentage) / 100.0;
        final adjustedServings = servings * averageMultiplier;
        totalCost += dish.baseFoodCost * adjustedServings;
      }
    }
    
    return totalCost;
  }

  void _saveQuote() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')),
        );
        return;
      }

      if (_selectedDishes.isEmpty && _percentageChoiceDishes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one dish')),
        );
        return;
      }

      final totalFoodCost = _calculateTotalFoodCost();
      final overheadPercentage = double.parse(_overheadPercentageController.text);
      final overheadCost = totalFoodCost * (overheadPercentage / 100);
      final grandTotal = totalFoodCost + overheadCost;

      final quote = Quote(
        id: widget.quote?.id,
        eventId: _selectedEventId != null ? BigInt.parse(_selectedEventId!) : null,
        clientId: BigInt.parse(_selectedClientId),
        quoteDate: _quoteDate ?? DateTime.now(),
        totalGuestCount: int.parse(_totalGuestCountController.text),
        guestsMale: int.parse(_guestsMaleController.text),
        guestsFemale: int.parse(_guestsFemaleController.text),
        guestsElderly: int.parse(_guestsElderlyController.text),
        guestsYouth: int.parse(_guestsYouthController.text),
        guestsChild: int.parse(_guestsChildController.text),
        calculationMethod: _selectedCalculationMethod,
        overheadPercentage: overheadPercentage,
        calculatedTotalFoodCost: totalFoodCost,
        calculatedOverheadCost: overheadCost,
        grandTotal: grandTotal,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        termsAndConditions: _termsAndConditionsController.text.isEmpty
            ? null
            : _termsAndConditionsController.text,
        status: _selectedStatus,
        items: [], // Add empty list for items, they will be added separately
      );

      final appState = Provider.of<AppState>(context, listen: false);
      String quoteId = quote.id.toString();
      
      if (widget.quote == null) {
        appState.addQuote(quote);
      } else {
        appState.updateQuote(quote);
        
        // Delete existing quote items
        final existingItems = appState.getQuoteItemsForQuote(quoteId);
        for (final item in existingItems) {
          appState.deleteQuoteItem(item.id.toString());
        }
      }

      // Get dishes from app state
      final dishes = appState.dishes;

      // Save regular dishes
      for (final entry in _selectedDishes.entries) {
        final dishId = entry.key;
        final quantity = entry.value;
        final dish = dishes.firstWhere((d) => d.id == dishId);
        
        // Calculate estimated servings and costs
        int estimatedServings = quantity.toInt();
        double estimatedTotalWeightGrams = dish.standardPortionSize * quantity;
        double estimatedItemFoodCost = dish.baseFoodCost * quantity;
        
        // If using detailed weight calculation, adjust based on demographics
        if (_selectedCalculationMethod == 'DetailedWeight') {
          final totalGuests = int.parse(_totalGuestCountController.text);
          final maleGuests = int.parse(_guestsMaleController.text);
          final femaleGuests = int.parse(_guestsFemaleController.text);
          final elderlyGuests = int.parse(_guestsElderlyController.text);
          final youthGuests = int.parse(_guestsYouthController.text);
          final childGuests = int.parse(_guestsChildController.text);
          
          // Calculate weighted average based on demographics
          double totalMultiplier = 0.0;
          int totalDemographicGuests = 0;
          
          // Base multipliers for each demographic
          const double maleMultiplier = 1.2; // Males typically eat 20% more
          const double femaleMultiplier = 0.9; // Females typically eat 10% less
          const double elderlyMultiplier = 0.8; // Elderly typically eat 20% less
          const double youthMultiplier = 1.1; // Youth typically eat 10% more
          if (maleGuests > 0) {
            totalMultiplier += maleGuests * maleMultiplier;
            totalDemographicGuests += maleGuests;
          }
          
          if (femaleGuests > 0) {
            totalMultiplier += femaleGuests * femaleMultiplier;
            totalDemographicGuests += femaleGuests;
          }
          
          if (elderlyGuests > 0) {
            totalMultiplier += elderlyGuests * elderlyMultiplier;
            totalDemographicGuests += elderlyGuests;
          }
          
          if (youthGuests > 0) {
            totalMultiplier += youthGuests * youthMultiplier;
            totalDemographicGuests += youthGuests;
          }
          
          // Define child multiplier
          const childMultiplier = 0.5;
          
          if (childGuests > 0) {
            totalMultiplier += childGuests * childMultiplier;
            totalDemographicGuests += childGuests;
          }
          
          // If no demographic breakdown is provided, use a default multiplier
          if (totalDemographicGuests == 0) {
            totalMultiplier = totalGuests * 1.0;
            totalDemographicGuests = totalGuests;
          }
          
          final averageMultiplier = totalMultiplier / totalDemographicGuests;
          
          estimatedServings = quantity.toInt();
          estimatedTotalWeightGrams = dish.standardPortionSize * quantity * averageMultiplier;
          estimatedItemFoodCost = dish.baseFoodCost * quantity * averageMultiplier;
        }
        
        final quoteItem = QuoteItem(
          quoteId: BigInt.parse(quoteId),
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: quantity,
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * quantity,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: estimatedTotalWeightGrams,
          estimatedItemFoodCost: estimatedItemFoodCost,
        );
        
        appState.addQuoteItem(quoteItem);
      }
      
      // Save percentage choice dishes
      for (final entry in _percentageChoiceDishes.entries) {
        final dishId = entry.key;
        final percentage = entry.value;
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final totalGuests = int.parse(_totalGuestCountController.text);
        final estimatedServings = ((totalGuests * percentage) / 100.0).round();
        
        final quoteItem = QuoteItem(
          quoteId: BigInt.parse(quoteId),
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: estimatedServings.toDouble(),
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * estimatedServings,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: dish.standardPortionSize * estimatedServings,
          estimatedItemFoodCost: dish.baseFoodCost * estimatedServings,
          percentageTakeRate: percentage,
        );
        
        appState.addQuoteItem(quoteItem);
      }

      // Show success message and navigate back
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote saved successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final clients = appState.clients;
    final events = appState.events;
    final dishes = appState.dishes;
    final menuPackages = appState.menuPackages;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote == null ? 'New Quote' : 'Edit Quote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // Create a temporary quote for analysis
              final tempQuote = _createQuote();
              if (tempQuote != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Quote Analysis'),
                      ),
                      body: QuoteDishAnalyzer(quote: tempQuote),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote details section
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quote Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          final clients = appState.clients;
                          return DropdownButtonFormField<String>(
                            value: _selectedClientId.isEmpty && clients.isNotEmpty
                                ? clients.first.id
                                : _selectedClientId,
                            decoration: const InputDecoration(labelText: 'Client *'),
                            items: clients.map((client) {
                              return DropdownMenuItem(
                                value: client.id,
                                child: Text(client.clientName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClientId = value!;
                                _selectedEventId = null; // Reset event when client changes
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a client';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          final events = appState.events
                              .where((event) => event.clientId == _selectedClientId)
                              .toList();
                          
                          if (events.isEmpty) {
                            return const Text('No events found for this client');
                          }
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedEventId,
                            decoration: const InputDecoration(labelText: 'Event (Optional)'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('None'),
                              ),
                              ...events.map((event) {
                                return DropdownMenuItem(
                                  value: event.id,
                                  child: Text(event.eventName ?? 'Unnamed Event'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedEventId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          _quoteDate == null
                              ? 'Select Date'
                              : DateFormat('MMM d, y').format(_quoteDate!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _totalGuestCountController,
                        decoration: const InputDecoration(labelText: 'Total Guest Count *'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter total guest count';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _guestsMaleController,
                              decoration: const InputDecoration(labelText: 'Male Guests'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextFormField(
                              controller: _guestsFemaleController,
                              decoration: const InputDecoration(labelText: 'Female Guests'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _guestsElderlyController,
                              decoration: const InputDecoration(labelText: 'Elderly Guests'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextFormField(
                              controller: _guestsYouthController,
                              decoration: const InputDecoration(labelText: 'Youth Guests'),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _guestsChildController,
                        decoration: const InputDecoration(labelText: 'Child Guests'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCalculationMethod,
                        decoration: const InputDecoration(labelText: 'Calculation Method'),
                        items: _calculationMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCalculationMethod = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _overheadPercentageController,
                        decoration: const InputDecoration(labelText: 'Overhead Percentage (%)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter overhead percentage';
                          }
                          final percentage = double.tryParse(value);
                          if (percentage == null) {
                            return 'Please enter a valid number';
                          }
                          if (percentage <= 0 || percentage > 100) {
                            return 'Percentage must be between 0 and 100';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _termsAndConditionsController,
                        decoration: const InputDecoration(labelText: 'Terms & Conditions'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Two-pane dish selection layout
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Dish Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.lightbulb_outline),
                                tooltip: 'Get Recommendations',
                                onPressed: _showDishRecommendations,
                              ),
                              IconButton(
                                icon: const Icon(Icons.auto_awesome),
                                tooltip: 'AI Menu Optimization',
                                onPressed: _showAIMenuOptimization,
                              ),
                              IconButton(
                                icon: const Icon(Icons.pie_chart),
                                tooltip: 'Menu Balance Analysis',
                                onPressed: _showMenuBalanceAnalysis,
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                tooltip: 'Seasonal Menu Suggestions',
                                onPressed: _showSeasonalMenuSuggestions,
                              ),
                              IconButton(
                                icon: const Icon(Icons.calculate),
                                tooltip: 'Budget Calculator',
                                onPressed: _showBudgetCalculator,
                              ),
                              Consumer<AppState>(
                                builder: (context, appState, child) {
                                  if (appState.menuPackages.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return PopupMenuButton<String>(
                                    tooltip: 'Add Menu Package',
                                    icon: const Icon(Icons.add_box),
                                    onSelected: (packageId) {
                                      _addMenuPackage(packageId);
                                    },
                                    itemBuilder: (context) => appState.menuPackages
                                        .map((package) => PopupMenuItem<String>(
                                              value: package.id,
                                              child: Text(package.name),
                                            ))
                                        .toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search and filter controls
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search dishes...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            hint: const Text('All Categories'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ...dishes.map((dish) => 
                                dish.category.trim().isEmpty ? "Uncategorized" : dish.category
                              ).toSet().map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Two-pane layout
                      SizedBox(
                        height: 500,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Available dishes pane
                            Expanded(
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Available Dishes', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: _buildAvailableDishesList(dishes),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Selected dishes pane
                            Expanded(
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Selected Dishes', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text('${_selectedDishes.length + _percentageChoiceDishes.length} items'),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                    Expanded(
                                      child: _buildSelectedDishesList(dishes),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Quote summary
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quote Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Food Cost:'),
                          Text('₹${_calculateTotalFoodCost().toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overhead (${_overheadPercentageController.text}%):'),
                          Text('₹${(_calculateTotalFoodCost() * (double.tryParse(_overheadPercentageController.text) ?? 30.0) / 100).toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '₹${(_calculateTotalFoodCost() * (1 + (double.tryParse(_overheadPercentageController.text) ?? 30.0) / 100)).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAvailableDishesList(List<Dish> dishes) {
    debugPrint('QuoteForm: Building available dishes list with ${dishes.length} dishes');
    
    // Debug dish categories
    final allCategories = dishes.map((d) => d.category).toSet();
    debugPrint('QuoteForm: Found categories: ${allCategories.join(', ')}');
    
    // First, let's assign categories to dishes that don't have one
    final categorizedDishes = dishes.map((dish) {
      if (dish.category == null || dish.category.trim().isEmpty) {
        // Try to determine category from categoryId
        String category = "Uncategorized";
        if (dish.categoryId.isNotEmpty) {
          final categoryId = int.tryParse(dish.categoryId);
          if (categoryId != null && categoryId >= 1 && categoryId <= 6) {
            final categories = [
              'Starters',
              'Main Course',
              'Non-Veg Main Course',
              'Rice & Breads',
              'Desserts',
              'Beverages',
            ];
            category = categories[categoryId - 1];
          }
        }
        
        // Create a new dish with the assigned category
        return dish.copyWith(category: category);
      }
      return dish;
    }).toList();
    
    // Filter dishes based on search query and category
    final filteredDishes = categorizedDishes.where((dish) {
      final matchesSearch = _searchQuery.isEmpty || 
                           dish.name.toLowerCase().contains(_searchQuery) ||
                           dish.category.toLowerCase().contains(_searchQuery) ||
                           (dish.description?.toLowerCase().contains(_searchQuery) ?? false);
      
      final matchesCategory = _selectedCategory == null || dish.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    debugPrint('QuoteForm: Filtered to ${filteredDishes.length} dishes');
    
    // Group dishes by category
    final dishesByCategory = <String, List<Dish>>{};
    for (final dish in filteredDishes) {
      // Use "Uncategorized" as fallback if category is empty or null
      String category = dish.category;
      if (category.trim().isEmpty) {
        category = "Uncategorized";
      }
      
      if (!dishesByCategory.containsKey(category)) {
        dishesByCategory[category] = [];
      }
      dishesByCategory[category]!.add(dish);
      
      // Debug each dish's category assignment
      debugPrint('QuoteForm: Assigned dish "${dish.name}" to category "$category" (original: "${dish.category}")');
    }
    
    // Sort categories alphabetically for better organization
    final sortedCategories = dishesByCategory.keys.toList()..sort();
    
    debugPrint('QuoteForm: Grouped dishes into ${dishesByCategory.length} categories');
    for (final category in sortedCategories) {
      debugPrint('QuoteForm: Category "$category" has ${dishesByCategory[category]!.length} dishes');
    }
    
    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryDishes = dishesByCategory[category]!;
        
        // Sort dishes alphabetically within each category
        categoryDishes.sort((a, b) => a.name.compareTo(b.name));
        
        return ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category),
              Text('${categoryDishes.length} items', 
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          initiallyExpanded: _selectedCategory != null && _selectedCategory == category,
          children: categoryDishes.map((dish) {
            final isSelected = _selectedDishes.containsKey(dish.id) || 
                              _percentageChoiceDishes.containsKey(dish.id);
            
            return ListTile(
              title: Text(dish.name),
              subtitle: Text('₹${dish.baseFoodCost.toStringAsFixed(2)}'),
              trailing: isSelected 
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.add_circle_outline),
              onTap: () {
                if (!isSelected) {
                  _toggleDishSelection(dish.id);
                } else {
                  // Allow toggling off by tapping again
                  _toggleDishSelection(dish.id);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildSelectedDishesList(List<Dish> dishes) {
    // Get all selected dish IDs
    final selectedDishIds = {..._selectedDishes.keys, ..._percentageChoiceDishes.keys};
    
    // Get the actual dishes
    final selectedDishes = dishes.where((dish) => selectedDishIds.contains(dish.id)).toList();
    
    if (selectedDishes.isEmpty) {
      return const Center(
        child: Text('No dishes selected. Drag dishes from the left panel or use the buttons above.'),
      );
    }
    
    // Group selected dishes by category
    final dishesByCategory = <String, List<Dish>>{};
    for (final dish in selectedDishes) {
      // Use "Uncategorized" as fallback if category is empty
      final category = dish.category.trim().isEmpty ? "Uncategorized" : dish.category;
      if (!dishesByCategory.containsKey(category)) {
        dishesByCategory[category] = [];
      }
      dishesByCategory[category]!.add(dish);
    }
    
    // Sort categories alphabetically
    final sortedCategories = dishesByCategory.keys.toList()..sort();
    
    debugPrint('QuoteForm: Grouped selected dishes into ${dishesByCategory.length} categories');
    for (final category in sortedCategories) {
      debugPrint('QuoteForm: Selected category "$category" has ${dishesByCategory[category]!.length} dishes');
    }
    
    return ListView.builder(
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryDishes = dishesByCategory[category]!;
        
        // Sort dishes alphabetically within each category
        categoryDishes.sort((a, b) => a.name.compareTo(b.name));
        
        return ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category),
              Text('${categoryDishes.length} items', 
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          initiallyExpanded: true,
          children: categoryDishes.map((dish) {
            final isPercentageChoice = dish.itemType == 'PercentageChoice';
            final quantity = isPercentageChoice 
              ? _percentageChoiceDishes[dish.id] ?? 100.0
              : _selectedDishes[dish.id] ?? 1.0;
            
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(dish.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹${dish.baseFoodCost.toStringAsFixed(2)}'),
                    if (dish.description != null && dish.description!.isNotEmpty)
                      Text(
                        dish.description!,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPercentageChoice)
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: quantity.toString(),
                          decoration: const InputDecoration(
                            labelText: '%',
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final percentage = double.tryParse(value);
                            if (percentage != null) {
                              _updatePercentageChoice(dish.id, percentage);
                            }
                          },
                        ),
                      )
                    else
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: quantity.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final newQuantity = double.tryParse(value);
                            if (newQuantity != null) {
                              _updateDishQuantity(dish.id, newQuantity);
                            }
                          },
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _toggleDishSelection(dish.id),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Quote? _createQuote() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Create quote items from selected dishes
      final List<QuoteItem> quoteItems = [];
      
      // Add regular dishes
      for (final entry in _selectedDishes.entries) {
        final dishId = entry.key;
        final quantity = entry.value;
        
        final dish = appState.dishes.firstWhere((d) => d.id == dishId);
        
        quoteItems.add(QuoteItem(
          quoteId: BigInt.from(0), // Temporary ID
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: quantity,
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * quantity,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: quantity.toInt(),
          estimatedTotalWeightGrams: dish.standardPortionSize * quantity,
          estimatedItemFoodCost: dish.baseFoodCost * quantity,
          dishObject: dish,
        ));
      }
      
      // Add percentage choice dishes
      for (final entry in _percentageChoiceDishes.entries) {
        final dishId = entry.key;
        final percentage = entry.value;
        
        final dish = appState.dishes.firstWhere((d) => d.id == dishId);
        final totalGuests = int.tryParse(_totalGuestCountController.text) ?? 0;
        final estimatedServings = (totalGuests * percentage / 100).round();
        
        quoteItems.add(QuoteItem(
          quoteId: BigInt.from(0), // Temporary ID
          dishId: BigInt.parse(dishId),
          dishName: dish.name,
          quantity: estimatedServings.toDouble(),
          unitPrice: dish.basePrice,
          totalPrice: dish.basePrice * estimatedServings,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          percentageTakeRate: percentage,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: dish.standardPortionSize * estimatedServings,
          estimatedItemFoodCost: dish.baseFoodCost * estimatedServings,
          dishObject: dish,
        ));
      }
      
      // Calculate totals
      final totalFoodCost = quoteItems.fold(0.0, (sum, item) => sum + (item.estimatedItemFoodCost ?? 0.0));
      final overheadPercentage = double.tryParse(_overheadPercentageController.text) ?? 30.0;
      final overheadCost = totalFoodCost * (overheadPercentage / 100);
      final grandTotal = totalFoodCost + overheadCost;
      
      // Create the quote
      return Quote(
        clientId: BigInt.parse(_selectedClientId),
        eventId: _selectedEventId != null ? BigInt.parse(_selectedEventId!) : null,
        quoteDate: _quoteDate ?? DateTime.now(),
        totalGuestCount: int.tryParse(_totalGuestCountController.text) ?? 0,
        guestsMale: int.tryParse(_guestsMaleController.text) ?? 0,
        guestsFemale: int.tryParse(_guestsFemaleController.text) ?? 0,
        guestsElderly: int.tryParse(_guestsElderlyController.text) ?? 0,
        guestsYouth: int.tryParse(_guestsYouthController.text) ?? 0,
        guestsChild: int.tryParse(_guestsChildController.text) ?? 0,
        calculationMethod: _selectedCalculationMethod,
        overheadPercentage: overheadPercentage,
        calculatedTotalFoodCost: totalFoodCost,
        calculatedOverheadCost: overheadCost,
        grandTotal: grandTotal,
        notes: _notesController.text,
        termsAndConditions: _termsAndConditionsController.text,
        status: _selectedStatus,
        items: quoteItems,
      );
    }
    
    return null;
  }
} 
