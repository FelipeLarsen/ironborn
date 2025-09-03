// ARQUIVO ATUALIZADO: lib/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ironborn/screens/register_screen.dart';
import 'package:ironborn/widgets/noise_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          errorMessage = 'Nenhum utilizador encontrado com este e-mail.';
          break;
        case 'wrong-password':
          errorMessage = 'A senha está incorreta. Por favor, tente novamente.';
          break;
        case 'invalid-credential':
           errorMessage = 'As credenciais estão incorretas. Verifique o e-mail e a senha.';
           break;
        default:
          errorMessage = 'Ocorreu um erro. Verifique a sua conexão.';
      }
      _showErrorSnackbar(errorMessage);

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Recuperar Senha"),
        content: TextField(
          controller: emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: "Insira o seu e-mail"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text("Enviar"),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackbar("E-mail de recuperação enviado para $email. Verifique a sua caixa de entrada.");
    } on FirebaseAuthException catch (e) {
      _showErrorSnackbar(e.message ?? "Ocorreu um erro ao enviar o e-mail.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRegisterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }
  
  void _showSnackbar(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const NoiseBackground(opacity: 0.05),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'IRONBORN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.protestStrike(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Por favor, insira o seu e-mail.' : null,
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
                        validator: (value) => value!.isEmpty ? 'Por favor, insira a sua senha.' : null,
                      ),
                      const SizedBox(height: 24), // Espaçamento aumentado
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.deepOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                      const SizedBox(height: 24), // Espaçamento aumentado

                      // ALTERADO: A estrutura dos botões secundários foi refeita.
                      Column(
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : _resetPassword,
                            child: const Text(
                              "Esqueci a minha senha",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const Divider(
                            color: Colors.white24,
                            thickness: 1,
                            indent: 40,
                            endIndent: 40,
                          ),
                           TextButton(
                            onPressed: _isLoading ? null : _navigateToRegisterScreen,
                            child: const Text(
                              'Não tem uma conta? Cadastre-se',
                              style: TextStyle(color: Colors.deepOrangeAccent),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

