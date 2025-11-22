import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<UserEntity?> call() async {
    return await repository.signInWithGoogle();
  }
}
