import re

with open('lib/features/return_signal/presentation/screens/manual_checkin_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trusted_contacts_provider.dart';"""
content = content.replace("import 'package:flutter/material.dart';", imports)

# Convert to ConsumerStatefulWidget
content = content.replace("class ManualCheckinScreen extends StatefulWidget", "class ManualCheckinScreen extends ConsumerStatefulWidget")
content = content.replace("State<ManualCheckinScreen> createState() => _ManualCheckinScreenState();", "ConsumerState<ManualCheckinScreen> createState() => _ManualCheckinScreenState();")
content = content.replace("class _ManualCheckinScreenState extends State<ManualCheckinScreen> {", "class _ManualCheckinScreenState extends ConsumerState<ManualCheckinScreen> {")

# Remove dummy contacts
dummy_pattern = re.compile(r"  final List<String> _dummyContacts = \[.*?\];\n", re.DOTALL)
content = dummy_pattern.sub("", content)

# Change type of _selectedContact to handle dynamic items. Actually, the type of value in DropdownButtonFormField is what we define.
# If we define it as TrustedContact, we need to match equality. 
# It's easier to keep _selectedContact as a String (the contact ID) and look it up if needed.
# Since initial implementation was String?, I'll leave it as String? for the ID.

# Update build to watch provider
build_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
build_new = """  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(trustedContactsProvider);
    
    return Scaffold("""
content = content.replace(build_old, build_new)

# Update the DropdownButtonFormField
dropdown_old = """                        DropdownButtonFormField<String>(
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
                        ),"""
dropdown_new = """                        contactsAsync.when(
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
                              value: _selectedContact,
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
                        ),"""
content = content.replace(dropdown_old, dropdown_new)

with open('lib/features/return_signal/presentation/screens/manual_checkin_screen.dart', 'w') as f:
    f.write(content)
