import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/inventory_item.dart';

// Move the method outside of any class to make it accessible to both classes
void _showAddEditInventoryItemDialog(BuildContext context, [InventoryItem? item]) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: item?.name);
  final descriptionController = TextEditingController(text: item?.description);
  final quantityController = TextEditingController(text: item?.quantity.toString());
  final unitController = TextEditingController(text: item?.unit);
  final minimumQuantityController = TextEditingController(text: item?.minimumQuantity.toString());
  final reorderPointController = TextEditingController(text: item?.reorderPoint.toString());
  final costPerUnitController = TextEditingController(text: item?.costPerUnit.toString());
  final expiryDateController = TextEditingController(
    text: item?.expiryDate?.toIso8601String().split('T')[0],
  );
  String? selectedSupplierId = item?.supplierId;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item == null ? 'Add Inventory Item' : 'Edit Inventory Item'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: minimumQuantityController,
                decoration: const InputDecoration(labelText: 'Minimum Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: reorderPointController,
                decoration: const InputDecoration(labelText: 'Reorder Point'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: costPerUnitController,
                decoration: const InputDecoration(labelText: 'Cost per Unit'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: expiryDateController,
                decoration: const InputDecoration(labelText: 'Expiry Date (YYYY-MM-DD)'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  return DropdownButtonFormField<String>(
                    value: selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    items: appState.suppliers.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier.id,
                        child: Text(supplier.name),
                      );
                    }).toList(),
                    onChanged: (value) => selectedSupplierId = value,
                    validator: (value) => value == null ? 'Required' : null,
                  );
                },
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
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final newItem = InventoryItem(
                id: item?.id,
                name: nameController.text,
                description: descriptionController.text,
                quantity: double.parse(quantityController.text),
                unit: unitController.text,
                minimumQuantity: double.parse(minimumQuantityController.text),
                reorderPoint: double.parse(reorderPointController.text),
                costPerUnit: double.parse(costPerUnitController.text),
                expiryDate: DateTime.parse(expiryDateController.text),
                supplierId: selectedSupplierId!,
              );

              if (item == null) {
                context.read<AppState>().addInventoryItem(newItem);
              } else {
                context.read<AppState>().updateInventoryItem(newItem);
              }

              Navigator.pop(context);
            }
          },
          child: Text(item == null ? 'Add' : 'Save'),
        ),
      ],
    ),
  );
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditInventoryItemDialog(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(child: Text('Error: ${appState.error}'));
        
          if (appState.inventoryItems.isEmpty) {
            return const Center(child: Text('No inventory items found'));
          }

          return ListView.builder(
            itemCount: appState.inventoryItems.length,
            itemBuilder: (context, index) {
              final item = appState.inventoryItems[index];
              return _InventoryItemCard(item: item);
            },
          );
        },
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${item.quantity} ${item.unit}'),
            Text('Cost: \$${item.costPerUnit} per ${item.unit}'),
            if (item.expiryDate != null)
              Text(
                'Expires: ${item.expiryDate!.toIso8601String().split('T')[0]}',
                style: TextStyle(
                  color: item.expiryDate!.isBefore(DateTime.now())
                      ? Colors.red
                      : item.expiryDate!.isBefore(DateTime.now().add(const Duration(days: 30)))
                          ? Colors.orange
                          : null,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditInventoryItemDialog(context, item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deleteInventoryItem(item.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 