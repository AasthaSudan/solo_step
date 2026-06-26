import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trusted_contacts_provider.dart';

class ManualCheckinScreen extends ConsumerStatefulWidget {
  const ManualCheckinScreen({super.key});

  @override
  ConsumerState<ManualCheckinScreen> createState() => _ManualCheckinScreenState();
}

class _ManualCheckinScreenState extends ConsumerState<ManualCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  TimeOfDay? _returnTime;
  String? _selectedContact;


  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _returnTime) {
      setState(() {
        _returnTime = picked;
      });
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_returnTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a return time')),
        );
        return;
      }
      if (_selectedContact == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a trusted contact')),
        );
        return;
      }
      
      // Dummy save callback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dummy Save: Activity "${_activityController.text}" '
              'returning at ${_returnTime!.format(context)} '
              'notifying $_selectedContact.'),
        ),
      );
      
      // Optionally pop the screen
      // Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(trustedContactsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Check-in'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Arm Return Signal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'If you do not check back in by the selected time, we will send an SMS to your trusted contact with your last known location.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _activityController,
                          decoration: const InputDecoration(
                            labelText: 'Activity Name',
                            hintText: 'e.g., Hiking Mount Fuji',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an activity name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Return By'),
                          subtitle: Text(
                            _returnTime != null
                                ? _returnTime!.format(context)
                                : 'Select a time',
                          ),
                          trailing: const Icon(Icons.access_time),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onTap: () => _selectTime(context),
                        ),
                        const SizedBox(height: 16),
                        contactsAsync.when(
                          data: (contacts) {
                            if (contacts.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No trusted contacts found. Please add one in settings.', style: TextStyle(color: Colors.red)),
                              );
                            }
                            
                            // Ensure the selected contact is still in the list, otherwise null it out
                            if (_selectedContact != null && !contacts.any((c) => c.id == _selectedContact)) {
                              _selectedContact = null;
                            }
                            
                            return DropdownButtonFormField<String>(
                              initialValue: _selectedContact,
                              decoration: const InputDecoration(
                                labelText: 'Trusted Contact',
                                border: OutlineInputBorder(),
                              ),
                              items: contacts.map((contact) {
                                return DropdownMenuItem(
                                  value: contact.id,
                                  child: Text('${contact.name} (${contact.phoneNumber})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedContact = value;
                                });
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Error loading contacts: $err'),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text('Arm Check-in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
