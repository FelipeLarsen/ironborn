// ARQUIVO ATUALIZADO: lib/screens/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';
import 'package:ironborn/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers para os campos
  late final TextEditingController _nameController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _bioController;
  late final TextEditingController _specsController;

  late UserModel _currentUser; // Estado local para refletir as mudanças
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _nameController = TextEditingController(text: _currentUser.name);
    _photoUrlController = TextEditingController(text: _currentUser.photoUrl);
    _bioController = TextEditingController(text: _currentUser.bio);
    // Junta a lista de especializações numa única string para o campo de texto.
    _specsController = TextEditingController(text: _currentUser.specializations?.join(', '));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _bioController.dispose();
    _specsController.dispose();
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

    setState(() => _isLoading = true);

    // Converte a string de especializações de volta para uma lista.
    final newSpecs = _specsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    // Cria um mapa apenas com os dados a serem atualizados.
    final Map<String, dynamic> dataToUpdate = {
      'name': newName,
      'photoUrl': _photoUrlController.text.trim(),
      'bio': _bioController.text.trim(),
      'specializations': newSpecs,
    };
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.id)
          .update(dataToUpdate);

      if (!mounted) return;

      // Atualiza o estado local com os novos dados.
      setState(() {
        _currentUser = _currentUser.copyWith(
          name: newName,
          photoUrl: _photoUrlController.text.trim(),
          bio: _bioController.text.trim(),
          specializations: newSpecs,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar o perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfessional = _currentUser.userType != UserType.aluno;

    return Scaffold(
      appBar: AppBar(
        title: const Text('O meu Perfil'),
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
          // Secção de Avatar e Nome
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _currentUser.photoUrl != null && _currentUser.photoUrl!.isNotEmpty
                  ? NetworkImage(_currentUser.photoUrl!)
                  : null,
              child: _currentUser.photoUrl == null || _currentUser.photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
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
            subtitle: Text(_currentUser.email),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Tipo de Perfil'),
            subtitle: Text(_currentUser.userType.name[0].toUpperCase() +
                _currentUser.userType.name.substring(1)),
          ),

          // NOVO: Secção visível apenas para profissionais
          if (isProfessional) ...[
            const Divider(height: 32),
            const Text("Perfil Público", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             TextFormField(
              controller: _photoUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da Foto de Perfil',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Biografia / Sobre Mim',
                border: OutlineInputBorder(),
              ),
            ),
             const SizedBox(height: 16),
            TextFormField(
              controller: _specsController,
              decoration: const InputDecoration(
                labelText: 'Especializações (separadas por vírgula)',
                border: OutlineInputBorder(),
                hintText: 'ex: Perda de peso, Hipertrofia, Nutrição desportiva',
              ),
            ),
          ],
          
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

