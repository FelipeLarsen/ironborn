import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Se o utilizador não está logado, mostra a tela de login
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        // Se o utilizador está logado, verifica se o perfil existe no Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, firestoreSnapshot) {
            // Enquanto espera, mostra um ecrã de carregamento
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Se o documento do perfil não existe, manda para a criação de perfil
            if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
              return const CreateProfileScreen();
            }

            // Se o utilizador está logado e tem perfil, mostra a tela principal
            return const HomeScreen();
          },
        );
      },
    );
  }
}