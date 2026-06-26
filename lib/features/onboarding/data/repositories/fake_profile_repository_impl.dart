import 'dart:async';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FakeProfileRepositoryImpl implements ProfileRepository {
  final Map<String, UserProfile> _inMemoryCache = {};

  @override
  Future<UserProfile?> getProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate network
    return _inMemoryCache[uid];
  }

  @override
  Future<void> saveProfile(String uid, UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    _inMemoryCache[uid] = profile;
  }
}
