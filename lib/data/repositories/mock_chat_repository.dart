import 'dart:async';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

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
    _chatController.add(List.from(_mockMessages));
  }

  @override
  Stream<List<MessageEntity>> getMessages() {
    final controller = StreamController<List<MessageEntity>>();
    controller.add(List.from(_mockMessages));

    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!controller.isClosed) {
        controller.add(List.from(_mockMessages));
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMessages.add(message);
    _chatController.add(List.from(_mockMessages));

    // Simulate community responses to user messages
    if (message.senderId == 'vecino_123') { // User is logged in as vecino_123
      Timer(const Duration(seconds: 4), () {
        final reply = MessageEntity(
          id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'vecino_4',
          senderName: 'Ana Luisa Beltrán',
          messageText: '¡Copiado! Estoy alerta desde mi ventana.',
          timestamp: DateTime.now(),
        );
        _mockMessages.add(reply);
        _chatController.add(List.from(_mockMessages));
      });
    }
  }

  @override
  Future<String> uploadMedia(String filePath, String folderName) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return filePath;
  }
}
