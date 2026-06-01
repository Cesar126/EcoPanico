class UserEntity {
  final String id;
  final String fullName;
  final String phone;
  final String address;
  final String houseNumber;
  final String? photoUrl;
  final String role; // 'vecino' or 'admin'
  final bool isConnected;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.houseNumber,
    this.photoUrl,
    required this.role,
    this.isConnected = true,
  });

  bool get isAdmin => role == 'admin';

  UserEntity copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? address,
    String? houseNumber,
    String? photoUrl,
    String? role,
    bool? isConnected,
  }) {
    return UserEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      houseNumber: houseNumber ?? this.houseNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
