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
  final int _selectedIndex = 0;
  final _inviteCodeController = TextEditingController();

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WorkoutTemplatesScreen(trainerId: widget.user.id),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ConversationsScreen(),
          ),
        );
        break;
      case 3:
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
      // ALTERADO: O body agora tem um layout mais estruturado.
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('trainerId', isEqualTo: widget.user.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(heightFactor: 5, child: Text("Ainda não tem alunos."))
                  );
                }

                final students = snapshot.data!.docs;
                // ALTERADO: A lista agora é uma SliverGrid para o layout em cartões.
                return SliverGrid.builder(
                   gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 4 / 1, // Proporção mais horizontal
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final studentData = students[index].data() as Map<String, dynamic>;
                    final student = UserModel.fromMap(studentData, students[index].id);

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StudentManagementScreen(
                                student: student,
                                trainer: widget.user,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Text("Gerir treinos e progresso", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Alunos'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Modelos'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Mensagens'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

