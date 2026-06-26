import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/fake_auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepositoryImpl();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});
