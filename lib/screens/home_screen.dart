import 'package:flutter/material.dart';
import 'dishes_screen.dart';
import 'quotes_screen.dart';
import 'clients_screen.dart';
import 'events_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catererer'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: [
          _buildMenuCard(
            context,
            'Dishes',
            Icons.restaurant_menu,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DishesScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Quotes',
            Icons.description,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QuotesScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Clients',
            Icons.people,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Events',
            Icons.event,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
} 