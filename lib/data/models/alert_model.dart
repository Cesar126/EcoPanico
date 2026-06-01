import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alert_entity.dart';

class AlertModel extends AlertEntity {
  const AlertModel({
    required super.id,
    required super.neighborId,
    required super.neighborName,
    required super.neighborPhone,
    required super.neighborHouseNumber,
    required super.type,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.level,
    required super.status,
    super.resolvedBy,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedTime;
    final ts = map['timestamp'];
    if (ts is Timestamp) {
      parsedTime = ts.toDate();
    } else if (ts is String) {
      parsedTime = DateTime.parse(ts);
    } else if (ts is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      parsedTime = DateTime.now();
    }

    return AlertModel(
      id: id,
      neighborId: map['neighborId'] ?? '',
      neighborName: map['neighborName'] ?? '',
      neighborPhone: map['neighborPhone'] ?? '',
      neighborHouseNumber: map['neighborHouseNumber'] ?? '',
      type: map['type'] ?? 'sospechoso',
      timestamp: parsedTime,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      level: map['level'] ?? 'medium',
      status: map['status'] ?? 'activa',
      resolvedBy: map['resolvedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'neighborId': neighborId,
      'neighborName': neighborName,
      'neighborPhone': neighborPhone,
      'neighborHouseNumber': neighborHouseNumber,
      'type': type,
      'timestamp': timestamp.toIso8601String(), // Firebase will interpret it or we can pass actual DateTime in firebase client
      'latitude': latitude,
      'longitude': longitude,
      'level': level,
      'status': status,
      'resolvedBy': resolvedBy,
    };
  }

  factory AlertModel.fromEntity(AlertEntity entity) {
    return AlertModel(
      id: entity.id,
      neighborId: entity.neighborId,
      neighborName: entity.neighborName,
      neighborPhone: entity.neighborPhone,
      neighborHouseNumber: entity.neighborHouseNumber,
      type: entity.type,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      level: entity.level,
      status: entity.status,
      resolvedBy: entity.resolvedBy,
    );
  }
}
