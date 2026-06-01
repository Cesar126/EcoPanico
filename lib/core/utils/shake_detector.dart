import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final Function() onShake;
  final double shakeThreshold;
  final Duration shakeCooldown;
  final Duration shakeWindow;
  final int shakesRequired;

  StreamSubscription? _subscription;
  DateTime? _lastShakeTime;
  final List<DateTime> _shakeTimestamps = [];

  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = 12.0, // m/s^2 above gravity or user accel force
    this.shakeCooldown = const Duration(milliseconds: 500), // Min duration between registered shakes
    this.shakeWindow = const Duration(seconds: 5), // Timeframe to accumulate shakes
    this.shakesRequired = 3,
  });

  void startListening() {
    _subscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > shakeThreshold) {
        final DateTime now = DateTime.now();
        
        // Cooldown between individual shakes to avoid counting a single physical shake multiple times
        if (_lastShakeTime != null && now.difference(_lastShakeTime!) < shakeCooldown) {
          return;
        }

        _lastShakeTime = now;
        _shakeTimestamps.add(now);

        // Remove shakes outside of the 5-second window
        _shakeTimestamps.removeWhere(
          (timestamp) => now.difference(timestamp) > shakeWindow,
        );

        if (_shakeTimestamps.length >= shakesRequired) {
          _shakeTimestamps.clear(); // Reset to prevent double firing
          onShake();
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _shakeTimestamps.clear();
  }
}
