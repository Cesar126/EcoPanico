import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<UserEntity?> call(String email, String password) {
    return repository.login(email, password);
  }
}

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity?> call(UserEntity user, String email, String password) {
    return repository.register(user, email, password);
  }
}

class LogoutUseCase {
  final AuthRepository repository;
  LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);

  Future<void> call(String email) {
    return repository.sendPasswordResetEmail(email);
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }
}

class CheckEmailVerificationUseCase {
  final AuthRepository repository;
  CheckEmailVerificationUseCase(this.repository);

  Future<bool> call() {
    return repository.isEmailVerified();
  }
}

class ReloadUserUseCase {
  final AuthRepository repository;
  ReloadUserUseCase(this.repository);

  Future<void> call() {
    return repository.reloadUser();
  }
}
