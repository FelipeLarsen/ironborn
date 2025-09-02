// ARQUIVO ATUALIZADO: lib/models/workout_schedule_model.dart

class WorkoutScheduleModel {
  final String id;
  // ALTERADO: Adicionado 'final' para imutabilidade.
  final Map<String, String?> weeklySchedule;

  // ALTERADO: Construtor agora é 'const'.
  const WorkoutScheduleModel({
    required this.id,
    required this.weeklySchedule,
  });

  // NOVO: copyWith para atualizações imutáveis.
  WorkoutScheduleModel copyWith({
    String? id,
    Map<String, String?>? weeklySchedule,
  }) {
    return WorkoutScheduleModel(
      id: id ?? this.id,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
    );
  }

  factory WorkoutScheduleModel.empty() {
    return const WorkoutScheduleModel( // ALTERADO para const
      id: '',
      weeklySchedule: {
        'monday': null,
        'tuesday': null,
        'wednesday': null,
        'thursday': null,
        'friday': null,
        'saturday': null,
        'sunday': null,
      },
    );
  }

  factory WorkoutScheduleModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return WorkoutScheduleModel(
      id: documentId,
      weeklySchedule: Map<String, String?>.from(map['weeklySchedule'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklySchedule': weeklySchedule,
    };
  }
}