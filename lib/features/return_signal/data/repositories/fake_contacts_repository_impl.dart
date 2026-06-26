import '../../domain/entities/trusted_contact.dart';
import '../../domain/repositories/trusted_contact_repository.dart';

class FakeContactsRepositoryImpl implements TrustedContactRepository {
  final List<TrustedContact> _contacts = [
    const TrustedContact(id: '1', name: 'Alice', phoneNumber: '+1 555-0101'),
    const TrustedContact(id: '2', name: 'Bob', phoneNumber: '+1 555-0102'),
    const TrustedContact(id: '3', name: 'Charlie', phoneNumber: '+1 555-0103'),
  ];

  @override
  Future<List<TrustedContact>> getContacts(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_contacts);
  }

  @override
  Future<void> addContact(String uid, TrustedContact contact) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newContact = TrustedContact(
      id: contact.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : contact.id,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
    );
    _contacts.add(newContact);
  }

  @override
  Future<void> updateContact(String uid, TrustedContact contact) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
    }
  }

  @override
  Future<void> deleteContact(String uid, String contactId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contacts.removeWhere((c) => c.id == contactId);
  }
}
