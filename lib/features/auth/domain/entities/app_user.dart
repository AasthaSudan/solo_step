class AppUser {
  final String uid;
  final bool isAnonymous;
  final String? email;

  const AppUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          isAnonymous == other.isAnonymous &&
          email == other.email;

  @override
  int get hashCode => uid.hashCode ^ isAnonymous.hashCode ^ email.hashCode;

  @override
  String toString() => 'AppUser(uid: $uid, isAnonymous: $isAnonymous, email: $email)';
}
