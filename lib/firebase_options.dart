// File generated from google-services.json for project styledrop-e0c02
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;
      default:
        return android;
    }
  }

  // Web config — update apiKey/appId if you add a web app in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBskCzSghGyAWypz8F4v9OaaW1Cft_H7o8',
    appId: '1:497002874460:android:871cd60e0a89aed4b40899',
    messagingSenderId: '497002874460',
    projectId: 'styledrop-e0c02',
    authDomain: 'styledrop-e0c02.firebaseapp.com',
    storageBucket: 'styledrop-e0c02.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBskCzSghGyAWypz8F4v9OaaW1Cft_H7o8',
    appId: '1:497002874460:android:871cd60e0a89aed4b40899',
    messagingSenderId: '497002874460',
    projectId: 'styledrop-e0c02',
    storageBucket: 'styledrop-e0c02.firebasestorage.app',
  );

  // iOS config — update appId/apiKey if you add an iOS app in Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBskCzSghGyAWypz8F4v9OaaW1Cft_H7o8',
    appId: '1:497002874460:android:871cd60e0a89aed4b40899',
    messagingSenderId: '497002874460',
    projectId: 'styledrop-e0c02',
    storageBucket: 'styledrop-e0c02.firebasestorage.app',
    iosBundleId: 'com.styledrop.app',
  );
}
