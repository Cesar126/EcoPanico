import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.messageText,
    required super.timestamp,
    super.photoUrl,
    super.videoUrl,
    super.latitude,
    super.longitude,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
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

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      messageText: map['messageText'] ?? '',
      timestamp: parsedTime,
      photoUrl: map['photoUrl'],
      videoUrl: map['videoUrl'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'messageText': messageText,
      'timestamp': timestamp.toIso8601String(),
      'photoUrl': photoUrl,
      'videoUrl': videoUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      messageText: entity.messageText,
      timestamp: entity.timestamp,
      photoUrl: entity.photoUrl,
      videoUrl: entity.videoUrl,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
