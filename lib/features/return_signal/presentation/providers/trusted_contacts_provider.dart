import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trusted_contact.dart';
import '../../domain/repositories/trusted_contact_repository.dart';
import '../../data/repositories/fake_contacts_repository_impl.dart';

// Provider for the repository
final trustedContactRepositoryProvider = Provider<TrustedContactRepository>((ref) {
  return FakeContactsRepositoryImpl();
});

// AsyncNotifier to manage contacts list state
final trustedContactsProvider = AsyncNotifierProvider<TrustedContactsNotifier, List<TrustedContact>>(() {
  return TrustedContactsNotifier();
});

class TrustedContactsNotifier extends AsyncNotifier<List<TrustedContact>> {
  @override
  FutureOr<List<TrustedContact>> build() async {
    // In a real app, this uid would come from auth provider
    return ref.read(trustedContactRepositoryProvider).getContacts('mock_uid');
  }

  Future<void> addContact(String name, String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trustedContactRepositoryProvider);
      final newContact = TrustedContact(id: '', name: name, phoneNumber: phone);
      await repository.addContact('mock_uid', newContact);
      return repository.getContacts('mock_uid');
    });
  }

  Future<void> updateContact(String id, String name, String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trustedContactRepositoryProvider);
      final contact = TrustedContact(id: id, name: name, phoneNumber: phone);
      await repository.updateContact('mock_uid', contact);
      return repository.getContacts('mock_uid');
    });
  }

  Future<void> deleteContact(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(trustedContactRepositoryProvider);
      await repository.deleteContact('mock_uid', id);
      return repository.getContacts('mock_uid');
    });
  }
}
