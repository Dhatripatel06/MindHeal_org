import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../shared/models/app_user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Stream<UserEntity?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  UserEntity? get currentUser => _remoteDataSource.currentUser;

  @override
  bool get isAnonymous => _remoteDataSource.isAnonymous;

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    return await _remoteDataSource.signInWithEmail(email, password);
  }

  @override
  Future<UserEntity?> createUserWithEmail(String email, String password, String displayName) async {
    return await _remoteDataSource.createUserWithEmail(email, password, displayName);
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    return await _remoteDataSource.signInWithGoogle();
  }

  @override
  Future<UserEntity?> signInAnonymously() async {
    return await _remoteDataSource.signInAnonymously();
  }

  @override
  Future<UserEntity?> linkAnonymousWithEmail(String email, String password, String displayName) async {
    return await _remoteDataSource.linkAnonymousWithEmail(email, password, displayName);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteAccount();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _remoteDataSource.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    return await _remoteDataSource.isEmailVerified();
  }

  @override
  Future<void> reloadUser() async {
    await _remoteDataSource.reloadUser();
  }

  @override
  Future<AppUser?> getUserData() async {
    return await _remoteDataSource.getUserData();
  }

  @override
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    // Implementation for updating user profile
    // This would typically involve updating Firestore document
    // For now, we'll update the Firebase Auth profile
    final user = currentUser;
    if (user != null) {
      // Update Firebase Auth profile
      // Note: You'd need to implement this in FirebaseAuthService
    }
  }
}
