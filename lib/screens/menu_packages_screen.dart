import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/menu_package.dart';
import '../models/package_item.dart';
import '../models/dish.dart';

class MenuPackagesScreen extends StatelessWidget {
  const MenuPackagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Packages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPackageDialog(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.error.isNotEmpty) {
            return Center(child: Text(appState.error));
          }

          final packages = appState.menuPackages;
          if (packages.isEmpty) {
            return const Center(
              child: Text('No menu packages found. Create one to get started!'),
            );
          }

          return ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return _MenuPackageCard(package: package);
            },
          );
        },
      ),
    );
  }

  void _showPackageDialog(BuildContext context, [MenuPackage? package]) {
    showDialog(
      context: context,
      builder: (context) => MenuPackageDialog(package: package),
    );
  }
}

class _MenuPackageCard extends StatelessWidget {
  final MenuPackage package;

  const _MenuPackageCard({Key? key, required this.package}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(package.name),
        subtitle: Text(package.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\$${package.basePrice.toStringAsFixed(2)}'),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showPackageDialog(context, package),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        children: [
          Consumer<AppState>(
            builder: (context, appState, child) {
              final items = appState.getPackageItemsForPackage(package.id!);
              final dishes = appState.getDishesForPackage(package.id!);

              return Column(
                children: [
                  ...dishes.map((dish) => ListTile(
                        title: Text(dish.name),
                        subtitle: Text(dish.description ?? ''),
                        trailing: Text('\$${dish.basePrice.toStringAsFixed(2)}'),
                      )),
                  TextButton(
                    onPressed: () => _showAddItemDialog(context, package),
                    child: const Text('Add Item'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPackageDialog(BuildContext context, MenuPackage package) {
    showDialog(
      context: context,
      builder: (context) => MenuPackageDialog(package: package),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Are you sure you want to delete ${package.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteMenuPackage(package.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, MenuPackage package) {
    showDialog(
      context: context,
      builder: (context) => AddPackageItemDialog(package: package),
    );
  }
}

class MenuPackageDialog extends StatefulWidget {
  final MenuPackage? package;

  const MenuPackageDialog({Key? key, this.package}) : super(key: key);

  @override
  State<MenuPackageDialog> createState() => _MenuPackageDialogState();
}

class _MenuPackageDialogState extends State<MenuPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _basePriceController;
  late TextEditingController _eventTypeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.package?.name);
    _descriptionController = TextEditingController(text: widget.package?.description);
    _basePriceController = TextEditingController(
      text: widget.package?.basePrice.toString(),
    );
    _eventTypeController = TextEditingController(text: widget.package?.eventType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _eventTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.package == null ? 'New Menu Package' : 'Edit Menu Package'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a description' : null,
              ),
              TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(labelText: 'Base Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a base price';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _eventTypeController,
                decoration: const InputDecoration(labelText: 'Event Type'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter an event type' : null,
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
          onPressed: _savePackage,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _savePackage() {
    if (_formKey.currentState?.validate() ?? false) {
      final package = MenuPackage(
        id: widget.package?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        basePrice: double.parse(_basePriceController.text),
        eventType: _eventTypeController.text,
        isActive: widget.package?.isActive ?? true,
        createdAt: widget.package?.createdAt ?? DateTime.now(),
      );

      if (widget.package == null) {
        context.read<AppState>().addMenuPackage(package);
      } else {
        context.read<AppState>().updateMenuPackage(package);
      }

      Navigator.pop(context);
    }
  }
}

class AddPackageItemDialog extends StatefulWidget {
  final MenuPackage package;

  const AddPackageItemDialog({Key? key, required this.package}) : super(key: key);

  @override
  State<AddPackageItemDialog> createState() => _AddPackageItemDialogState();
}

class _AddPackageItemDialogState extends State<AddPackageItemDialog> {
  Dish? _selectedDish;
  bool _isOptional = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item to Package'),
      content: Consumer<AppState>(
        builder: (context, appState, child) {
          final dishes = appState.dishes;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Dish>(
                value: _selectedDish,
                decoration: const InputDecoration(labelText: 'Select Dish'),
                items: dishes.map((dish) {
                  return DropdownMenuItem(
                    value: dish,
                    child: Text(dish.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDish = value;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Optional Item'),
                value: _isOptional,
                onChanged: (value) {
                  setState(() {
                    _isOptional = value ?? false;
                  });
                },
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedDish == null ? null : _saveItem,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _saveItem() {
    if (_selectedDish != null) {
      final item = PackageItem(
        packageId: widget.package.id!,
        dishId: _selectedDish!.id,
        isOptional: _isOptional,
      );

      context.read<AppState>().addPackageItem(item);
      Navigator.pop(context);
    }
  }
} 