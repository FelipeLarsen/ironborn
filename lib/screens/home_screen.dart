import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'dashboards/student_dashboard.dart';
import 'dashboards/trainer_dashboard.dart';
import 'dashboards/nutritionist_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Future para guardar os dados do perfil do utilizador
  late final Future<UserModel?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile();
  }

  // Função para buscar os dados do perfil no Firestore
  Future<UserModel?> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      // Tratar o erro, se necessário
      print("Erro ao buscar perfil: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _userProfileFuture,
      builder: (context, snapshot) {
        // Enquanto os dados estão a ser carregados
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Se houver um erro ou o perfil não for encontrado
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não foi possível carregar o seu perfil.'),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Fazer Login Novamente'),
                  )
                ],
              ),
            ),
          );
        }

        final userProfile = snapshot.data!;

        // Direciona para o dashboard correto com base no userType
        switch (userProfile.userType) {
          case 'treinador':
            return TrainerDashboard(user: userProfile);
          case 'nutricionista':
            return NutritionistDashboard(user: userProfile);
          case 'aluno':
          default:
            return StudentDashboard(user: userProfile);
        }
      },
    );
  }
}