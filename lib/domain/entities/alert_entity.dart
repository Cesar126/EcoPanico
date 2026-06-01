class AlertEntity {
  final String id;
  final String neighborId;
  final String neighborName;
  final String neighborPhone;
  final String neighborHouseNumber;
  final String type; // 'sospechoso', 'robo', 'shake_emergencia'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String level; // 'medium', 'critical'
  final String status; // 'activa', 'en_atencion', 'resuelta'
  final String? resolvedBy;

  const AlertEntity({
    required this.id,
    required this.neighborId,
    required this.neighborName,
    required this.neighborPhone,
    required this.neighborHouseNumber,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.level,
    required this.status,
    this.resolvedBy,
  });

  bool get isActive => status == 'activa';
  bool get isCritical => level == 'critical';

  AlertEntity copyWith({
    String? id,
    String? neighborId,
    String? neighborName,
    String? neighborPhone,
    String? neighborHouseNumber,
    String? type,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? level,
    String? status,
    String? resolvedBy,
  }) {
    return AlertEntity(
      id: id ?? this.id,
      neighborId: neighborId ?? this.neighborId,
      neighborName: neighborName ?? this.neighborName,
      neighborPhone: neighborPhone ?? this.neighborPhone,
      neighborHouseNumber: neighborHouseNumber ?? this.neighborHouseNumber,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      level: level ?? this.level,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}
