import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../models/inventory_item.dart';
import '../models/supplier.dart';

class PurchaseOrdersScreen extends StatelessWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditPurchaseOrderDialog(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.error.isNotEmpty) {
            return Center(child: Text('Error: ${appState.error}'));
          }
        
          if (appState.purchaseOrders.isEmpty) {
            return const Center(child: Text('No purchase orders found'));
          }

          return ListView.builder(
            itemCount: appState.purchaseOrders.length,
            itemBuilder: (context, index) {
              final order = appState.purchaseOrders[index];
              return _PurchaseOrderCard(order: order);
            },
          );
        },
      ),
    );
  }

  void _showAddEditPurchaseOrderDialog(BuildContext context, [PurchaseOrder? order]) {
    final formKey = GlobalKey<FormState>();
    final supplierIdController = TextEditingController(text: order?.supplierId);
    final orderDateController = TextEditingController(
      text: order?.orderDate.toIso8601String().split('T')[0],
    );
    final expectedDeliveryDateController = TextEditingController(
      text: order?.expectedDeliveryDate?.toIso8601String().split('T')[0],
    );
    final statusController = TextEditingController(text: order?.status);
    final notesController = TextEditingController(text: order?.notes);
    final totalAmountController = TextEditingController(
      text: order?.totalAmount.toString() ?? '0.0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order == null ? 'Add Purchase Order' : 'Edit Purchase Order'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return DropdownButtonFormField<String>(
                      value: supplierIdController.text.isEmpty ? null : supplierIdController.text,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: appState.suppliers.map((supplier) {
                        return DropdownMenuItem(
                          value: supplier.id,
                          child: Text(supplier.name),
                        );
                      }).toList(),
                      onChanged: (value) => supplierIdController.text = value ?? '',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    );
                  },
                ),
                TextFormField(
                  controller: orderDateController,
                  decoration: const InputDecoration(labelText: 'Order Date (YYYY-MM-DD)'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: expectedDeliveryDateController,
                  decoration: const InputDecoration(labelText: 'Expected Delivery Date (YYYY-MM-DD)'),
                ),
                TextFormField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newOrder = PurchaseOrder(
                  id: order?.id,
                  supplierId: supplierIdController.text,
                  orderDate: DateTime.parse(orderDateController.text),
                  expectedDeliveryDate: expectedDeliveryDateController.text.isNotEmpty
                      ? DateTime.parse(expectedDeliveryDateController.text)
                      : null,
                  status: statusController.text,
                  totalAmount: double.parse(totalAmountController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                final appState = Provider.of<AppState>(context, listen: false);
                if (order == null) {
                  appState.addPurchaseOrder(newOrder);
                } else {
                  appState.updatePurchaseOrder(newOrder);
                }

                Navigator.pop(context);
              }
            },
            child: Text(order == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderCard extends StatelessWidget {
  final PurchaseOrder order;

  const _PurchaseOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text('Order #${order.id?.substring(0, 8) ?? 'New'}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AppState>(
              builder: (context, appState, child) {
                final supplier = appState.suppliers.firstWhere(
                  (s) => s.id == order.supplierId,
                  orElse: () => Supplier(
                    id: order.supplierId,
                    name: 'Unknown Supplier',
                    contactPerson: 'N/A',
                    email: 'N/A',
                    phone: 'N/A',
                    address: 'N/A',
                  ),
                );
                return Text('Supplier: ${supplier.name}');
              },
            ),
            Text('Date: ${order.orderDate.toIso8601String().split('T')[0]}'),
            if (order.expectedDeliveryDate != null)
              Text('Expected Delivery: ${order.expectedDeliveryDate!.toIso8601String().split('T')[0]}'),
            Text('Status: ${order.status}'),
            Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
            if (order.notes?.isNotEmpty ?? false) Text('Notes: ${order.notes}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditPurchaseOrderDialog(context, order),
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
        title: const Text('Delete Purchase Order'),
        content: Text('Are you sure you want to delete this purchase order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AppState>().deletePurchaseOrder(order.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddEditPurchaseOrderDialog(BuildContext context, [PurchaseOrder? order]) {
    final formKey = GlobalKey<FormState>();
    final supplierIdController = TextEditingController(text: order?.supplierId);
    final orderDateController = TextEditingController(
      text: order?.orderDate.toIso8601String().split('T')[0],
    );
    final expectedDeliveryDateController = TextEditingController(
      text: order?.expectedDeliveryDate?.toIso8601String().split('T')[0],
    );
    final statusController = TextEditingController(text: order?.status);
    final notesController = TextEditingController(text: order?.notes);
    final totalAmountController = TextEditingController(
      text: order?.totalAmount.toString() ?? '0.0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order == null ? 'Add Purchase Order' : 'Edit Purchase Order'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<AppState>(
                  builder: (context, appState, child) {
                    return DropdownButtonFormField<String>(
                      value: supplierIdController.text.isEmpty ? null : supplierIdController.text,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                      items: appState.suppliers.map((supplier) {
                        return DropdownMenuItem(
                          value: supplier.id,
                          child: Text(supplier.name),
                        );
                      }).toList(),
                      onChanged: (value) => supplierIdController.text = value ?? '',
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    );
                  },
                ),
                TextFormField(
                  controller: orderDateController,
                  decoration: const InputDecoration(labelText: 'Order Date (YYYY-MM-DD)'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: expectedDeliveryDateController,
                  decoration: const InputDecoration(labelText: 'Expected Delivery Date (YYYY-MM-DD)'),
                ),
                TextFormField(
                  controller: statusController,
                  decoration: const InputDecoration(labelText: 'Status'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: totalAmountController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newOrder = PurchaseOrder(
                  id: order?.id,
                  supplierId: supplierIdController.text,
                  orderDate: DateTime.parse(orderDateController.text),
                  expectedDeliveryDate: expectedDeliveryDateController.text.isNotEmpty
                      ? DateTime.parse(expectedDeliveryDateController.text)
                      : null,
                  status: statusController.text,
                  totalAmount: double.parse(totalAmountController.text),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                final appState = Provider.of<AppState>(context, listen: false);
                if (order == null) {
                  appState.addPurchaseOrder(newOrder);
                } else {
                  appState.updatePurchaseOrder(newOrder);
                }

                Navigator.pop(context);
              }
            },
            child: Text(order == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
} 