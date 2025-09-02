// ARQUIVO ATUALIZADO: lib/screens/create_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart'; // Import necessário para o Enum

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  // ALTERADO: de String? para UserType? para segurança de tipo.
  UserType? _selectedUserType;
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, selecione um tipo de perfil."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser!;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            // ALTERADO: Usa o .name do enum para salvar a string correta.
            {'userType': _selectedUserType!.name},
            SetOptions(merge: true),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar perfil: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Olá, ${user.displayName ?? 'Usuário'}!', // ALTERADO: Usa displayName do Auth para simplicidade.
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete o seu Perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  const Text('Eu sou um:', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  // ALTERADO: RadioListTile agora usa o enum UserType.
                  RadioListTile<UserType>(
                    title: const Text('Aluno'),
                    value: UserType.aluno,
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value),
                  ),
                  RadioListTile<UserType>(
                    title: const Text('Treinador'),
                    value: UserType.treinador,
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value),
                  ),
                  RadioListTile<UserType>(
                    title: const Text('Nutricionista'),
                    value: UserType.nutricionista,
                    groupValue: _selectedUserType,
                    onChanged: (value) => setState(() => _selectedUserType = value),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Salvar e Continuar',
                              style: TextStyle(fontSize: 18)),
                        ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}