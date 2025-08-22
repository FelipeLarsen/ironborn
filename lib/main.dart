import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'firebase_options.dart'; // Importa o arquivo gerado automaticamente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Esta é a forma moderna e correta de inicializar o Firebase.
  // Ele usa o arquivo firebase_options.dart para carregar a configuração
  // correta para a plataforma em que a aplicação está a ser executada.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const IronbornApp());
}

class IronbornApp extends StatelessWidget {
  const IronbornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ironborn',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const AuthGate(),
    );
  }
}