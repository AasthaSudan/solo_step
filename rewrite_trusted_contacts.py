import re

# Rewrite trusted_contacts_screen.dart
with open('lib/features/return_signal/presentation/screens/trusted_contacts_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trusted_contacts_provider.dart';"""
content = content.replace("import 'package:flutter/material.dart';", imports)

# Convert to ConsumerStatefulWidget
content = content.replace("class TrustedContactsScreen extends StatefulWidget", "class TrustedContactsScreen extends ConsumerStatefulWidget")
content = content.replace("State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();", "ConsumerState<TrustedContactsScreen> createState() => _TrustedContactsScreenState();")
content = content.replace("class _TrustedContactsScreenState extends State<TrustedContactsScreen> {", "class _TrustedContactsScreenState extends ConsumerState<TrustedContactsScreen> {")

# Remove dummy data and related state operations
dummy_data_pattern = re.compile(r"  // Dummy data for Layer 1.*?];\n\n", re.DOTALL)
content = dummy_data_pattern.sub("", content)

# Update _deleteContact
delete_old = """  void _deleteContact(int index) {
    setState(() {
      final removed = _contacts.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted contact: ${removed['name']}')),
      );
    });
  }"""
delete_new = """  void _deleteContact(String id, String name) {
    ref.read(trustedContactsProvider.notifier).deleteContact(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted contact: $name')),
    );
  }"""
content = content.replace(delete_old, delete_new)

# Update _showContactDialog signature and logic
dialog_old = """  Future<void> _showContactDialog({required bool isEdit, int? index}) async {
    final nameController = TextEditingController(
      text: isEdit && index != null ? _contacts[index]['name'] : '',
    );
    final phoneController = TextEditingController(
      text: isEdit && index != null ? _contacts[index]['phone'] : '',
    );"""
dialog_new = """  Future<void> _showContactDialog({required bool isEdit, String? id, String? initialName, String? initialPhone}) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController(text: initialPhone ?? '');"""
content = content.replace(dialog_old, dialog_new)

# Fix _showContactDialog save logic
save_old = """                if (formKey.currentState!.validate()) {
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
                }"""
save_new = """                if (formKey.currentState!.validate()) {
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
                }"""
content = content.replace(save_old, save_new)

# Update _editContact
edit_old = """  void _editContact(int index) {
    _showContactDialog(isEdit: true, index: index);
  }"""
edit_new = """  void _editContact(String id, String name, String phone) {
    _showContactDialog(isEdit: true, id: id, initialName: name, initialPhone: phone);
  }"""
content = content.replace(edit_old, edit_new)

# Update build method to watch provider
build_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
build_new = """  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(trustedContactsProvider);
    
    return Scaffold("""
content = content.replace(build_old, build_new)

# Replace LayoutBuilder contents
layout_old = """          builder: (context, constraints) {
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
          },"""
layout_new = """          builder: (context, constraints) {
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
          },"""
content = content.replace(layout_old, layout_new)

with open('lib/features/return_signal/presentation/screens/trusted_contacts_screen.dart', 'w') as f:
    f.write(content)
