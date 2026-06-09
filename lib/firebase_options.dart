import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCr8LPLFkpRWc6AY_j5kP7jbdrFo2WH1uA',
    appId: '1:47047255892:web:CAMBIA_ESTO_CON_TU_WEB_APP_ID', // Reemplazar con el del panel de Firebase
    messagingSenderId: '47047255892',
    projectId: 'ecopanico',
    authDomain: 'ecopanico.firebaseapp.com',
    storageBucket: 'ecopanico.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCr8LPLFkpRWc6AY_j5kP7jbdrFo2WH1uA',
    appId: '1:47047255892:android:6461cc6380cd4524d34ac1',
    messagingSenderId: '47047255892',
    projectId: 'ecopanico',
    storageBucket: 'ecopanico.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCr8LPLFkpRWc6AY_j5kP7jbdrFo2WH1uA',
    appId: '1:47047255892:ios:xxxxxxxxxxxxx', // Opcional (si se añade iOS en el futuro)
    messagingSenderId: '47047255892',
    projectId: 'ecopanico',
    storageBucket: 'ecopanico.firebasestorage.app',
    iosBundleId: 'com.ecopanico.ecoPanico',
  );
}
