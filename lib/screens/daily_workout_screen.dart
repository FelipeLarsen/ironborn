import 'package:flutter/material.dart';
import '../models/workout_template_model.dart';

class DailyWorkoutScreen extends StatelessWidget {
  final WorkoutTemplateModel workout;

  const DailyWorkoutScreen({super.key, required this.workout});

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
      // Botão fixo no rodapé
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implementar a lógica para marcar o treino como concluído
            Navigator.pop(context); // Volta para o dashboard
          },
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