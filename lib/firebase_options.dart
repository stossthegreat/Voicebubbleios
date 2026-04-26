// File generated to provide platform-specific FirebaseOptions so
// Firebase.initializeApp does not depend on implicit native config loading.
// Values mirror android/app/google-services.json and ios/Runner/GoogleService-Info.plist.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web - '
        'rerun the FlutterFire CLI to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3pmcwr-HGXwdfYu2Kg5vLA1d5Pyxo76E',
    appId: '1:343007612090:android:e71dd80abe09b4dc664683',
    messagingSenderId: '343007612090',
    projectId: 'voicebubble-52ea5',
    storageBucket: 'voicebubble-52ea5.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvuOQ7fP-UKhb4nVWLosK_1BRtdIGrlcU',
    appId: '1:343007612090:ios:7de25657324a1d0d664683',
    messagingSenderId: '343007612090',
    projectId: 'voicebubble-52ea5',
    storageBucket: 'voicebubble-52ea5.firebasestorage.app',
    iosBundleId: 'com.example.voicebubble',
    iosClientId:
        '343007612090-b0f1qpgtu738j92cp1g7i329c5kc77rk.apps.googleusercontent.com',
  );
}
