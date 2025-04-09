import 'package:flutter/material.dart';
import '../models/dish.dart';

class DishDetailsScreen extends StatelessWidget {
  final Dish dish;

  const DishDetailsScreen({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dish.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dish.imageUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    dish.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Dish Information',
              children: [
                _buildInfoRow('Name', dish.name),
                _buildInfoRow('Category', dish.category),
                _buildInfoRow('Item Type', dish.itemType),
                _buildInfoRow('Status', dish.isActive ? 'Active' : 'Inactive'),
                if (dish.description != null && dish.description!.isNotEmpty)
                  _buildInfoRow('Description', dish.description!),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Pricing & Portions',
              children: [
                _buildInfoRow('Base Price', '₹${dish.basePrice.toStringAsFixed(2)}'),
                _buildInfoRow('Food Cost', '₹${dish.baseFoodCost.toStringAsFixed(2)}'),
                _buildInfoRow('Standard Portion', '${dish.standardPortionSize} units'),
              ],
            ),
            if (dish.dietaryTags.isNotEmpty) ...[  
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Dietary Information',
                children: [
                  Wrap(
                    spacing: 8.0,
                    children: dish.dietaryTags.map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.green.shade100,
                    )).toList(),
                  ),
                ],
              ),
            ],
            if (dish.ingredients.isNotEmpty) ...[  
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Ingredients',
                children: [
                  ...dish.ingredients.entries.map((entry) => 
                    _buildInfoRow(entry.key, '${entry.value} units')
                  ).toList(),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Additional Information',
              children: [
                _buildInfoRow('Created On', _formatDate(dish.createdAt)),
                _buildInfoRow('ID', dish.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}