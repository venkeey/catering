import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/dish_form.dart';
import 'dish_details_screen.dart';

class DishesScreen extends StatelessWidget {
  const DishesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DishForm(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final dishes = appState.dishes;
          if (dishes.isEmpty) {
            return const Center(
              child: Text('No dishes added yet. Tap + to add a new dish.'),
            );
          }

          return ListView.builder(
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final dish = dishes[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: dish.imageUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(dish.imageUrl!),
                        )
                      : CircleAvatar(
                          child: Text(dish.name[0]),
                        ),
                  title: Text(dish.name),
                  subtitle: Text(
                    '${dish.category} - ₹${dish.baseFoodCost.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => DishForm(dish: dish),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Dish'),
                              content: Text(
                                'Are you sure you want to delete ${dish.name}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    appState.deleteDish(dish.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DishDetailsScreen(dish: dish),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 