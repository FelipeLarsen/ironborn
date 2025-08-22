// ARQUIVO: lib/models/workout_template_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para representar um exercício dentro de um template
class Exercise {
  final String name;
  final String sets;
  final String reps;

  Exercise({required this.name, required this.sets, required this.reps});

  // Converte um objeto Exercise para um formato que o Firestore entende (um Map).
  Map<String, dynamic> toMap() {
    return {'name': name, 'sets': sets, 'reps': reps};
  }

  // Cria um objeto Exercise a partir de um Map (vindo do Firestore).
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      sets: map['sets'] ?? '',
      reps: map['reps'] ?? '',
    );
  }
}

// Modelo para representar um template de treino completo
class WorkoutTemplateModel {
  final String? id; // O ID do documento no Firestore
  final String creatorId; // O UID do treinador que o criou
  final String name;
  final List<Exercise> exercises;

  WorkoutTemplateModel({
    this.id,
    required this.creatorId,
    required this.name,
    required this.exercises,
  });

  // Converte o objeto completo para um Map para ser salvo no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  // Cria um objeto WorkoutTemplateModel a partir de um DocumentSnapshot do Firestore.
  factory WorkoutTemplateModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplateModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      name: data['name'] ?? '',
      // Converte a lista de Maps de exercícios de volta para uma lista de objetos Exercise.
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
