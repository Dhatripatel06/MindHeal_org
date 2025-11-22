class UserEntity {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;

  const UserEntity({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.createdAt,
    this.lastSignInTime,
  });

  UserMetadata get metadata => UserMetadata(
    creationTime: createdAt,
    lastSignInTime: lastSignInTime,
  );
}

class UserMetadata {
  final DateTime? creationTime;
  final DateTime? lastSignInTime;

  const UserMetadata({
    this.creationTime,
    this.lastSignInTime,
  });
}
