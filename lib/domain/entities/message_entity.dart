class MessageEntity {
  final String id;
  final String senderId;
  final String senderName;
  final String messageText;
  final DateTime timestamp;
  final String? photoUrl;
  final String? videoUrl;
  final double? latitude;
  final double? longitude;

  const MessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.messageText,
    required this.timestamp,
    this.photoUrl,
    this.videoUrl,
    this.latitude,
    this.longitude,
  });

  bool get isLocationShare => latitude != null && longitude != null;
  bool get isMediaShare => photoUrl != null || videoUrl != null;

  MessageEntity copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? messageText,
    DateTime? timestamp,
    String? photoUrl,
    String? videoUrl,
    double? latitude,
    double? longitude,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      messageText: messageText ?? this.messageText,
      timestamp: timestamp ?? this.timestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
