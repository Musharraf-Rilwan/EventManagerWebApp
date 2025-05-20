import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Handle non-web platforms
    throw UnsupportedError(
      'DefaultFirebaseOptions are currently only configured for web platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBjmaLgiFJOiIeohcimd_bxHKncwlQJmVU',
    appId: '1:741175389716:web:4a75a833c8ae612b858101',
    messagingSenderId: '741175389716',
    projectId: 'event-manager-f417d',
    authDomain: 'event-manager-f417d.firebaseapp.com',
    storageBucket: 'event-manager-f417d.appspot.com',
    measurementId: 'G-CF336G60TY',
  );
}
