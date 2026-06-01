import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;
  GetMessagesUseCase(this.repository);

  Stream<List<MessageEntity>> call() {
    return repository.getMessages();
  }
}

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<void> call(MessageEntity message) {
    return repository.sendMessage(message);
  }
}

class UploadMediaUseCase {
  final ChatRepository repository;
  UploadMediaUseCase(this.repository);

  Future<String> call(String filePath, String folderName) {
    return repository.uploadMedia(filePath, folderName);
  }
}
