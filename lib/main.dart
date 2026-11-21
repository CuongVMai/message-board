import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'auth_gate.dart'; ////// added: AuthGate lives in its own file

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false, ////// added
      home: SplashScreen(),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<FirebaseApp> _initialize() async {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    ////// added: keep the splash on screen ~2 seconds so it can be seen/screenshotted
    await Future.delayed(const Duration(seconds: 2));
    return app;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Firebase could not start. Check your setup.'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initialization = _initialize();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          ////// changed: styled splash instead of a plain spinner
          return const Scaffold(
            backgroundColor: Colors.indigo,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum, size: 96, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Message Board',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chatboards for the new age',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          );
        }
        return const AuthGate();
      },
    );
  }
}
