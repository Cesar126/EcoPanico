import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/alert_entity.dart';
import '../../core/utils/shake_detector.dart';
import '../../core/utils/feedback_service.dart';
import '../providers/usecase_providers.dart';
import 'auth_viewmodel.dart';

class AlertState {
  final List<AlertEntity> activeAlerts;
  final List<AlertEntity> alertsHistory;
  final AlertEntity? currentOwnAlert;
  final bool isLoading;
  final String? errorMessage;
  final bool isTrackingLocation;
  final int onlineNeighbors;

  AlertState({
    this.activeAlerts = const [],
    this.alertsHistory = const [],
    this.currentOwnAlert,
    this.isLoading = false,
    this.errorMessage,
    this.isTrackingLocation = false,
    this.onlineNeighbors = 0,
  });

  AlertState copyWith({
    List<AlertEntity>? activeAlerts,
    List<AlertEntity>? alertsHistory,
    AlertEntity? currentOwnAlert,
    bool? isLoading,
    String? errorMessage,
    bool? isTrackingLocation,
    int? onlineNeighbors,
    bool clearOwnAlert = false,
    bool clearError = false,
  }) {
    return AlertState(
      activeAlerts: activeAlerts ?? this.activeAlerts,
      alertsHistory: alertsHistory ?? this.alertsHistory,
      currentOwnAlert: clearOwnAlert ? null : (currentOwnAlert ?? this.currentOwnAlert),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isTrackingLocation: isTrackingLocation ?? this.isTrackingLocation,
      onlineNeighbors: onlineNeighbors ?? this.onlineNeighbors,
    );
  }
}

class AlertViewModel extends Notifier<AlertState> {
  StreamSubscription? _activeAlertsSub;
  StreamSubscription? _alertsHistorySub;
  StreamSubscription? _onlineNeighborsSub;
  StreamSubscription? _gpsTrackingSub;
  
  ShakeDetector? _shakeDetector;
  bool _shakeEnabled = true;

  @override
  AlertState build() {
    // 1. Listen to active alerts
    _activeAlertsSub = ref.read(getActiveAlertsUseCaseProvider).call().listen((alerts) {
      final currentUser = ref.read(authViewModelProvider).user;

      // Filter active alerts to 200m range
      final filteredAlerts = alerts.where((alert) {
        // ALWAYS keep the user's own active alert in the list so they can see and manage it
        if (state.currentOwnAlert != null && alert.id == state.currentOwnAlert!.id) {
          return true;
        }

        if (currentUser == null || currentUser.latitude == null || currentUser.longitude == null) {
          return true;
        }
        final distance = Geolocator.distanceBetween(
          currentUser.latitude!,
          currentUser.longitude!,
          alert.latitude,
          alert.longitude,
        );
        return distance <= 200.0;
      }).toList();

      if (state.currentOwnAlert != null) {
        // Check the unfiltered database list 'alerts' to see if the user's own alert was resolved/removed
        final matchedOwn = alerts.where((a) => a.id == state.currentOwnAlert!.id);
        if (matchedOwn.isEmpty) {
          _stopLocationTracking();
          state = state.copyWith(clearOwnAlert: true);
        }
      }
      
      // Find new alerts that were not in the previous active list
      final previousIds = state.activeAlerts.map((a) => a.id).toSet();
      final newAlerts = filteredAlerts.where((a) => !previousIds.contains(a.id)).toList();

      if (currentUser != null && newAlerts.isNotEmpty) {
        for (final alert in newAlerts) {
          final age = DateTime.now().difference(alert.timestamp);
          if (alert.neighborId != currentUser.id && alert.status == 'activa' && age.inSeconds < 60) {
            _triggerCommunityNotificationEffects();
            break; // Trigger once per batch
          }
        }
      }

      state = state.copyWith(activeAlerts: filteredAlerts);
    });

    // 2. Listen to alerts history
    _alertsHistorySub = ref.read(getAlertsHistoryUseCaseProvider).call().listen((history) {
      final currentUser = ref.read(authViewModelProvider).user;

      // Filter alerts history to 200m range
      final filteredHistory = history.where((alert) {
        if (currentUser == null || currentUser.latitude == null || currentUser.longitude == null) {
          return true;
        }
        final distance = Geolocator.distanceBetween(
          currentUser.latitude!,
          currentUser.longitude!,
          alert.latitude,
          alert.longitude,
        );
        return distance <= 200.0;
      }).toList();

      state = state.copyWith(alertsHistory: filteredHistory);
    });

    // 3. Listen to online neighbors count
    _onlineNeighborsSub = ref.read(getOnlineNeighborsCountUseCaseProvider).call().listen((count) {
      state = state.copyWith(onlineNeighbors: count);
    });

    // 4. Initialize Shake detector
    _initShakeDetector();

    ref.onDispose(() {
      _activeAlertsSub?.cancel();
      _alertsHistorySub?.cancel();
      _onlineNeighborsSub?.cancel();
      _stopLocationTracking();
      _shakeDetector?.stopListening();
    });

    return AlertState();
  }

