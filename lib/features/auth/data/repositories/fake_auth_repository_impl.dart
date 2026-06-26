import 'dart:async';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FakeAuthRepositoryImpl implements AuthRepository {
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  FakeAuthRepositoryImpl() {
    // Start logged out
    Future.microtask(() => _authStateController.add(null));
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = const AppUser(
      uid: 'fake_google_uid_123',
      isAnonymous: false,
      email: 'user@example.com',
    );
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signInAnonymously() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = const AppUser(
      uid: 'fake_anon_uid_456',
      isAnonymous: true,
    );
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authStateController.add(null);
  }
}
