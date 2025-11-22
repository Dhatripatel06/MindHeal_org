import '../../features/auth/domain/entities/user_entity.dart';

class AppUser {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastSignInTime;
  final UserPreferences? preferences;

  const AppUser({
    this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    this.isAnonymous = false,
    this.createdAt,
    this.lastSignInTime,
    this.preferences,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String) 
          : null,
      lastSignInTime: data['lastSignInTime'] != null 
          ? DateTime.parse(data['lastSignInTime'] as String) 
          : null,
      preferences: data['preferences'] != null
          ? UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'preferences': preferences?.toMap(),
    };
  }

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

  factory AppUser.fromEntity(UserEntity entity) {
    return AppUser(
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

  bool hasFeatureAccess(String feature) {
    return true;
  }

  UserMetadata get metadata => UserMetadata(
    creationTime: createdAt,
    lastSignInTime: lastSignInTime,
  );
}

class UserPreferences {
  final bool notificationsEnabled;

  const UserPreferences({
    this.notificationsEnabled = true,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
    };
  }
}

class UserMetadata {
  final DateTime? creationTime;
  final DateTime? lastSignInTime;

  const UserMetadata({
    this.creationTime,
    this.lastSignInTime,
  });
}
