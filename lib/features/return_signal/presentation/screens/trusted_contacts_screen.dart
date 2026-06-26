import 'package:flutter/material.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  // Dummy data for Layer 1
  final List<Map<String, String>> _contacts = [
    {'name': 'Alice', 'phone': '+1 555-0101'},
    {'name': 'Bob', 'phone': '+1 555-0102'},
    {'name': 'Charlie', 'phone': '+1 555-0103'},
  ];

  void _addContact() {
    _showContactDialog(isEdit: false);
  }

  void _editContact(int index) {
    _showContactDialog(isEdit: true, index: index);
  }

  void _deleteContact(int index) {
    setState(() {
      final removed = _contacts.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted contact: ${removed['name']}')),
      );
    });
  }

  Future<void> _showContactDialog({required bool isEdit, int? index}) async {
    final nameController = TextEditingController(
      text: isEdit && index != null ? _contacts[index]['name'] : '',
    );
    final phoneController = TextEditingController(
      text: isEdit && index != null ? _contacts[index]['phone'] : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Contact' : 'Add Contact'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (e.g. +1...)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    if (isEdit && index != null) {
                      _contacts[index] = {
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                      };
                    } else {
                      _contacts.add({
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                      });
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_contacts.isEmpty) {
              return const Center(
                child: Text('No trusted contacts found. Add one!'),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            contact['name']!.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        title: Text(contact['name']!),
                        subtitle: Text(contact['phone']!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editContact(index),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteContact(index),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
