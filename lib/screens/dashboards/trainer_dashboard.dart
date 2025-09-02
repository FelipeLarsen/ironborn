// ARQUIVO ATUALIZADO: lib/screens/dashboards/trainer_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';
import 'package:ironborn/screens/conversations_screen.dart';
import 'package:ironborn/screens/student_management_screen.dart';
import 'package:ironborn/screens/workout_templates_screen.dart';
import 'package:ironborn/screens/profile_screen.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class TrainerDashboard extends StatefulWidget {
  final UserModel user;
  const TrainerDashboard({super.key, required this.user});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  // O índice 0 (Alunos) é a base deste ecrã.
  final int _selectedIndex = 0;
  final _inviteCodeController = TextEditingController();

  void _onItemTapped(int index) {
    // As outras abas navegam para novos ecrãs.
    switch (index) {
      case 0:
        // Já estamos no ecrã de alunos, não faz nada.
        break;
      case 1: // Modelos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WorkoutTemplatesScreen(trainerId: widget.user.id),
          ),
        );
        break;
      case 2: // Mensagens
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ConversationsScreen(),
          ),
        );
        break;
      case 3: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: widget.user),
          ),
        );
        break;
    }
  }

  Future<void> _addStudent() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final studentDoc =
          FirebaseFirestore.instance.collection('users').doc(code);
      final docSnapshot = await studentDoc.get();

      if (docSnapshot.exists) {
        await studentDoc.update({'trainerId': widget.user.id});
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Aluno adicionado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Código de convite inválido."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text("Erro ao adicionar aluno: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showInviteDialog() {
    _inviteCodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Convidar Aluno"),
        content: TextField(
          controller: _inviteCodeController,
          decoration:
              const InputDecoration(hintText: "Insira o código do aluno"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _addStudent,
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: Text('Olá, ${widget.user.name}!'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _showInviteDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Convidar Aluno'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Os meus Alunos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('trainerId', isEqualTo: widget.user.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Ocorreu um erro."));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Ainda não tem alunos."));
                  }

                  final students = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final studentData =
                          students[index].data() as Map<String, dynamic>;
                      final student =
                          UserModel.fromMap(studentData, students[index].id);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                                student.name.isNotEmpty ? student.name[0] : '?'),
                          ),
                          title: Text(student.name),
                          subtitle:
                              const Text("Ver progresso e gerir treinos"),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => StudentManagementScreen(
                                  student: student,
                                  // NOVO: Passa o modelo do treinador para o próximo ecrã.
                                  trainer: widget.user,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Garante que todos os itens aparecem
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Alunos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Modelos',
          ),
          // NOVO ITEM
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Mensagens',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

