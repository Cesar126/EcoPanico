import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static final StreamController<UserEntity?> _authController = StreamController<UserEntity?>.broadcast();
  static UserEntity? _currentUser;
  static bool _isVerified = true;

  MockAuthRepository() {
    // If not set, default to null (logged out)
    _authController.add(_currentUser);
  }

  @override
  Stream<UserEntity?> get onAuthStateChanged => _authController.stream;

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network latency

    if (email == 'admin@ecopanico.com') {
      _currentUser = const UserEntity(
        id: 'admin_123',
        fullName: 'Administrador Los Ceibos',
        phone: '+593 99 999 9999',
        address: 'Calle de la Administración #5',
        houseNumber: 'Vivienda 00',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        role: 'admin',
        isConnected: true,
      );
    } else {
      // Default neighbor user
      _currentUser = UserEntity(
        id: 'vecino_123',
        fullName: 'Juan Pérez',
        phone: '+593 98 765 4321',
        address: 'Av. Las Palmas y Los Cedros',
        houseNumber: 'Vivienda 42',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&q=80',
        role: 'vecino',
        isConnected: true,
      );
    }
    _isVerified = true;
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<UserEntity?> register(UserEntity user, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    _currentUser = user.copyWith(id: 'new_user_${DateTime.now().millisecondsSinceEpoch}');
    _isVerified = false; // Registration requires verification
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> isEmailVerified() async {
    return _isVerified;
  }

  @override
  Future<void> reloadUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isVerified = true; // Simulate verified on reload
    _authController.add(_currentUser);
  }
}
