import '../../../../shared/models/app_user.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  emailNotVerified,
  error,
}

class AuthState {
  final AuthStatus status;
  final dynamic user;
  final AppUser? userData;
  final bool isLoading;
  final String errorMessage;
  final String successMessage;
  final bool isAnonymous;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.userData,
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
    this.isAnonymous = false,
  });

  bool get hasError => errorMessage.isNotEmpty;
  bool get hasSuccess => successMessage.isNotEmpty;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isEmailNotVerified => status == AuthStatus.emailNotVerified;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  AuthState copyWith({
    AuthStatus? status,
    dynamic user,
    AppUser? userData,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isAnonymous,
    bool? clearError,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError == true ? '' : (errorMessage ?? this.errorMessage),
      successMessage: clearError == true ? '' : (successMessage ?? this.successMessage),
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
