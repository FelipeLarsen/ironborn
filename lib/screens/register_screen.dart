// ARQUIVO ATUALIZADO: lib/screens/register_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // NOVO: Variáveis de estado para os requisitos da senha
  bool _hasEightCharacters = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialCharacter = false;

  @override
  void initState() {
    super.initState();
    // NOVO: Listener para verificar a senha em tempo real
    _passwordController.addListener(_updatePasswordRequirements);
  }

  void _updatePasswordRequirements() {
    final password = _passwordController.text;
    setState(() {
      _hasEightCharacters = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          userType: UserType.aluno,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());

        await userCredential.user!.updateDisplayName(newUser.name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Conta criada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
          // O AuthGate tratará do redirecionamento
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.message ?? "Ocorreu um erro desconhecido.");
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar("Ocorreu um erro inesperado: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordRequirements);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ALTERADO: Validação para o nome
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O nome é obrigatório.';
                      }
                      // RegEx: Permite apenas letras (maiúsculas/minúsculas) e espaços.
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                        return 'O nome deve conter apenas letras e espaços.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ALTERADO: Validação para o e-mail
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O e-mail é obrigatório.';
                      }
                      // RegEx: Validação de formato de e-mail padrão.
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // ALTERADO: Validação completa para a senha
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'A senha é obrigatória.';
                      }
                      if (!_hasEightCharacters || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSpecialCharacter) {
                        return 'A senha não cumpre todos os requisitos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // NOVO: Widget para mostrar os requisitos da senha
                  _buildPasswordRequirements(),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cadastrar',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // NOVO: Widget que constrói a lista de requisitos da senha.
  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow('Pelo menos 8 caracteres', _hasEightCharacters),
        _buildRequirementRow('Pelo menos uma letra maiúscula (A-Z)', _hasUppercase),
        _buildRequirementRow('Pelo menos uma letra minúscula (a-z)', _hasLowercase),
        _buildRequirementRow('Pelo menos um número (0-9)', _hasNumber),
        _buildRequirementRow('Pelo menos um caractere especial (!@#\$...)', _hasSpecialCharacter),
      ],
    );
  }

  // NOVO: Widget para uma única linha de requisito.
  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: met ? Colors.green : Colors.redAccent)),
        ],
      ),
    );
  }
}

