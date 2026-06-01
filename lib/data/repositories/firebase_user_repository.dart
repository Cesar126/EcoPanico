import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserEntity?> getUserById(String id) async {
    final doc = await _firestore.collection('usuarios').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<void> saveUserProfile(UserEntity user) async {
    final model = UserModel.fromEntity(user);
    await _firestore.collection('usuarios').doc(user.id).set(
          model.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<UserEntity>> getAllUsers() {
    return _firestore.collection('usuarios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> deleteUser(String id) async {
    await _firestore.collection('usuarios').doc(id).delete();
  }

  @override
  Future<void> updateUserRole(String id, String role) async {
    await _firestore.collection('usuarios').doc(id).update({'role': role});
  }

  @override
  Stream<int> getOnlineNeighborsCount() {
    return _firestore
        .collection('usuarios')
        .where('isConnected', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> updateConnectionStatus(String id, bool isConnected) async {
    await _firestore.collection('usuarios').doc(id).update({'isConnected': isConnected});
  }
}
