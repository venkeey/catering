import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/event_form.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const EventForm(),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final events = appState.events;
          if (events.isEmpty) {
            return const Center(
              child: Text('No events added yet. Tap + to add a new event.'),
            );
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final client = appState.clients.firstWhere(
                (c) => c.id == event.clientId,
                orElse: () => Client(
                  clientName: 'Unknown Client',
                  createdAt: DateTime.now(),
                ),
              );

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(event.eventName?[0] ?? 'E'),
                  ),
                  title: Text(event.eventName ?? 'Unnamed Event'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: ${client.clientName}'),
                      if (event.eventDate != null)
                        Text(
                          'Date: ${DateFormat('MMM d, y').format(event.eventDate!)}',
                        ),
                      if (event.venueAddress != null)
                        Text('Venue: ${event.venueAddress}'),
                      Text('Status: ${event.status}'),
                      Text(
                        'Guests: ${event.totalGuestCount ?? 0} (M: ${event.guestsMale}, F: ${event.guestsFemale}, E: ${event.guestsElderly}, Y: ${event.guestsYouth}, C: ${event.guestsChild})',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => EventForm(event: event),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Event'),
                              content: Text(
                                'Are you sure you want to delete ${event.eventName ?? 'this event'}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    appState.deleteEvent(event.id);
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
                    // TODO: Show event details
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