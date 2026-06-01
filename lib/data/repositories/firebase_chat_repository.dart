import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_model.dart';

class FirebaseChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<MessageEntity>> getMessages() {
    return _firestore
        .collection('mensajes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList()
          .reversed // We reverse it because order is descending and we want bottom-up
          .toList();
    });
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    final model = MessageModel.fromEntity(message);
    await _firestore.collection('mensajes').doc(message.id).set(model.toMap());
  }

  @override
  Future<String> uploadMedia(String filePath, String folderName) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child(folderName).child(fileName);
    
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
