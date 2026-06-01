import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get onAuthStateChanged;
  
  Future<UserEntity?> getCurrentUser();
  
  Future<UserEntity?> login(String email, String password);
  
  Future<UserEntity?> register(UserEntity user, String email, String password);
  
  Future<void> logout();
  
  Future<void> sendPasswordResetEmail(String email);
  
  Future<bool> isEmailVerified();
  
  Future<void> reloadUser();
}
