import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  static final List<UserEntity> _mockUsers = [
    const UserEntity(
      id: 'admin_123',
      fullName: 'Administrador Los Ceibos',
      phone: '+593 99 999 9999',
      address: 'Calle de la Administración #5',
      houseNumber: 'Vivienda 00',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      role: 'admin',
      isConnected: true,
      community: 'Los Ceibos (Sector Central)',
    ),
    const UserEntity(
      id: 'vecino_1',
      fullName: 'Juan Pérez',
      phone: '+593 98 765 4321',
      address: 'Av. Las Palmas y Los Cedros',
      houseNumber: 'Vivienda 42',
      photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&q=80',
      role: 'vecino',
      isConnected: true,
      community: 'Los Ceibos (Sector Central)',
    ),
    const UserEntity(
      id: 'vecino_2',
      fullName: 'María Augusta Rodriguez',
      phone: '+593 98 111 2222',
      address: 'Calle Los Ceibos y Segunda',
      houseNumber: 'Vivienda 15',
      photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80',
      role: 'vecino',
      isConnected: true,
      community: 'Yacucalle',
    ),
    const UserEntity(
      id: 'vecino_3',
      fullName: 'Carlos Andrade',
      phone: '+593 99 555 4444',
      address: 'Pasaje Olmedo y Principal',
      houseNumber: 'Vivienda 28',
      photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
      role: 'vecino',
      isConnected: false,
      community: 'La Florida',
    ),
    const UserEntity(
      id: 'vecino_4',
      fullName: 'Ana Luisa Beltrán',
      phone: '+593 99 888 7777',
      address: 'Calle Quinta y Los Alamos',
      houseNumber: 'Vivienda 104',
      photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80',
      role: 'vecino',
      isConnected: true,
      community: 'Los Ceibos (Sector Polideportivo)',
    ),
  ];

  static void addMockUser(UserEntity user) {
    if (!_mockUsers.any((u) => u.id == user.id)) {
      _mockUsers.add(user);
      _usersController.add(List.from(_mockUsers));
    }
  }

  static final StreamController<List<UserEntity>> _usersController =
      StreamController<List<UserEntity>>.broadcast();

  MockUserRepository() {
    _usersController.add(List.from(_mockUsers));
  }

  @override
  Stream<List<UserEntity>> getAllUsers() {
    // Periodically update to emit list
    final controller = StreamController<List<UserEntity>>();
    controller.add(List.from(_mockUsers));
    
    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!controller.isClosed) {
        controller.add(List.from(_mockUsers));
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUserProfile(UserEntity user) async {
    final idx = _mockUsers.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      _mockUsers[idx] = user;
    } else {
      _mockUsers.add(user);
    }
    _usersController.add(List.from(_mockUsers));
  }

  @override
  Future<void> deleteUser(String id) async {
    _mockUsers.removeWhere((u) => u.id == id);
    _usersController.add(List.from(_mockUsers));
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    final idx = _mockUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _mockUsers[idx] = _mockUsers[idx].copyWith(role: role);
    }
    _usersController.add(List.from(_mockUsers));
  }

  @override
  Stream<int> getOnlineNeighborsCount() {
    // Generates a stream that updates every few seconds to show dynamic online neighbors
    return Stream.periodic(const Duration(seconds: 4), (count) {
      final connectedCount = _mockUsers.where((u) => u.isConnected).length;
      // Add a slight random variation to feel alive, centering around 12-18 connected users
      final liveVariance = (count % 3) - 1; 
      return connectedCount + 12 + liveVariance;
    }).asBroadcastStream();
  }

  @override
  Future<void> updateConnectionStatus(String id, bool isConnected) async {
    final idx = _mockUsers.indexWhere((u) => u.id == id);
    if (idx != -1) {
      _mockUsers[idx] = _mockUsers[idx].copyWith(isConnected: isConnected);
    }
    _usersController.add(List.from(_mockUsers));
  }
}
