import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/workout_template_model.dart';
import 'create_edit_template_screen.dart';

class WorkoutTemplatesScreen extends StatelessWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Utilizador não encontrado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Modelos de Treino'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('workoutTemplates')
            .where('creatorId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum modelo de treino criado ainda.'));
          }

          final templates = snapshot.data!.docs
              .map((doc) => WorkoutTemplateModel.fromSnapshot(doc))
              .toList();

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                title: Text(template.name),
                subtitle: Text('${template.exercises.length} exercícios'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditTemplateScreen(template: template),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditTemplateScreen(),
            ),
          );
        },
        label: const Text('Novo Modelo'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}