// ARQUIVO ATUALIZADO: lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/screens/settings_screen.dart'; // NOVO: Importar o ecrã de definições.
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late String _currentName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.user.name;
    _nameController = TextEditingController(text: _currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode estar vazio.')),
      );
      return;
    }

    if (newName == _currentName) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({'name': newName});

      if (!mounted) return;

      setState(() {
        _currentName = newName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      _nameController.text = _currentName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O meu Perfil'),
        // NOVO: Adiciona um botão de definições na AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Definições da Conta',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Completo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('E-mail'),
            subtitle: Text(widget.user.email),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Tipo de Perfil'),
            subtitle: Text(widget.user.userType.name[0].toUpperCase() +
                widget.user.userType.name.substring(1)),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
        ],
      ),
    );
  }
}
