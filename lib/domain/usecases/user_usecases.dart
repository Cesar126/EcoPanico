import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetUserByIdUseCase {
  final UserRepository repository;
  GetUserByIdUseCase(this.repository);

  Future<UserEntity?> call(String id) {
    return repository.getUserById(id);
  }
}

class SaveUserProfileUseCase {
  final UserRepository repository;
  SaveUserProfileUseCase(this.repository);

  Future<void> call(UserEntity user) {
    return repository.saveUserProfile(user);
  }
}

class GetAllUsersUseCase {
  final UserRepository repository;
  GetAllUsersUseCase(this.repository);

  Stream<List<UserEntity>> call() {
    return repository.getAllUsers();
  }
}

class DeleteUserUseCase {
  final UserRepository repository;
  DeleteUserUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteUser(id);
  }
}

class UpdateUserRoleUseCase {
  final UserRepository repository;
  UpdateUserRoleUseCase(this.repository);

  Future<void> call(String id, String role) {
    return repository.updateUserRole(id, role);
  }
}

class GetOnlineNeighborsCountUseCase {
  final UserRepository repository;
  GetOnlineNeighborsCountUseCase(this.repository);

  Stream<int> call() {
    return repository.getOnlineNeighborsCount();
  }
}

class UpdateConnectionStatusUseCase {
  final UserRepository repository;
  UpdateConnectionStatusUseCase(this.repository);

  Future<void> call(String id, bool isConnected) {
    return repository.updateConnectionStatus(id, isConnected);
  }
}
