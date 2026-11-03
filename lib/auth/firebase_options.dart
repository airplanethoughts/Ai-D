import 'package:firebase_core/firebase_core.dart';

/// Public Firebase client configuration, supplied by the developer at build time.
/// Never put an OpenAI key or a Firebase admin credential in these values.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    if ([apiKey, appId, projectId, sender].any((value) => value.isEmpty)) {
      throw StateError(
        'Firebase mode needs your own config. See config/firebase.example.json and README.md.',
      );
    }
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: sender,
      authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      databaseURL: String.fromEnvironment('FIREBASE_DATABASE_URL'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    );
  }
}
