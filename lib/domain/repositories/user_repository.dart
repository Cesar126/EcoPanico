import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<UserEntity?> getUserById(String id);
  
  Future<void> saveUserProfile(UserEntity user);
  
  Stream<List<UserEntity>> getAllUsers();
  
  Future<void> deleteUser(String id);
  
  Future<void> updateUserRole(String id, String role);
  
  Stream<int> getOnlineNeighborsCount();
  
  Future<void> updateConnectionStatus(String id, bool isConnected);
}
