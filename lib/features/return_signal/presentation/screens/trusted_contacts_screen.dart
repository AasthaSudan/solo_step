import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trusted_contacts_provider.dart';

class TrustedContactsScreen extends ConsumerStatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  ConsumerState<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {
  void _addContact() {
    _showContactDialog(isEdit: false);
  }

  void _editContact(String id, String name, String phone) {
    _showContactDialog(isEdit: true, id: id, initialName: name, initialPhone: phone);
  }

  void _deleteContact(String id, String name) {
    ref.read(trustedContactsProvider.notifier).deleteContact(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted contact: $name')),
    );
  }

  Future<void> _showContactDialog({required bool isEdit, String? id, String? initialName, String? initialPhone}) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController(text: initialPhone ?? '');
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
                  if (isEdit && id != null) {
                    ref.read(trustedContactsProvider.notifier).updateContact(
                      id,
                      nameController.text.trim(),
                      phoneController.text.trim(),
                    );
                  } else {
                    ref.read(trustedContactsProvider.notifier).addContact(
                      nameController.text.trim(),
                      phoneController.text.trim(),
                    );
                  }
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
    final contactsAsync = ref.watch(trustedContactsProvider);
    
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
            return contactsAsync.when(
              data: (contacts) {
                if (contacts.isEmpty) {
                  return const Center(
                    child: Text('No trusted contacts found. Add one!'),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                contact.name.isNotEmpty ? contact.name.substring(0, 1).toUpperCase() : '?',
                              ),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(contact.phoneNumber),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editContact(contact.id, contact.name, contact.phoneNumber),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteContact(contact.id, contact.name),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            );
          },
        ),
      ),
    );
  }
}
