// ARQUIVO ATUALIZADO: lib/screens/dashboards/trainer_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';
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
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    // Ação para o Perfil
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(user: widget.user),
        ),
      );
      return;
    }

    // Ação para os Modelos
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          // CORRIGIDO: Agora a chamada está correta pois o construtor de WorkoutTemplatesScreen aceita o parâmetro.
          builder: (context) => WorkoutTemplatesScreen(trainerId: widget.user.id),
        ),
      );
    }
    
    // Ação para Alunos (apenas muda o estado local se necessário)
    // Se você estiver usando uma PageView, aqui você mudaria o índice.
    // Como não estamos, e a tela de alunos é a 'base', não precisamos de ação para o índice 0.
    if(index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  final _inviteCodeController = TextEditingController();

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
        navigator.pop(); // Fecha o dialog
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Aluno adicionado com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        navigator.pop(); // Fecha o dialog
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Código de convite inválido."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if(navigator.canPop()) navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text("Erro ao adicionar aluno: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
       _inviteCodeController.clear();
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
    // Lista de telas para o corpo principal, se fôssemos usar um PageView ou troca de Body.
    // Por enquanto, a tela de Alunos é a única no corpo.
    final List<Widget> _pages = <Widget>[
      _buildStudentList(), // Corpo principal da tela de alunos
      // A tela de modelos é navegada por cima, então aqui podemos ter um placeholder ou o mesmo widget.
      _buildStudentList(),
      // A tela de perfil também é navegada por cima.
       _buildStudentList(),
    ];
    
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
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Alunos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Modelos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // O corpo sempre mostrará a lista de alunos nesta arquitetura.
      body: _buildStudentList(),
    );
  }

  // NOVO: Widget separado para o corpo da lista de alunos.
  Widget _buildStudentList() {
    return Padding(
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
            'Meus Alunos',
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
                          child:
                              Text(student.name.substring(0, 1).toUpperCase()),
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
    );
  }
}
