import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FirestoreProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreProfileRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting profile for $uid: $e');
    }
    return null;
  }

  @override
  Future<void> saveProfile(String uid, UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(uid).set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving profile for $uid: $e');
      rethrow;
    }
  }
}
