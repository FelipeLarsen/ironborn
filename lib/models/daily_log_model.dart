import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel {
  final String? id;
  final String studentId;
  final Timestamp date; // Usamos Timestamp para facilitar a ordenação
  final double? bodyWeightKg;
  final bool? workoutCompleted;

  DailyLogModel({
    this.id,
    required this.studentId,
    required this.date,
    this.bodyWeightKg,
    this.workoutCompleted,
  });

  // Converte o objeto para um Map, tratando valores nulos
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'studentId': studentId,
      'date': date,
    };
    if (bodyWeightKg != null) map['bodyWeightKg'] = bodyWeightKg;
    if (workoutCompleted != null) map['workoutCompleted'] = workoutCompleted;
    return map;
  }
}