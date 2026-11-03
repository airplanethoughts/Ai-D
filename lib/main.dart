import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'admins/home_page.dart';
import 'users/home_page.dart';
import 'auth/auth.dart';
import 'auth/firebase_options.dart';
import 'demo/demo_app.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const connected = bool.fromEnvironment('USE_FIREBASE', defaultValue: false);
  if (!connected) {
    runApp(const DemoApp());
    return;
  }
  try {
    app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuth.instanceFor(app: app);
    const emulators = bool.fromEnvironment(
      'USE_EMULATORS',
      defaultValue: false,
    );
    if (emulators) {
      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: '127.0.0.1',
      );
      await auth.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
    }
    if (!kIsWeb) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    }
    runApp(const AuthExampleApp());
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ai-D could not connect to Firebase. Check your configuration and network. See README.md for setup.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => runApp(const DemoApp()),
                    child: const Text('Open local demo instead'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthExampleApp extends StatelessWidget {
  const AuthExampleApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ai-D',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) return const AuthGate();
        return _SignedInGate(
          key: ValueKey(snapshot.data!.uid),
          user: snapshot.data!,
        );
      },
    ),
  );
}

class _SignedInGate extends StatefulWidget {
  final User user;
  const _SignedInGate({super.key, required this.user});
  @override
  State<_SignedInGate> createState() => _SignedInGateState();
}

class _SignedInGateState extends State<_SignedInGate> {
  late final Future<IdTokenResult> _claims = widget.user.getIdTokenResult();
  @override
  Widget build(BuildContext context) => FutureBuilder<IdTokenResult>(
    future: _claims,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load your account. Please sign in again.',
                ),
                TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.data!.claims?['admin'] == true
          ? const AdminHomePage()
          : const BottomNavigationBarControl();
    },
  );
}
