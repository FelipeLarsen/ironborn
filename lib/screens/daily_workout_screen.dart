import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/daily_log_model.dart';
import '../models/workout_template_model.dart';

class DailyWorkoutScreen extends StatelessWidget {
  final WorkoutTemplateModel workout;

  const DailyWorkoutScreen({super.key, required this.workout});

  // Função para obter o ID do documento de log de hoje
  String _getTodayLogDocId() {
    final user = FirebaseAuth.instance.currentUser!;
    final now = DateTime.now();
    return '${user.uid}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Função para marcar o treino como concluído
  Future<void> _finishWorkout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final logDocId = _getTodayLogDocId();
    final logRef = FirebaseFirestore.instance.collection('dailyLogs').doc(logDocId);

    final logData = DailyLogModel(
      studentId: user.uid,
      date: Timestamp.now(),
      workoutCompleted: true,
    );

    try {
      await logRef.set(logData.toMap(), SetOptions(merge: true));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino finalizado com sucesso!'), backgroundColor: Colors.green),
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
              title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${exercise.sets} séries x ${exercise.reps} reps'),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => _finishWorkout(context), // Chama a nova função
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepOrange,
          ),
          child: const Text('Finalizar Treino', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}