import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/firestore_profile_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirestoreProfileRepositoryImpl();
});

// A FutureProvider that fetches the current user's profile
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    return null; // Not logged in
  }
  
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getProfile(authState.uid);
});
