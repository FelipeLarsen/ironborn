// NOVO FICHEIRO

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Função para mostrar o diálogo de apagar conta
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar Conta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Esta ação é irreversível. Para confirmar, por favor, insira a sua senha.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo antes da ação
              _deleteAccount(passwordController.text);
            },
            child: const Text('APAGAR CONTA',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // Lógica para apagar a conta
  Future<void> _deleteAccount(String password) async {
    if (password.isEmpty) {
      _showSnackbar('A senha é necessária para apagar a conta.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser!;
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: password);
      
      // Reautentica o utilizador para garantir que a ação é legítima
      await user.reauthenticateWithCredential(cred);
      
      // Apaga a conta
      await user.delete();

      // O AuthGate tratará do redirecionamento para o ecrã de login
    } on FirebaseAuthException catch (e) {
      _showSnackbar(e.message ?? 'Ocorreu um erro.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: const Text('Definições da Conta'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Alterar Senha'),
                  subtitle: const Text(
                      'Enviaremos um e-mail para redefinir a sua senha.'),
                  onTap: () async {
                    try {
                      await _auth.sendPasswordResetEmail(
                          email: _auth.currentUser!.email!);
                      _showSnackbar(
                          'E-mail de redefinição de senha enviado!');
                    } catch (e) {
                      _showSnackbar('Não foi possível enviar o e-mail.',
                          isError: true);
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Apagar Conta',
                      style: TextStyle(color: Colors.redAccent)),
                  subtitle: const Text(
                      'Esta ação é permanente e não pode ser desfeita.'),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),
    );
  }
}
