import '../entities/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> signOut();
}
