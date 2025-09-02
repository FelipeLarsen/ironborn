// ARQUIVO ATUALIZADO: lib/screens/workout_templates_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/workout_template_model.dart';
import 'package:ironborn/screens/create_edit_template_screen.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class WorkoutTemplatesScreen extends StatelessWidget {
  final String trainerId;

  const WorkoutTemplatesScreen({super.key, required this.trainerId});

  // NOVO: Função para apagar o modelo de treino.
  Future<void> _deleteTemplate(String templateId) async {
    await FirebaseFirestore.instance
        .collection('workoutTemplates')
        .doc(templateId)
        .delete();
    // NOTA: Também seria ideal apagar a referência a este template
    // nas agendas de treino dos alunos, mas isso é uma lógica mais complexa (Cloud Function).
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: const Text('Meus Modelos de Treino'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateEditTemplateScreen(),
            ),
          );
        },
        label: const Text('Novo Modelo'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workoutTemplates')
            .where('trainerId', isEqualTo: trainerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Ocorreu um erro."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhum modelo de treino criado."));
          }

          final templates = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final templateData =
                  templates[index].data() as Map<String, dynamic>;
              final template =
                  WorkoutTemplateModel.fromMap(templateData, templates[index].id);

              // ALTERADO: O Card agora está envolvido por um Dismissible.
              return Dismissible(
                key: Key(template.id), // Chave única para identificar o item.
                direction: DismissDirection.endToStart, // Arrastar da direita para a esquerda.
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                // NOVO: Pede confirmação antes de apagar.
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: const Text(
                            "Tem certeza de que deseja apagar este modelo? Esta ação não pode ser desfeita."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("CANCELAR"),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("APAGAR"),
                          ),
                        ],
                      );
                    },
                  );
                },
                // NOVO: Ação a ser executada após a confirmação.
                onDismissed: (direction) {
                  _deleteTemplate(template.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${template.name} apagado."),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(template.name),
                    subtitle: Text("${template.exercises.length} exercícios"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateEditTemplateScreen(template: template),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

