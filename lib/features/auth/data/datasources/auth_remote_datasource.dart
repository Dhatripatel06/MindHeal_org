import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../shared/models/app_user.dart';

abstract class AuthRemoteDataSource {
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
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
  Future<AppUser?> getUserData();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuthService _authService;

  AuthRemoteDataSourceImpl({
    required FirebaseAuthService authService,
  }) : _authService = authService;

  @override
  Stream<UserEntity?> get authStateChanges => _authService.authStateChanges
      .map((user) => user != null ? _userToEntity(user) : null);

  @override
  UserEntity? get currentUser {
    final user = _authService.currentUser;
    return user != null ? _userToEntity(user) : null;
  }

  @override
  bool get isAnonymous => _authService.isAnonymous;

  @override
  Future<UserEntity?> signInWithEmail(String email, String password) async {
    final user = await _authService.signInWithEmailAndPassword(email, password);
    return user != null ? _userToEntity(user) : null;
  }

  @override
  Future<UserEntity?> createUserWithEmail(String email, String password, String displayName) async {
    final user = await _authService.createUserWithEmailAndPassword(email, password);
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.reload();
      return _userToEntity(user);
    }
    return null;
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    return user != null ? _userToEntity(user) : null;
  }

  @override
  Future<UserEntity?> signInAnonymously() async {
    final user = await _authService.signInAnonymously();
    return user != null ? _userToEntity(user) : null;
  }

  @override
  Future<UserEntity?> linkAnonymousWithEmail(String email, String password, String displayName) async {
    final user = await _authService.linkAnonymousWithEmail(email, password, displayName);
    if (user != null) {
      return _userToEntity(user);
    }
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
  }

  @override
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    return _authService.isEmailVerified;
  }

  @override
  Future<void> reloadUser() async {
    await _authService.reloadUser();
  }

  @override
  Future<AppUser?> getUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        return AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          emailVerified: user.emailVerified,
          isAnonymous: user.isAnonymous,
          createdAt: user.metadata.creationTime,
          lastSignInTime: user.metadata.lastSignInTime,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  UserEntity _userToEntity(User user) {
    return UserEntity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
    );
  }
}
