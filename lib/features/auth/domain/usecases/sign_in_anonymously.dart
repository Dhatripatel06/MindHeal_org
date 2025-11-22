import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class SignInAnonymously {
  final AuthRepository repository;

  SignInAnonymously(this.repository);

  Future<UserEntity?> call() async {
    return await repository.signInAnonymously();
  }
}
