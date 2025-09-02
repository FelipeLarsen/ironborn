// ARQUIVO ATUALIZADO: lib/screens/dashboards/nutritionist_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';
import 'package:ironborn/screens/conversations_screen.dart';
import 'package:ironborn/screens/patient_management_screen.dart';
import 'package:ironborn/screens/profile_screen.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class NutritionistDashboard extends StatefulWidget {
  final UserModel user;
  const NutritionistDashboard({super.key, required this.user});

  @override
  State<NutritionistDashboard> createState() => _NutritionistDashboardState();
}

class _NutritionistDashboardState extends State<NutritionistDashboard> {
  final int _selectedIndex = 0; // O índice 0 (Pacientes) é a base deste ecrã.
  final _patientCodeController = TextEditingController();

  void _onItemTapped(int index) {
    // As outras abas navegam para novos ecrãs.
    switch (index) {
      case 0:
        // Já estamos no ecrã de pacientes, não faz nada.
        break;
      case 1: // Mensagens
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ConversationsScreen(),
          ),
        );
        break;
      case 2: // Perfil
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: widget.user),
          ),
        );
        break;
    }
  }

  void _showInviteDialog() {
    _patientCodeController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Convidar Paciente'),
          content: TextField(
            controller: _patientCodeController,
            decoration: const InputDecoration(
              labelText: 'Código de Convite do Paciente',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _addPatient,
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPatient() async {
    final patientId = _patientCodeController.text.trim();
    if (patientId.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .update({'nutritionistId': widget.user.id});

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Paciente adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erro: Paciente não encontrado ou código inválido.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      navigator.pop(); // Fecha o diálogo
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: Text('Olá, Nutri ${widget.user.name}!'),
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
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Convidar Paciente',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: _showInviteDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Os meus Pacientes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('nutritionistId', isEqualTo: widget.user.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Ainda não tem pacientes.'),
                    );
                  }

                  final patientDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: patientDocs.length,
                    itemBuilder: (context, index) {
                      final patientDoc = patientDocs[index];
                      final patient = UserModel.fromMap(
                        patientDoc.data() as Map<String, dynamic>,
                        patientDoc.id,
                      );
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(patient.name.isNotEmpty ? patient.name[0] : 'P')),
                          title: Text(patient.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PatientManagementScreen(
                                      patient: patient,
                                      // Passa o modelo do nutri para o próximo ecrã.
                                      nutritionist: widget.user,
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
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Pacientes',
          ),
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

