class AppConfig {
  // Toggle this to use simulated local repositories instead of actual Firebase.
  // Defaults to true so the app runs out-of-the-box, but can be toggled in settings.
  static bool useMockData = true;

  // Preferences Keys
  static const String keyUseMock = 'use_mock_data';
  static const String keyVibrationEnabled = 'vibration_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyShakeEnabled = 'shake_enabled';
}
