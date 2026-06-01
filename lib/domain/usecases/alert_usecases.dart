import '../entities/alert_entity.dart';
import '../repositories/alert_repository.dart';

class EmitAlertUseCase {
  final AlertRepository repository;
  EmitAlertUseCase(this.repository);

  Future<void> call(AlertEntity alert) {
    return repository.emitAlert(alert);
  }
}

class UpdateAlertStatusUseCase {
  final AlertRepository repository;
  UpdateAlertStatusUseCase(this.repository);

  Future<void> call(String alertId, String newStatus, String? resolvedBy) {
    return repository.updateAlertStatus(alertId, newStatus, resolvedBy);
  }
}

class GetActiveAlertsUseCase {
  final AlertRepository repository;
  GetActiveAlertsUseCase(this.repository);

  Stream<List<AlertEntity>> call() {
    return repository.getActiveAlerts();
  }
}

class GetAlertsHistoryUseCase {
  final AlertRepository repository;
  GetAlertsHistoryUseCase(this.repository);

  Stream<List<AlertEntity>> call() {
    return repository.getAlertsHistory();
  }
}

class UpdateEmergencyLocationUseCase {
  final AlertRepository repository;
  UpdateEmergencyLocationUseCase(this.repository);

  Future<void> call(String alertId, double latitude, double longitude) {
    return repository.updateEmergencyLocation(alertId, latitude, longitude);
  }
}

class ListenToAlertUseCase {
  final AlertRepository repository;
  ListenToAlertUseCase(this.repository);

  Stream<AlertEntity?> call(String alertId) {
    return repository.listenToAlert(alertId);
  }
}
