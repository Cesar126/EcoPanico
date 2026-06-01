import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';
import '../models/alert_model.dart';

class FirebaseAlertRepository implements AlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> emitAlert(AlertEntity alert) async {
    final model = AlertModel.fromEntity(alert);
    // Emit alert into the 'alertas' collection
    await _firestore.collection('alertas').doc(alert.id).set(model.toMap());
  }

  @override
  Future<void> updateAlertStatus(String alertId, String newStatus, String? resolvedBy) async {
    await _firestore.collection('alertas').doc(alertId).update({
      'status': newStatus,
      'resolvedBy': resolvedBy,
    });
  }

  @override
  Stream<List<AlertEntity>> getActiveAlerts() {
    return _firestore
        .collection('alertas')
        .where('status', whereIn: ['activa', 'en_atencion'])
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort by timestamp descending
          alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return alerts;
        });
  }

  @override
  Stream<List<AlertEntity>> getAlertsHistory() {
    return _firestore
        .collection('alertas')
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
              .toList();
          alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return alerts;
        });
  }

  @override
  Future<void> updateEmergencyLocation(String alertId, double latitude, double longitude) async {
    await _firestore.collection('alertas').doc(alertId).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  @override
  Stream<AlertEntity?> listenToAlert(String alertId) {
    return _firestore
        .collection('alertas')
        .doc(alertId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return AlertModel.fromMap(doc.data()!, doc.id);
          }
          return null;
        });
  }
}
