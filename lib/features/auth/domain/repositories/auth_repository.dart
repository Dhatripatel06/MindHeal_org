import '../entities/user_entity.dart';
import '../../../../shared/models/app_user.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;
  bool get isAnonymous;

  Future<UserEntity?> signInWithEmail(String email, String password);
  Future<UserEntity?> createUserWithEmail(String email, String password, String displayName);
  Future<UserEntity?> signInWithGoogle();
  Future<UserEntity?> signInAnonymously();
  Future<UserEntity?> linkAnonymousWithEmail(String email, String password, String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
  
  Future<AppUser?> getUserData();
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  });

  // Email Verification Methods
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
}
