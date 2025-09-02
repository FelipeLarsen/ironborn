// ARQUIVO ATUALIZADO: lib/screens/daily_workout_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/daily_log_model.dart';
import '../models/workout_template_model.dart';

class DailyWorkoutScreen extends StatelessWidget {
  final WorkoutTemplateModel workout;

  const DailyWorkoutScreen({super.key, required this.workout});

  // ALTERADO: A lógica de 'finalizar treino' agora cria um novo documento.
  Future<void> _finishWorkout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final logCollection = FirebaseFirestore.instance.collection('dailyLogs');

    final logData = DailyLogModel(
      studentId: user.uid,
      date: Timestamp.now(),
      workoutCompleted: true,
      // O peso é nulo porque esta ação apenas regista a conclusão do treino.
      bodyWeightKg: null,
    );

    try {
      // Usa .add() para garantir a criação de um novo registo com ID automático.
      await logCollection.add(logData.toMap());
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Treino finalizado com sucesso!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Volta para o dashboard
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar o treino: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: workout.exercises.length,
        itemBuilder: (context, index) {
          final exercise = workout.exercises[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${exercise.sets} séries x ${exercise.reps} reps'),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => _finishWorkout(context),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepOrange,
          ),
          child: const Text('Finalizar Treino',
              style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}

