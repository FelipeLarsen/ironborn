import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/screens/auth_gate.dart';
import 'package:ironborn/services/notification_service.dart'; // Importa o serviço de notificações
import 'firebase_options.dart';

void main() async {
  // Garante que o Flutter está inicializado antes de qualquer outra coisa.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase para a plataforma atual.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializa o nosso serviço de notificações para pedir permissões e configurar listeners.
  await NotificationService().initialize();

  runApp(const IronbornApp());
}

class IronbornApp extends StatelessWidget {
  const IronbornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove a faixa "Debug" no canto superior direito.
      debugShowCheckedModeBanner: false,
      title: 'Ironborn',
      // Define o tema geral da aplicação.
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      // O AuthGate é o ponto de entrada que decide qual ecrã mostrar.
      home: const AuthGate(),
    );
  }
}

