import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../student_management_screen.dart';
import '../workout_templates_screen.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';

class TrainerDashboard extends StatefulWidget {
  final UserModel user;
  const TrainerDashboard({super.key, required this.user});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  final _studentCodeController = TextEditingController();

  // Função para mostrar o diálogo de convite
  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Convidar Aluno'),
          content: TextField(
            controller: _studentCodeController,
            decoration: const InputDecoration(
              labelText: 'Código de Convite do Aluno',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _addStudent,
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  // Função para adicionar o aluno no Firestore
  Future<void> _addStudent() async {
    final studentId = _studentCodeController.text.trim();
    if (studentId.isEmpty) return;

    try {
      // Atualiza o documento do aluno, definindo o trainerId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .update({'trainerId': widget.user.uid});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aluno adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Aluno não encontrado ou código inválido.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _studentCodeController.clear();
      Navigator.pop(context); // Fecha o diálogo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, Treinador ${widget.user.name}!'),
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
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Convidar Aluno',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _showInviteDialog, // Chama o diálogo
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Meus Alunos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              // StreamBuilder para ouvir as atualizações da lista de alunos em tempo real
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('trainerId', isEqualTo: widget.user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Ainda não tem alunos.'));
                  }

                  final studentDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: studentDocs.length,
                    itemBuilder: (context, index) {
                      final student = UserModel.fromMap(
                        studentDocs[index].data() as Map<String, dynamic>,
                      );
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(student.name[0])),
                          title: Text(student.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentManagementScreen(student: student),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Alunos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Modelos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex:
            0, // Pode manter 0 ou gerir o estado para refletir a tela atual
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkoutTemplatesScreen(),
              ),
            );
          } else if (index == 2) {
            // Se o item 'Perfil' for clicado
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: widget.user),
              ),
            );
          }
        },
      ),
    );
  }
}
