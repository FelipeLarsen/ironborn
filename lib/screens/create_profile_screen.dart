import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  String? _userType = 'aluno'; // Valor padrão
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o seu nome.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userProfile = UserModel(
        uid: user.uid,
        email: user.email!,
        name: _nameController.text.trim(),
        userType: _userType!,
      );

      // Salva o perfil do utilizador na coleção 'users' do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userProfile.toMap());

      // A navegação será tratada pelo AuthGate após o perfil ser criado
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o perfil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete o seu Perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'O seu nome completo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Eu sou um:', style: TextStyle(fontSize: 16)),
                RadioListTile<String>(
                  title: const Text('Aluno'),
                  value: 'aluno',
                  groupValue: _userType,
                  onChanged: (value) => setState(() => _userType = value),
                ),
                RadioListTile<String>(
                  title: const Text('Treinador'),
                  value: 'treinador',
                  groupValue: _userType,
                  onChanged: (value) => setState(() => _userType = value),
                ),
                RadioListTile<String>(
                  title: const Text('Nutricionista'),
                  value: 'nutricionista',
                  groupValue: _userType,
                  onChanged: (value) => setState(() => _userType = value),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepOrange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Salvar e Continuar',
                            style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}