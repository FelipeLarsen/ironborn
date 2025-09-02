// ARQUIVO ATUALIZADO: lib/models/daily_log_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel {
  final String? id;
  final String studentId;
  final Timestamp date;
  final double? bodyWeightKg;
  final bool? workoutCompleted;

  const DailyLogModel({ // ADICIONADO: construtor const
    this.id,
    required this.studentId,
    required this.date,
    this.bodyWeightKg,
    this.workoutCompleted,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'studentId': studentId,
      'date': date,
    };
    if (bodyWeightKg != null) map['bodyWeightKg'] = bodyWeightKg;
    if (workoutCompleted != null) map['workoutCompleted'] = workoutCompleted;
    return map;
  }

  // NOVO: Factory constructor para criar um objeto a partir de um DocumentSnapshot.
  factory DailyLogModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyLogModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      bodyWeightKg: data['bodyWeightKg'],
      workoutCompleted: data['workoutCompleted'],
    );
  }
}
