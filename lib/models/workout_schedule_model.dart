import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutScheduleModel {
  final String? id;
  final String studentId;
  final String trainerId;
  final Map<String, String?> dailyPlan; // Ex: {'monday': 'templateId1', 'tuesday': null}

  WorkoutScheduleModel({
    this.id,
    required this.studentId,
    required this.trainerId,
    required this.dailyPlan,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'trainerId': trainerId,
      'dailyPlan': dailyPlan,
    };
  }

  factory WorkoutScheduleModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutScheduleModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      trainerId: data['trainerId'] ?? '',
      dailyPlan: Map<String, String?>.from(data['dailyPlan'] ?? {}),
    );
  }
}