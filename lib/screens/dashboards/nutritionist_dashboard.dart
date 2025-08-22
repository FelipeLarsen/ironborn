import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../patient_management_screen.dart';

class NutritionistDashboard extends StatefulWidget {
  final UserModel user;
  const NutritionistDashboard({super.key, required this.user});

  @override
  State<NutritionistDashboard> createState() => _NutritionistDashboardState();
}

class _NutritionistDashboardState extends State<NutritionistDashboard> {
  final _patientCodeController = TextEditingController();

  // Função para mostrar o diálogo de convite
  void _showInviteDialog() {
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

  // Função para adicionar o paciente no Firestore
  Future<void> _addPatient() async {
    final patientId = _patientCodeController.text.trim();
    if (patientId.isEmpty) return;

    // Usamos o `mounted` para garantir que o widget ainda está na árvore
    if (!mounted) return;

    try {
      // Atualiza o documento do paciente, definindo o nutritionistId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .update({'nutritionistId': widget.user.uid});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Paciente não encontrado ou código inválido.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _patientCodeController.clear();
      Navigator.pop(context); // Fecha o diálogo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, Nutri ${widget.user.name}!'),
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
              label: const Text('Convidar Paciente', style: TextStyle(color: Colors.white)),
              onPressed: _showInviteDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Meus Pacientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('nutritionistId', isEqualTo: widget.user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Ainda não tem pacientes.'));
                  }

                  final patientDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: patientDocs.length,
                    itemBuilder: (context, index) {
                      final patient = UserModel.fromMap(
                          patientDocs[index].data() as Map<String, dynamic>);
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(patient.name[0])),
                          title: Text(patient.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PatientManagementScreen(patient: patient),
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
    );
  }
}