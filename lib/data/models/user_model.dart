import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.address,
    required super.houseNumber,
    super.photoUrl,
    required super.role,
    super.isConnected,
    super.latitude,
    super.longitude,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      houseNumber: map['houseNumber'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'vecino',
      isConnected: map['isConnected'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'houseNumber': houseNumber,
      'photoUrl': photoUrl,
      'role': role,
      'isConnected': isConnected,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      fullName: entity.fullName,
      phone: entity.phone,
      address: entity.address,
      houseNumber: entity.houseNumber,
      photoUrl: entity.photoUrl,
      role: entity.role,
      isConnected: entity.isConnected,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
