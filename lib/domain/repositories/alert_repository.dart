import '../entities/alert_entity.dart';

abstract class AlertRepository {
  Future<void> emitAlert(AlertEntity alert);
  
  Future<void> updateAlertStatus(String alertId, String newStatus, String? resolvedBy);
  
  Stream<List<AlertEntity>> getActiveAlerts();
  
  Stream<List<AlertEntity>> getAlertsHistory();
  
  Future<void> updateEmergencyLocation(String alertId, double latitude, double longitude);
  
  Stream<AlertEntity?> listenToAlert(String alertId);
}
