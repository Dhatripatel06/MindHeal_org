import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_in_anonymously.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_state.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SignInWithEmail _signInWithEmail;
  final SignInWithGoogle _signInWithGoogle;
  final SignInAnonymously _signInAnonymously;
  final SignOut _signOut;

  StreamSubscription? _authStateSubscription;
  AuthState _state = const AuthState();

  AuthProvider({
    required AuthRepository authRepository,
    required SignInWithEmail signInWithEmail,
    required SignInWithGoogle signInWithGoogle,
    required SignInAnonymously signInAnonymously,
    required SignOut signOut,
  })  : _authRepository = authRepository,
        _signInWithEmail = signInWithEmail,
        _signInWithGoogle = signInWithGoogle,
        _signInAnonymously = signInAnonymously,
        _signOut = signOut {
    _initialize();
  }

  AuthState get state => _state;
  dynamic get user => _state.user;
  bool get isLoading => _state.isLoading;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isEmailNotVerified => _state.isEmailNotVerified;
  String get errorMessage => _state.errorMessage;
  String get successMessage => _state.successMessage;

  void _initialize() {
    _listenToAuthStateChanges();
  }

  void _listenToAuthStateChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) async {
        if (user == null) {
          _updateState(_state.copyWith(
            status: AuthStatus.unauthenticated,
            user: null,
            userData: null,
            isAnonymous: false,
            clearError: true,
          ));
        } else {
          await _loadUserData(user);
        }
      },
      onError: (error) {
        _updateState(_state.copyWith(
          status: AuthStatus.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> _loadUserData(user) async {
    try {
      await _authRepository.reloadUser();

      final userData = await _authRepository.getUserData();
      final isEmailVerified = await _authRepository.isEmailVerified();
      final isAnonymous = _authRepository.isAnonymous;

      AuthStatus status;
      if (isAnonymous) {
        status = AuthStatus.authenticated;
      } else if (!isEmailVerified) {
        status = AuthStatus.emailNotVerified;
      } else {
        status = AuthStatus.authenticated;
      }

      _updateState(_state.copyWith(
        status: status,
        user: user,
        userData: userData,
        isAnonymous: isAnonymous,
        clearError: true,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isAnonymous: _authRepository.isAnonymous,
        errorMessage: 'Failed to load user data: ${e.toString()}',
      ));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      final user = await _signInWithEmail(email, password);

      if (user == null) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Sign in failed',
        ));
        return;
      }

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> createUserWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      final user = await _authRepository.createUserWithEmail(
          email, password, displayName);

      if (user == null) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Account creation failed',
        ));
        return;
      }

      await _authRepository.sendEmailVerification();

      _updateState(_state.copyWith(
        isLoading: false,
        successMessage:
            'Account created! Please check your email for verification.',
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      final user = await _signInWithGoogle();

      if (user == null) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Google sign in was cancelled',
        ));
        return;
      }

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      final user = await _signInAnonymously();

      if (user == null) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Anonymous sign in failed',
        ));
        return;
      }

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> linkAnonymousWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      final user = await _authRepository.linkAnonymousWithEmail(
          email, password, displayName);

      if (user == null) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Account linking failed',
        ));
        return;
      }

      await _authRepository.sendEmailVerification();

      _updateState(_state.copyWith(
        isLoading: false,
        successMessage: 'Account linked! Please verify your email.',
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      await _authRepository.sendPasswordResetEmail(email);

      _updateState(_state.copyWith(
        isLoading: false,
        successMessage: 'Password reset email sent!',
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
      _updateState(_state.copyWith(
        successMessage: 'Verification email sent! Please check your inbox.',
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        errorMessage: 'Failed to send verification email: ${e.toString()}',
      ));
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      await _authRepository.reloadUser();
      final isVerified = await _authRepository.isEmailVerified();

      if (isVerified) {
        await _loadUserData(_state.user);
        _updateState(_state.copyWith(
          isLoading: false,
          successMessage: 'Email verified successfully!',
        ));
      } else {
        _updateState(_state.copyWith(
          isLoading: false,
          status: AuthStatus.emailNotVerified,
          errorMessage: 'Email is not verified yet. Please check your inbox.',
        ));
      }
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to check verification status: ${e.toString()}',
      ));
    }
  }

  Future<void> signOut() async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      await _signOut();

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> deleteAccount() async {
    try {
      _updateState(_state.copyWith(isLoading: true, clearError: true));

      await _authRepository.deleteAccount();

      _updateState(_state.copyWith(isLoading: false));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void clearMessages() {
    _updateState(_state.copyWith(clearError: true));
  }

  bool hasFeatureAccess(String feature) {
    return _state.userData?.hasFeatureAccess(feature) ?? false;
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
