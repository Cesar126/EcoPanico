import 'dart:async';
import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';
import 'mock_auth_repository.dart';

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
      latitude: 0.33201,
      longitude: -78.11743,
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
      latitude: 0.33120,
      longitude: -78.11920,
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
      latitude: 0.33310,
      longitude: -78.11520,
      level: 'critical',
      status: 'resuelta',
      resolvedBy: 'Carlos Andrade',
    )
  ];

  static final StreamController<List<AlertEntity>> _alertsController =
      StreamController<List<AlertEntity>>.broadcast();

  MockAlertRepository() {
    _getRelativeAlerts().then((list) => _alertsController.add(list));
  }

  Future<List<AlertEntity>> _getRelativeAlerts() async {
    final user = await MockAuthRepository().getCurrentUser();
    // Default fallback coordinates if no user is found
    final double baseLat = user?.latitude ?? 0.33201;
    final double baseLng = user?.longitude ?? -78.11743;

    return _mockAlerts.map((alert) {
      if (alert.id == 'alert_1' || alert.id == 'alert_2' || alert.id == 'alert_3') {
        double offsetLat = 0.0;
        double offsetLng = 0.0;
        if (alert.id == 'alert_1') {
          // active alert, e.g. 50m away
          offsetLat = 0.0003;
          offsetLng = -0.0002;
        } else if (alert.id == 'alert_2') {
          // resolved alert, a bit further away (e.g. 150m)
          offsetLat = -0.0008;
          offsetLng = 0.0007;
        } else if (alert.id == 'alert_3') {
          // resolved alert, near user (e.g. 80m)
          offsetLat = 0.0004;
          offsetLng = 0.0004;
        }
        return alert.copyWith(
          latitude: baseLat + offsetLat,
          longitude: baseLng + offsetLng,
        );
      }
      return alert;
    }).toList();
  }

  @override
  Stream<List<AlertEntity>> getActiveAlerts() {
    final controller = StreamController<List<AlertEntity>>();
    
    _getRelativeAlerts().then((relativeAlerts) {
      if (!controller.isClosed) {
        controller.add(relativeAlerts.where((a) => a.status == 'activa' || a.status == 'en_atencion').toList());
      }
    });

    final timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!controller.isClosed) {
        final relativeAlerts = await _getRelativeAlerts();
        controller.add(relativeAlerts.where((a) => a.status == 'activa' || a.status == 'en_atencion').toList());
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Stream<List<AlertEntity>> getAlertsHistory() {
    final controller = StreamController<List<AlertEntity>>();
    
    _getRelativeAlerts().then((relativeAlerts) {
      if (!controller.isClosed) {
        controller.add(relativeAlerts);
      }
    });

    final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!controller.isClosed) {
        final relativeAlerts = await _getRelativeAlerts();
        controller.add(relativeAlerts);
      }
    });

    controller.onCancel = () => timer.cancel();
    return controller.stream;
  }

  @override
  Future<void> emitAlert(AlertEntity alert) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _mockAlerts.insert(0, alert);
    final relativeList = await _getRelativeAlerts();
    _alertsController.add(relativeList);
    
    // Simulate real-time tracking: slightly adjust coordinates if it's critical
    if (alert.isCritical) {
      int ticks = 0;
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        final index = _mockAlerts.indexWhere((a) => a.id == alert.id);
        if (index == -1 || _mockAlerts[index].status == 'resuelta' || ticks > 12) {
          timer.cancel();
          return;
        }
        ticks++;
        final currentAlert = _mockAlerts[index];
        _mockAlerts[index] = currentAlert.copyWith(
          latitude: currentAlert.latitude + 0.0001,
          longitude: currentAlert.longitude - 0.0001,
        );
        final list = await _getRelativeAlerts();
        _alertsController.add(list);
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
      final list = await _getRelativeAlerts();
      _alertsController.add(list);
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
      final list = await _getRelativeAlerts();
      _alertsController.add(list);
    }
  }

  @override
  Stream<AlertEntity?> listenToAlert(String alertId) {
    return Stream.periodic(const Duration(seconds: 1), (_) async {
      try {
        final relativeAlerts = await _getRelativeAlerts();
        return relativeAlerts.firstWhere((a) => a.id == alertId);
      } catch (_) {
        return null;
      }
    }).asyncMap((event) async => await event).asBroadcastStream();
  }
}
