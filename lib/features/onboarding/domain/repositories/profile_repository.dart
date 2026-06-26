import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> getProfile(String uid);
  Future<void> saveProfile(String uid, UserProfile profile);
}
