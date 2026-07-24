// Firebase options for project kooba-stock-management.
// Android: from android/app/google-services.json
// Web: register a Web app in Firebase Console (or run tool/configure_firebase_web.ps1
// after `firebase login`), then set [web].appId to the Web app id
// (format: 1:366516824804:web:xxxxxxxx).

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Run flutterfire configure to add GoogleService-Info.plist.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Web Firebase config for project `kooba-stock-management`.
  ///
  /// IMPORTANT: Replace [appId] with your Web app id from Firebase Console:
  /// Project settings → Your apps → Web app → SDK setup
  /// Example: '1:366516824804:web:a1b2c3d4e5f6...'
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAj1gQJqmthH4CN6NDscWBdFe2AHzh3rm0',
    appId: '1:366516824804:web:PENDING_ADD_FROM_CONSOLE',
    messagingSenderId: '366516824804',
    projectId: 'kooba-stock-management',
    authDomain: 'kooba-stock-management.firebaseapp.com',
    storageBucket: 'kooba-stock-management.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAj1gQJqmthH4CN6NDscWBdFe2AHzh3rm0',
    appId: '1:366516824804:android:3fbf9f260221aae0a4daf1',
    messagingSenderId: '366516824804',
    projectId: 'kooba-stock-management',
    storageBucket: 'kooba-stock-management.firebasestorage.app',
  );
}
