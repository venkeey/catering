import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/app_state.dart';

class ClientForm extends StatefulWidget {
  final Client? client;

  const ClientForm({super.key, this.client});

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _email1Controller;
  late TextEditingController _email2Controller;
  late TextEditingController _billingAddressController;
  late TextEditingController _companyNameController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController(text: widget.client?.clientName ?? '');
    _contactPersonController = TextEditingController(text: widget.client?.contactPerson ?? '');
    _phone1Controller = TextEditingController(text: widget.client?.phone1 ?? '');
    _phone2Controller = TextEditingController(text: widget.client?.phone2 ?? '');
    _email1Controller = TextEditingController(text: widget.client?.email1 ?? '');
    _email2Controller = TextEditingController(text: widget.client?.email2 ?? '');
    _billingAddressController = TextEditingController(text: widget.client?.billingAddress ?? '');
    _companyNameController = TextEditingController(text: widget.client?.companyName ?? '');
    _notesController = TextEditingController(text: widget.client?.notes ?? '');
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _contactPersonController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _email1Controller.dispose();
    _email2Controller.dispose();
    _billingAddressController.dispose();
    _companyNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveClient() {
    if (_formKey.currentState!.validate()) {
      final client = Client(
        id: widget.client?.id,
        clientName: _clientNameController.text,
        contactPerson: _contactPersonController.text.isEmpty ? null : _contactPersonController.text,
        phone1: _phone1Controller.text.isEmpty ? null : _phone1Controller.text,
        phone2: _phone2Controller.text.isEmpty ? null : _phone2Controller.text,
        email1: _email1Controller.text.isEmpty ? null : _email1Controller.text,
        email2: _email2Controller.text.isEmpty ? null : _email2Controller.text,
        billingAddress: _billingAddressController.text.isEmpty ? null : _billingAddressController.text,
        companyName: _companyNameController.text.isEmpty ? null : _companyNameController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.client?.createdAt,
      );

      final appState = Provider.of<AppState>(context, listen: false);
      if (widget.client == null) {
        appState.addClient(client);
      } else {
        appState.updateClient(client);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.client == null ? 'Add Client' : 'Edit Client'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: 'Client Name *'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a client name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone1Controller,
                decoration: const InputDecoration(labelText: 'Primary Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone2Controller,
                decoration: const InputDecoration(labelText: 'Secondary Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email1Controller,
                decoration: const InputDecoration(labelText: 'Primary Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email2Controller,
                decoration: const InputDecoration(labelText: 'Secondary Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _billingAddressController,
                decoration: const InputDecoration(labelText: 'Billing Address'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
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
          onPressed: _saveClient,
          child: const Text('Save'),
        ),
      ],
    );
  }
} 