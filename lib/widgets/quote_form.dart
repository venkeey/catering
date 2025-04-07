import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

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
    _notesController = TextEditingController(text: widget.quote?.notes ?? '');
    _termsAndConditionsController = TextEditingController(
      text: widget.quote?.termsAndConditions ?? '',
    );
    _quoteDate = widget.quote?.quoteDate ?? DateTime.now();
    _selectedClientId = widget.quote?.clientId ?? '';
    _selectedEventId = widget.quote?.eventId;
    _selectedCalculationMethod = widget.quote?.calculationMethod ?? 'Simple';
    _selectedStatus = widget.quote?.status ?? 'Draft';

    // Initialize selected dishes if editing an existing quote
    if (widget.quote != null) {
      _loadExistingQuoteItems();
    }
  }

  void _loadExistingQuoteItems() {
    final appState = Provider.of<AppState>(context, listen: false);
    final quoteItems = appState.getQuoteItemsForQuote(widget.quote!.id);
    
    for (final item in quoteItems) {
      final dish = appState.getDishForQuoteItem(item);
      if (dish != null) {
        if (dish.itemType == 'PercentageChoice') {
          _percentageChoiceDishes[dish.id] = item.percentageTakeRate ?? 100.0;
        } else {
          _selectedDishes[dish.id] = item.estimatedServings?.toDouble() ?? 1.0;
        }
      }
    }
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
        _selectedDishes[dishId] = 1.0; // Default quantity
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
        eventId: _selectedEventId,
        clientId: _selectedClientId,
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
      String quoteId;
      
      if (widget.quote == null) {
        appState.addQuote(quote);
        quoteId = quote.id;
      } else {
        appState.updateQuote(quote);
        quoteId = quote.id;
        
        // Delete existing quote items
        final existingItems = appState.getQuoteItemsForQuote(quoteId);
        for (final item in existingItems) {
          appState.deleteQuoteItem(item.id!);
        }
      }

      // Save quote items
      final dishes = appState.dishes;
      
      // Save regular dishes
      for (final dishId in _selectedDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final quantity = _selectedDishes[dishId] ?? 1.0;
        final totalGuests = int.parse(_totalGuestCountController.text);
        
        // Calculate estimated servings and cost
        int estimatedServings;
        double estimatedTotalWeightGrams;
        double estimatedItemFoodCost;
        
        if (_selectedCalculationMethod == 'Simple') {
          estimatedServings = quantity.toInt();
          estimatedTotalWeightGrams = dish.standardPortionSize * quantity;
          estimatedItemFoodCost = dish.baseFoodCost * quantity;
        } else {
          // Detailed calculation with demographics
          final maleGuests = int.parse(_guestsMaleController.text);
          final femaleGuests = int.parse(_guestsFemaleController.text);
          final elderlyGuests = int.parse(_guestsElderlyController.text);
          final youthGuests = int.parse(_guestsYouthController.text);
          final childGuests = int.parse(_guestsChildController.text);
          
          // Demographic multipliers
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
          
          estimatedServings = quantity.toInt();
          estimatedTotalWeightGrams = dish.standardPortionSize * quantity * averageMultiplier;
          estimatedItemFoodCost = dish.baseFoodCost * quantity * averageMultiplier;
        }
        
        final quoteItem = QuoteItem(
          quoteId: quoteId,
          dishId: dishId,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: estimatedTotalWeightGrams,
          estimatedItemFoodCost: estimatedItemFoodCost,
        );
        
        appState.addQuoteItem(quoteItem);
      }
      
      // Save percentage choice dishes
      for (final dishId in _percentageChoiceDishes.keys) {
        final dish = dishes.firstWhere((d) => d.id == dishId);
        final percentage = _percentageChoiceDishes[dishId] ?? 100.0;
        final totalGuests = int.parse(_totalGuestCountController.text);
        
        // Calculate estimated servings and cost
        int estimatedServings;
        double estimatedTotalWeightGrams;
        double estimatedItemFoodCost;
        
        if (_selectedCalculationMethod == 'Simple') {
          estimatedServings = ((totalGuests * percentage) / 100.0).round();
          estimatedTotalWeightGrams = dish.standardPortionSize * estimatedServings;
          estimatedItemFoodCost = dish.baseFoodCost * estimatedServings;
        } else {
          // Detailed calculation with demographics
          final maleGuests = int.parse(_guestsMaleController.text);
          final femaleGuests = int.parse(_guestsFemaleController.text);
          final elderlyGuests = int.parse(_guestsElderlyController.text);
          final youthGuests = int.parse(_guestsYouthController.text);
          final childGuests = int.parse(_guestsChildController.text);
          
          // Demographic multipliers
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
          
          estimatedServings = ((totalGuests * percentage) / 100.0).round();
          estimatedTotalWeightGrams = dish.standardPortionSize * estimatedServings * averageMultiplier;
          estimatedItemFoodCost = dish.baseFoodCost * estimatedServings * averageMultiplier;
        }
        
        final quoteItem = QuoteItem(
          quoteId: quoteId,
          dishId: dishId,
          quotedPortionSizeGrams: dish.standardPortionSize,
          quotedBaseFoodCostPerServing: dish.baseFoodCost,
          percentageTakeRate: percentage,
          estimatedServings: estimatedServings,
          estimatedTotalWeightGrams: estimatedTotalWeightGrams,
          estimatedItemFoodCost: estimatedItemFoodCost,
        );
        
        appState.addQuoteItem(quoteItem);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.quote == null ? 'Add Quote' : 'Edit Quote'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 16),
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const Text('Select Dishes', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final dishes = appState.dishes;
                  if (dishes.isEmpty) {
                    return const Text('No dishes available. Please add dishes first.');
                  }

                  return Column(
                    children: dishes.map((dish) {
                      final isSelected = _selectedDishes.containsKey(dish.id) || 
                                        _percentageChoiceDishes.containsKey(dish.id);
                      final isPercentageChoice = dish.itemType == 'PercentageChoice';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(dish.name),
                          subtitle: Text('${dish.category} - ₹${dish.baseFoodCost.toStringAsFixed(2)}'),
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
                    }).toList(),
                  );
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveQuote,
          child: const Text('Save'),
        ),
      ],
    );
  }
} 