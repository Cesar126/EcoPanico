import 'package:flutter/services.dart';

class FeedbackService {
  static Future<void> triggerVibration() async {
    // Perform repetitive vibrations for emergency attention
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  static Future<void> triggerTapFeedback() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> playAlertSound() async {
    // Play default alert sound
    await SystemSound.play(SystemSoundType.click);
    
    // In a fully configured app, you can use the `audioplayers` package:
    // AudioPlayer().play(AssetSource('sounds/emergency_siren.mp3'));
    // Since native audio configuration can vary, we fall back to SystemSound.
  }
}
