// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDL69C2RHDmNu0LMMk_kJM2tqjlsf_tMy8',
    appId: '1:604175490645:web:b98e5ca0cebde2b330bedc',
    messagingSenderId: '604175490645',
    projectId: 'yes-tracker-customer',
    authDomain: 'yes-tracker-customer.firebaseapp.com',
    storageBucket: 'yes-tracker-customer.appspot.com',
    measurementId: 'G-CCQCJ7WCSK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_l-sB11D3DWTmHmeEZAl5thVMUz0WZxw',
    appId: '1:604175490645:android:37ad5d9d6d28b01b30bedc',
    messagingSenderId: '604175490645',
    projectId: 'yes-tracker-customer',
    storageBucket: 'yes-tracker-customer.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAPMjC96R4l-TvsIZF_SXQszGVmeAaQYAo',
    appId: '1:604175490645:ios:4795b26f8f930a7f30bedc',
    messagingSenderId: '604175490645',
    projectId: 'yes-tracker-customer',
    storageBucket: 'yes-tracker-customer.appspot.com',
    iosBundleId: 'com.mighty.delivery',
  );
}