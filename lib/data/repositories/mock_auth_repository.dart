import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'mock_user_repository.dart';

class MockUserCredentials {
  final UserEntity user;
  final String password;
  const MockUserCredentials({required this.user, required this.password});
}

class MockAuthRepository implements AuthRepository {
  static final StreamController<UserEntity?> _authController = StreamController<UserEntity?>.broadcast();
  static UserEntity? _currentUser;
  static bool _isVerified = true;

  // In-memory credentials map to simulate registered accounts
  static final Map<String, MockUserCredentials> _registeredUsers = {
    'admin@ecopanico.com': const MockUserCredentials(
      user: UserEntity(
        id: 'admin_123',
        fullName: 'Administrador Los Ceibos',
        phone: '+593 99 999 9999',
        address: 'Calle de la Administración #5',
        houseNumber: 'Vivienda 00',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        role: 'admin',
        isConnected: true,
      ),
      password: 'password123',
    ),
    'vecino@ecopanico.com': const MockUserCredentials(
      user: UserEntity(
        id: 'vecino_123',
        fullName: 'Juan Pérez',
        phone: '+593 98 765 4321',
        address: 'Av. Las Palmas y Los Cedros',
        houseNumber: 'Vivienda 42',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&q=80',
        role: 'vecino',
        isConnected: true,
      ),
      password: 'password123',
    ),
  };

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

    final normalizedEmail = email.toLowerCase().trim();
    if (_registeredUsers.containsKey(normalizedEmail)) {
      final creds = _registeredUsers[normalizedEmail]!;
      if (creds.password == password) {
        _currentUser = creds.user;
        _isVerified = true; // Mark as verified upon successful login
        _authController.add(_currentUser);
        return _currentUser;
      } else {
        throw Exception('Contraseña incorrecta');
      }
    } else {
      // Get real GPS position if possible for fallback user
      double? lat;
      double? lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        lat = -2.1432;
        lng = -79.9015;
      }

      // Generate a dynamic name from email to avoid hardcoding Juan Pérez
      final emailName = normalizedEmail.split('@').first;
      final capitalizedName = emailName.isNotEmpty
          ? emailName[0].toUpperCase() + emailName.substring(1)
          : 'Vecino';

      final newUser = UserEntity(
        id: 'vecino_${DateTime.now().millisecondsSinceEpoch}',
        fullName: capitalizedName,
        phone: '+593 98 765 4321',
        address: 'Av. Las Palmas y Los Cedros',
        houseNumber: 'Vivienda ${10 + (DateTime.now().second % 90)}',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&q=80',
        role: 'vecino',
        isConnected: true,
        latitude: lat,
        longitude: lng,
      );
      _registeredUsers[normalizedEmail] = MockUserCredentials(
        user: newUser,
        password: password,
      );
      // Register in list of users
      MockUserRepository.addMockUser(newUser);
      _currentUser = newUser;
      _isVerified = true;
      _authController.add(_currentUser);
      return _currentUser;
    }
  }

  @override
  Future<UserEntity?> register(UserEntity user, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final registeredUser = user.copyWith(
      id: 'new_user_${DateTime.now().millisecondsSinceEpoch}',
    );
    _registeredUsers[email.toLowerCase().trim()] = MockUserCredentials(
      user: registeredUser,
      password: password,
    );
    // Add to user repository list so it shows in dashboard
    MockUserRepository.addMockUser(registeredUser);
    
    _currentUser = registeredUser;
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
