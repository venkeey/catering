import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dish.dart';
import '../providers/app_state.dart';

class DishForm extends StatefulWidget {
  final Dish? dish;

  const DishForm({super.key, this.dish});

  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _portionSizeController;
  late TextEditingController _baseFoodCostController;
  late TextEditingController _imageUrlController;
  String _selectedCategory = 'Starters';
  List<String> _selectedDietaryTags = [];
  String _selectedItemType = 'Standard';
  bool _isActive = true;
  Map<String, double> _ingredients = {};

  final List<String> _categories = [
    'Starters',
    'Salads',
    'Drinks',
    'Main Course',
    'Rotis',
    'Desserts',
    'Rice Dishes',
  ];

  final List<String> _dietaryTags = [
    'Veg',
    'Non-Veg',
    'Jain',
    'Gluten-Free',
    'Dairy-Free',
  ];

  final List<String> _itemTypes = [
    'Standard',
    'PercentageChoice',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.dish?.description ?? '');
    _portionSizeController = TextEditingController(
        text: widget.dish?.standardPortionSize.toString() ?? '');
    _baseFoodCostController = TextEditingController(
        text: widget.dish?.baseFoodCost.toString() ?? '');
    _imageUrlController =
        TextEditingController(text: widget.dish?.imageUrl ?? '');
    if (widget.dish != null) {
      _selectedCategory = _categories.contains(widget.dish!.category) 
          ? widget.dish!.category 
          : _categories.first;
      _selectedDietaryTags = List.from(widget.dish!.dietaryTags);
      _selectedItemType = _itemTypes.contains(widget.dish!.itemType)
          ? widget.dish!.itemType
          : _itemTypes.first;
      _isActive = widget.dish!.isActive;
      _ingredients = Map.from(widget.dish!.ingredients);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _portionSizeController.dispose();
    _baseFoodCostController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name'),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity (g/ml)'),
                keyboardType: TextInputType.number,
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
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  setState(() {
                    _ingredients[nameController.text] =
                        double.parse(quantityController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _saveDish() {
    if (_formKey.currentState!.validate()) {
      final dish = Dish(
        id: widget.dish?.id,
        name: _nameController.text,
        categoryId: _selectedCategory,
        category: _selectedCategory,
        basePrice: double.parse(_baseFoodCostController.text) * 1.3,
        baseFoodCost: double.parse(_baseFoodCostController.text),
        standardPortionSize: double.parse(_portionSizeController.text),
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        dietaryTags: _selectedDietaryTags,
        itemType: _selectedItemType,
        isActive: _isActive,
        ingredients: _ingredients,
        createdAt: widget.dish?.createdAt,
      );

      final appState = Provider.of<AppState>(context, listen: false);
      if (widget.dish == null) {
        appState.addDish(dish);
      } else {
        appState.updateDish(dish);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dish == null ? 'Add Dish' : 'Edit Dish'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portionSizeController,
                decoration:
                    const InputDecoration(labelText: 'Standard Portion Size (g/ml)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a portion size';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baseFoodCostController,
                decoration:
                    const InputDecoration(labelText: 'Base Food Cost (₹)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cost';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedItemType,
                decoration: const InputDecoration(labelText: 'Item Type'),
                items: _itemTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedItemType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _dietaryTags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: _selectedDietaryTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDietaryTags.add(tag);
                        } else {
                          _selectedDietaryTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Ingredients:'),
              const SizedBox(height: 8),
              ..._ingredients.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text('${entry.value} g/ml'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _ingredients.remove(entry.key);
                      });
                    },
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Add Ingredient'),
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
          onPressed: _saveDish,
          child: const Text('Save'),
        ),
      ],
    );
  }
} 