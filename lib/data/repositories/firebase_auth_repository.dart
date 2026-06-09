import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../core/config/app_config.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserEntity? _mapFirebaseUser(fb.User? user) {
    if (user == null) return null;
    
    // We create a temporary entity. The actual profile details will be fetched from Firestore
    return UserEntity(
      id: user.uid,
      fullName: user.displayName ?? '',
      phone: user.phoneNumber ?? '',
      address: '',
      houseNumber: '',
      photoUrl: user.photoURL,
      role: 'vecino',
    );
  }

  @override
  Stream<UserEntity?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      return await getCurrentUser();
    });
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;

    try {
      final doc = await _firestore.collection('usuarios').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      // In case Firestore retrieval fails, fall back to basic firebase user info
    }
    return _mapFirebaseUser(fbUser);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user == null) return null;
    return await getCurrentUser();
  }

  @override
  Future<UserEntity?> register(UserEntity user, String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) return null;

    // Update display name
    await fbUser.updateDisplayName(user.fullName);

    // Save profile to firestore
    final userModel = UserModel.fromEntity(user.copyWith(id: fbUser.uid));
    await _firestore.collection('usuarios').doc(fbUser.uid).set(userModel.toMap());

    // Send email verification safely if required
    if (AppConfig.requireEmailVerification) {
      try {
        await fbUser.sendEmailVerification();
      } catch (_) {
        // Safe fallback
      }
    }

    return userModel;
  }

  @override
  Future<void> logout() async {
    // Set connection status to offline before logging out
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      try {
        await _firestore.collection('usuarios').doc(uid).update({'isConnected': false});
      } catch (_) {}
    }
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return _firebaseAuth.currentUser?.emailVerified ?? false;
    }
    return false;
  }

  @override
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }
}
