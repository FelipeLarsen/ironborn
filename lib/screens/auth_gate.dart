import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/screens/create_profile_screen.dart';
import 'package:ironborn/screens/home_screen.dart';
import 'package:ironborn/screens/login_screen.dart';
import 'package:ironborn/services/notification_service.dart'; // NOVO: Import

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // NOVO: Lógica para salvar/remover o token
        if (authSnapshot.hasData && authSnapshot.data != null) {
          // Utilizador fez login, salva o token
          NotificationService().saveTokenToDatabase(authSnapshot.data!.uid);
        } else {
          // Utilizador fez logout (precisamos do ID antigo, o que é complexo aqui)
          // A remoção do token será feita no botão de logout.
        }

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!profileSnapshot.hasData ||
                !profileSnapshot.data!.exists ||
                profileSnapshot.data!.get('userType') == null) {
              return const CreateProfileScreen();
            }
            
            return const HomeScreen();
          },
        );
      },
    );
  }
}
