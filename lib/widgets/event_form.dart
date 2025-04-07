import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

class EventForm extends StatefulWidget {
  final Event? event;

  const EventForm({super.key, this.event});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _eventNameController;
  late TextEditingController _venueAddressController;
  late TextEditingController _eventTypeController;
  late TextEditingController _totalGuestCountController;
  late TextEditingController _guestsMaleController;
  late TextEditingController _guestsFemaleController;
  late TextEditingController _guestsElderlyController;
  late TextEditingController _guestsYouthController;
  late TextEditingController _guestsChildController;
  late TextEditingController _notesController;
  DateTime? _eventDate;
  String _selectedClientId = '';
  String _selectedStatus = 'Planning';

  final List<String> _statusOptions = [
    'Planning',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _eventNameController = TextEditingController(text: widget.event?.eventName ?? '');
    _venueAddressController = TextEditingController(text: widget.event?.venueAddress ?? '');
    _eventTypeController = TextEditingController(text: widget.event?.eventType ?? '');
    _totalGuestCountController = TextEditingController(
      text: widget.event?.totalGuestCount?.toString() ?? '',
    );
    _guestsMaleController = TextEditingController(
      text: widget.event?.guestsMale.toString() ?? '0',
    );
    _guestsFemaleController = TextEditingController(
      text: widget.event?.guestsFemale.toString() ?? '0',
    );
    _guestsElderlyController = TextEditingController(
      text: widget.event?.guestsElderly.toString() ?? '0',
    );
    _guestsYouthController = TextEditingController(
      text: widget.event?.guestsYouth.toString() ?? '0',
    );
    _guestsChildController = TextEditingController(
      text: widget.event?.guestsChild.toString() ?? '0',
    );
    _notesController = TextEditingController(text: widget.event?.notes ?? '');
    _eventDate = widget.event?.eventDate;
    _selectedClientId = widget.event?.clientId ?? '';
    _selectedStatus = widget.event?.status ?? 'Planning';
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _venueAddressController.dispose();
    _eventTypeController.dispose();
    _totalGuestCountController.dispose();
    _guestsMaleController.dispose();
    _guestsFemaleController.dispose();
    _guestsElderlyController.dispose();
    _guestsYouthController.dispose();
    _guestsChildController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a client')),
        );
        return;
      }

      final event = Event(
        id: widget.event?.id,
        clientId: _selectedClientId,
        eventName: _eventNameController.text.isEmpty ? null : _eventNameController.text,
        eventDate: _eventDate,
        venueAddress: _venueAddressController.text.isEmpty ? null : _venueAddressController.text,
        eventType: _eventTypeController.text.isEmpty ? null : _eventTypeController.text,
        totalGuestCount: _totalGuestCountController.text.isEmpty
            ? null
            : int.parse(_totalGuestCountController.text),
        guestsMale: int.parse(_guestsMaleController.text),
        guestsFemale: int.parse(_guestsFemaleController.text),
        guestsElderly: int.parse(_guestsElderlyController.text),
        guestsYouth: int.parse(_guestsYouthController.text),
        guestsChild: int.parse(_guestsChildController.text),
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.event?.createdAt,
      );

      final appState = Provider.of<AppState>(context, listen: false);
      if (widget.event == null) {
        appState.addEvent(event);
      } else {
        appState.updateEvent(event);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Add Event' : 'Edit Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: 'Event Name'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _eventDate == null
                      ? 'Select Date'
                      : DateFormat('MMM d, y').format(_eventDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _venueAddressController,
                decoration: const InputDecoration(labelText: 'Venue Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventTypeController,
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalGuestCountController,
                decoration: const InputDecoration(labelText: 'Total Guest Count'),
                keyboardType: TextInputType.number,
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
          onPressed: _saveEvent,
          child: const Text('Save'),
        ),
      ],
    );
  }
} 