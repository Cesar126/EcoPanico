import '../entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<MessageEntity>> getMessages();
  
  Future<void> sendMessage(MessageEntity message);
  
  Future<String> uploadMedia(String filePath, String folderName);
}
