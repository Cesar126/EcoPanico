import 'dart:async';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'mock_auth_repository.dart';

class MockChatRepository implements ChatRepository {
  static final List<MessageEntity> _mockMessages = [
    MessageEntity(
      id: 'msg_1',
      senderId: 'vecino_1',
      senderName: 'Juan Pérez',
      messageText: 'Vecinos, acabo de ver un vehículo gris rondando la calle principal con actitud sospechosa.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    MessageEntity(
      id: 'msg_2',
      senderId: 'vecino_2',
      senderName: 'María Augusta Rodriguez',
      messageText: 'Sí, Juan. También lo vi por acá, iba despacio sin luces.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    MessageEntity(
      id: 'msg_3',
      senderId: 'vecino_1',
      senderName: 'Juan Pérez',
      messageText: 'Comparto mi ubicación para estar atentos.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      latitude: -2.1432,
      longitude: -79.9015,
    ),
    MessageEntity(
      id: 'msg_4',
      senderId: 'admin_123',
      senderName: 'Administrador Los Ceibos',
      messageText: 'Enterado vecinos, ya di aviso a la patrulla comunitaria para que realice rondas.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    )
  ];

  static final StreamController<List<MessageEntity>> _chatController =
      StreamController<List<MessageEntity>>.broadcast();

  MockChatRepository() {
    _getRelativeMessages().then((list) => _chatController.add(list));
  }

  Future<List<MessageEntity>> _getRelativeMessages() async {
    final user = await MockAuthRepository().getCurrentUser();
    // Default fallback coordinates if no user is found
    final double baseLat = user?.latitude ?? -2.1432;
    final double baseLng = user?.longitude ?? -79.9015;

    return _mockMessages.map((msg) {
      if (msg.latitude == null || msg.longitude == null) {
        double offsetLat = 0.0;
        double offsetLng = 0.0;
        if (msg.id == 'msg_1') {
          offsetLat = 0.0003;
          offsetLng = -0.0002;
        } else if (msg.id == 'msg_2') {
          offsetLat = -0.0002;
          offsetLng = 0.0004;
        } else if (msg.id == 'msg_4') {
          offsetLat = 0.0001;
          offsetLng = 0.0001;
        }
        return msg.copyWith(
          latitude: baseLat + offsetLat,
          longitude: baseLng + offsetLng,
        );
      } else {
        if (msg.id == 'msg_3') {
          return msg.copyWith(
            latitude: baseLat,
            longitude: baseLng,
          );
        }
        return msg;
      }
    }).toList();
  }

  @override
  Stream<List<MessageEntity>> getMessages() {
    final controller = StreamController<List<MessageEntity>>();
    
    _getRelativeMessages().then((list) {
      if (!controller.isClosed) {
        controller.add(list);
      }
    });

    final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!controller.isClosed) {
        final list = await _getRelativeMessages();
        controller.add(list);
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMessages.add(message);
    
    final relativeList = await _getRelativeMessages();
    _chatController.add(relativeList);

    // Simulate community responses to user messages
    if (message.senderId.startsWith('new_user_') || message.senderId == 'vecino_123' || message.senderId.startsWith('vecino_')) {
      Timer(const Duration(seconds: 4), () async {
        final user = await MockAuthRepository().getCurrentUser();
        final double baseLat = user?.latitude ?? -2.1432;
        final double baseLng = user?.longitude ?? -79.9015;

        final reply = MessageEntity(
          id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'vecino_4',
          senderName: 'Ana Luisa Beltrán',
          messageText: '¡Copiado! Estoy alerta desde mi ventana.',
          timestamp: DateTime.now(),
          latitude: baseLat + 0.0005, // within 200m
          longitude: baseLng - 0.0005,
        );
        _mockMessages.add(reply);
        final list = await _getRelativeMessages();
        _chatController.add(list);
      });
    }
  }

  @override
  Future<String> uploadMedia(String filePath, String folderName) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return filePath;
  }
}
