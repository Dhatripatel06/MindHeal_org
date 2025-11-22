import '/features/auth/domain/entities/user_entity.dart';

class UserModel {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;

  const UserModel({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.createdAt,
    this.lastSignInTime,
  });

  // Factory constructor to create UserModel from JSON/Map (Firebase/API response)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
      emailVerified: map['emailVerified'] as bool? ?? false,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString()) 
          : null,
      lastSignInTime: map['lastSignInTime'] != null 
          ? DateTime.tryParse(map['lastSignInTime'].toString()) 
          : null,
    );
  }

  // Factory constructor to create from Firebase User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser?.uid,
      email: firebaseUser?.email,
      displayName: firebaseUser?.displayName,
      photoURL: firebaseUser?.photoURL,
      emailVerified: firebaseUser?.emailVerified ?? false,
      isAnonymous: firebaseUser?.isAnonymous ?? false,
      createdAt: firebaseUser?.metadata?.creationTime,
      lastSignInTime: firebaseUser?.metadata?.lastSignInTime,
    );
  }

  // Convert UserModel to Map (for saving to Firestore/local DB)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
    };
  }

  // Convert UserModel to UserEntity (for domain layer)
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      emailVerified: emailVerified,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
      lastSignInTime: lastSignInTime,
    );
  }

  // Create UserModel from UserEntity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      photoURL: entity.photoURL,
      emailVerified: entity.emailVerified,
      isAnonymous: entity.isAnonymous,
      createdAt: entity.createdAt,
      lastSignInTime: entity.lastSignInTime,
    );
  }

  // Copy with method for updating user data
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastSignInTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
    );
  }

  // Helper getter for metadata (similar to Firebase User)
  UserMetadata get metadata => UserMetadata(
    creationTime: createdAt,
    lastSignInTime: lastSignInTime,
  );

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, emailVerified: $emailVerified, isAnonymous: $isAnonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.emailVerified == emailVerified &&
        other.isAnonymous == isAnonymous &&
        other.createdAt == createdAt &&
        other.lastSignInTime == lastSignInTime;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoURL.hashCode ^
        emailVerified.hashCode ^
        isAnonymous.hashCode ^
        createdAt.hashCode ^
        lastSignInTime.hashCode;
  }
}

// Helper class for user metadata (matching your UserEntity structure)
class UserMetadata {
  final DateTime? creationTime;
  final DateTime? lastSignInTime;

  const UserMetadata({
    this.creationTime,
    this.lastSignInTime,
  });
}
