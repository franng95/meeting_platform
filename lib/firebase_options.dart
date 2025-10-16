// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Dummy configuration for emulator use only
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForEmulator',
    appId: '1:123456789:web:abc123',
    messagingSenderId: '123456789',
    projectId: 'demo-meeting-platform',
    storageBucket: 'demo-meeting-platform.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForEmulator',
    appId: '1:123456789:android:abc123',
    messagingSenderId: '123456789',
    projectId: 'demo-meeting-platform',
    storageBucket: 'demo-meeting-platform.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForEmulator',
    appId: '1:123456789:ios:abc123',
    messagingSenderId: '123456789',
    projectId: 'demo-meeting-platform',
    storageBucket: 'demo-meeting-platform.appspot.com',
    iosBundleId: 'com.example.meetingPlatform',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForEmulator',
    appId: '1:123456789:macos:abc123',
    messagingSenderId: '123456789',
    projectId: 'demo-meeting-platform',
    storageBucket: 'demo-meeting-platform.appspot.com',
    iosBundleId: 'com.example.meetingPlatform',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForEmulator',
    appId: '1:123456789:windows:abc123',
    messagingSenderId: '123456789',
    projectId: 'demo-meeting-platform',
    storageBucket: 'demo-meeting-platform.appspot.com',
  );
}