  void _initShakeDetector() {
    _shakeDetector = ShakeDetector(
      onShake: () {
        if (_shakeEnabled) {
          triggerEmergencyAlert(
            type: 'shake_emergencia',
            level: 'critical',
          );
        }
      },
    );
    _shakeDetector?.startListening();
  }

  void setShakeEnabled(bool enabled) {
    _shakeEnabled = enabled;
    if (enabled) {
      _shakeDetector?.startListening();
    } else {
      _shakeDetector?.stopListening();
    }
  }

  Future<void> _triggerCommunityNotificationEffects() async {
    await FeedbackService.triggerVibration();
    await FeedbackService.playAlertSound();
  }

  Future<Position?> _determineGPSPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación (GPS) están desactivados en el teléfono.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permiso de ubicación denegado por el usuario.';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están denegados permanentemente.';
    }

    // Use standard Settings
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> triggerEmergencyAlert({
    required String type,
    required String level,
  }) async {
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Debes iniciar sesión para emitir alertas.');
      return;
    }

    if (state.currentOwnAlert != null) {
      state = state.copyWith(errorMessage: 'Ya tienes una alerta activa en este momento.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    
    double lat = -2.1430;
    double lng = -79.9020;

    try {
      final position = await _determineGPSPosition();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
      }
    } catch (e) {
      lat = -2.1432 + (DateTime.now().second % 10) * 0.0001; 
      lng = -79.9015 - (DateTime.now().second % 10) * 0.0001;
    }

    final alert = AlertEntity(
      id: const Uuid().v4(),
      neighborId: user.id,
      neighborName: user.fullName,
      neighborPhone: user.phone,
      neighborHouseNumber: user.houseNumber,
      type: type,
      timestamp: DateTime.now(),
      latitude: lat,
      longitude: lng,
      level: level,
      status: 'activa',
    );

    try {
      await ref.read(emitAlertUseCaseProvider).call(alert);
      state = state.copyWith(
        currentOwnAlert: alert,
        isLoading: false,
      );
      
      await FeedbackService.triggerTapFeedback();
      _startLocationTracking(alert.id);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al emitir alerta: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void _startLocationTracking(String alertId) {
    _gpsTrackingSub?.cancel();
    state = state.copyWith(isTrackingLocation: true);

    _gpsTrackingSub = Stream.periodic(const Duration(seconds: 5)).listen((_) async {
      try {
        double lat = -2.1430;
        double lng = -79.9020;
        
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
        
        await ref.read(updateEmergencyLocationUseCaseProvider).call(alertId, lat, lng);
      } catch (e) {
        if (state.currentOwnAlert != null) {
          final curr = state.currentOwnAlert!;
          final newLat = curr.latitude + 0.00005;
          final newLng = curr.longitude - 0.00005;
          
          final updatedAlert = curr.copyWith(latitude: newLat, longitude: newLng);
          state = state.copyWith(currentOwnAlert: updatedAlert);
          
          await ref.read(updateEmergencyLocationUseCaseProvider).call(alertId, newLat, newLng);
        }
      }
    });
  }

  void _stopLocationTracking() {
    _gpsTrackingSub?.cancel();
    _gpsTrackingSub = null;
    state = state.copyWith(isTrackingLocation: false);
  }

  Future<void> resolveAlert(String alertId) async {
    final user = ref.read(authViewModelProvider).user;
    final resolverName = user != null ? user.fullName : 'Comunidad';

    try {
      await ref.read(updateAlertStatusUseCaseProvider).call(alertId, 'resuelta', resolverName);
      
      if (state.currentOwnAlert?.id == alertId) {
        _stopLocationTracking();
        state = state.copyWith(clearOwnAlert: true);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> attendAlert(String alertId) async {
    try {
      await ref.read(updateAlertStatusUseCaseProvider).call(alertId, 'en_atencion', null);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Global provider for Alert State & Actions
final alertViewModelProvider = NotifierProvider<AlertViewModel, AlertState>(() {
  return AlertViewModel();
});
