// ARQUIVO ATUALIZADO: lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart'; // ALTERADO: Import agora usado para o Enum.
import 'package:ironborn/screens/dashboards/nutritionist_dashboard.dart';
import 'package:ironborn/screens/dashboards/student_dashboard.dart';
import 'package:ironborn/screens/dashboards/trainer_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Este caso raramente deve acontecer devido ao AuthGate, mas é uma boa proteção.
      return const Scaffold(
        body: Center(
          child: Text("Utilizador não encontrado. Por favor, faça login novamente."),
        ),
      );
    }

    // ALTERADO: de FutureBuilder para StreamBuilder para reatividade em tempo real.
    return StreamBuilder<DocumentSnapshot>(
      // ALTERADO: de .get() para .snapshots()
      stream:
          FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Erro: ${snapshot.error}")));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Perfil não encontrado.")));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData, snapshot.data!.id);

        // ALTERADO: switch agora usa o enum UserType para mais segurança.
        switch (userModel.userType) {
          case UserType.treinador:
            return TrainerDashboard(user: userModel);
          case UserType.nutricionista:
            return NutritionistDashboard(user: userModel);
          case UserType.aluno:
          default:
            return StudentDashboard(user: userModel);
        }
      },
    );
  }
}