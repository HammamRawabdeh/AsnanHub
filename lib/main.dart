
import 'package:asnan_hub/pages/auth/auth_gate.dart';
import 'package:asnan_hub/theme/theme_data.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("🔥 Firebase connected successfully");
  } catch (e) {
    print("❌ Firebase connection failed: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsnanHub',
      theme: asnanTheme,
      
      home: const AuthGate(),
    );
  }
}
