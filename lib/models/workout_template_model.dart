// ARQUIVO ATUALIZADO: lib/models/workout_template_model.dart

class Exercise {
  // ALTERADO: Adicionado 'final' para imutabilidade.
  final String name;
  final String sets;
  final String reps;

  // ALTERADO: Construtor agora é 'const'.
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
  });
  
  // NOVO: copyWith para atualizações imutáveis em formulários.
  Exercise copyWith({String? name, String? sets, String? reps}) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      sets: map['sets'] ?? '',
      reps: map['reps'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
    };
  }
}

class WorkoutTemplateModel {
  final String id;
  final String name;
  final String trainerId;
  final List<Exercise> exercises;

  // ALTERADO: Construtor agora é 'const'.
  const WorkoutTemplateModel({
    required this.id,
    required this.name,
    required this.trainerId,
    required this.exercises,
  });

  // NOVO: copyWith para atualizações imutáveis.
  WorkoutTemplateModel copyWith({
    String? id,
    String? name,
    String? trainerId,
    List<Exercise>? exercises,
  }) {
    return WorkoutTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      trainerId: trainerId ?? this.trainerId,
      exercises: exercises ?? this.exercises,
    );
  }

  factory WorkoutTemplateModel.fromMap(Map<String, dynamic> map, String id) {
    return WorkoutTemplateModel(
      id: id,
      name: map['name'] ?? '',
      trainerId: map['trainerId'] ?? '',
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trainerId': trainerId,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}