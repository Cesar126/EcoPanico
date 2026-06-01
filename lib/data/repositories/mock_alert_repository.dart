import 'dart:async';
import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';

class MockAlertRepository implements AlertRepository {
  static final List<AlertEntity> _mockAlerts = [
    AlertEntity(
      id: 'alert_1',
      neighborId: 'vecino_2',
      neighborName: 'María Augusta Rodriguez',
      neighborPhone: '+593 98 111 2222',
      neighborHouseNumber: 'Vivienda 15',
      type: 'sospechoso',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      latitude: -2.1432,
      longitude: -79.9015,
      level: 'medium',
      status: 'activa',
    ),
    AlertEntity(
      id: 'alert_2',
      neighborId: 'vecino_3',
      neighborName: 'Carlos Andrade',
      neighborPhone: '+593 99 555 4444',
      neighborHouseNumber: 'Vivienda 28',
      type: 'robo',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      latitude: -2.1458,
      longitude: -79.9042,
      level: 'critical',
      status: 'resuelta',
      resolvedBy: 'Administrador Los Ceibos',
    ),
    AlertEntity(
      id: 'alert_3',
      neighborId: 'vecino_4',
      neighborName: 'Ana Luisa Beltrán',
      neighborPhone: '+593 99 888 7777',
      neighborHouseNumber: 'Vivienda 104',
      type: 'shake_emergencia',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      latitude: -2.1415,
      longitude: -79.8998,
      level: 'critical',
      status: 'resuelta',
      resolvedBy: 'Carlos Andrade',
    )
  ];

  static final StreamController<List<AlertEntity>> _alertsController =
      StreamController<List<AlertEntity>>.broadcast();

  MockAlertRepository() {
    _alertsController.add(List.from(_mockAlerts));
  }

  @override
  Stream<List<AlertEntity>> getActiveAlerts() {
    // Return a stream that updates when the list changes
    final controller = StreamController<List<AlertEntity>>();
    controller.add(_mockAlerts.where((a) => a.status == 'activa' || a.status == 'en_atencion').toList());

    final timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!controller.isClosed) {
        controller.add(_mockAlerts.where((a) => a.status == 'activa' || a.status == 'en_atencion').toList());
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Stream<List<AlertEntity>> getAlertsHistory() {
    final controller = StreamController<List<AlertEntity>>();
    controller.add(List.from(_mockAlerts));

    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!controller.isClosed) {
        controller.add(List.from(_mockAlerts));
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Future<void> emitAlert(AlertEntity alert) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAlerts.insert(0, alert);
    _alertsController.add(List.from(_mockAlerts));
    
    // Simulate real-time tracking: if the emitted alert is a robbery/shake, let's slightly adjust the coordinates every 5 seconds to simulate movement
    if (alert.isCritical) {
      int ticks = 0;
      Timer.periodic(const Duration(seconds: 5), (timer) {
        final index = _mockAlerts.indexWhere((a) => a.id == alert.id);
        if (index == -1 || _mockAlerts[index].status == 'resuelta' || ticks > 12) {
          timer.cancel();
          return;
        }
        ticks++;
        final currentAlert = _mockAlerts[index];
        // Move slightly North-West
        _mockAlerts[index] = currentAlert.copyWith(
          latitude: currentAlert.latitude + 0.0001,
          longitude: currentAlert.longitude - 0.0001,
        );
        _alertsController.add(List.from(_mockAlerts));
      });
    }
  }

  @override
  Future<void> updateAlertStatus(String alertId, String newStatus, String? resolvedBy) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _mockAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _mockAlerts[idx] = _mockAlerts[idx].copyWith(
        status: newStatus,
        resolvedBy: resolvedBy,
      );
      _alertsController.add(List.from(_mockAlerts));
    }
  }

  @override
  Future<void> updateEmergencyLocation(String alertId, double latitude, double longitude) async {
    final idx = _mockAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1) {
      _mockAlerts[idx] = _mockAlerts[idx].copyWith(
        latitude: latitude,
        longitude: longitude,
      );
      _alertsController.add(List.from(_mockAlerts));
    }
  }

  @override
  Stream<AlertEntity?> listenToAlert(String alertId) {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      try {
        return _mockAlerts.firstWhere((a) => a.id == alertId);
      } catch (_) {
        return null;
      }
    }).asBroadcastStream();
  }
}
