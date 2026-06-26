import 'package:flutter/material.dart';

class ManualCheckinScreen extends StatefulWidget {
  const ManualCheckinScreen({super.key});

  @override
  State<ManualCheckinScreen> createState() => _ManualCheckinScreenState();
}

class _ManualCheckinScreenState extends State<ManualCheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  TimeOfDay? _returnTime;
  String? _selectedContact;

  final List<String> _dummyContacts = [
    'Alice (+1 555-0101)',
    'Bob (+1 555-0102)',
    'Charlie (+1 555-0103)',
  ];

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
                        DropdownButtonFormField<String>(
                          initialValue: _selectedContact,
                          decoration: const InputDecoration(
                            labelText: 'Trusted Contact',
                            border: OutlineInputBorder(),
                          ),
                          items: _dummyContacts.map((contact) {
                            return DropdownMenuItem(
                              value: contact,
                              child: Text(contact),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedContact = value;
                            });
                          },
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
