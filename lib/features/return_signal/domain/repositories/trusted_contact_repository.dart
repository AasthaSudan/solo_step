import '../entities/trusted_contact.dart';

abstract interface class TrustedContactRepository {
  Future<List<TrustedContact>> getContacts(String uid);
  Future<void> addContact(String uid, TrustedContact contact);
  Future<void> updateContact(String uid, TrustedContact contact);
  Future<void> deleteContact(String uid, String contactId);
}
