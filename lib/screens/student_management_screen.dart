import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/workout_template_model.dart';
import '../models/workout_schedule_model.dart';

class StudentManagementScreen extends StatefulWidget {
  final UserModel student;
  const StudentManagementScreen({super.key, required this.student});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<WorkoutTemplateModel> _templates = [];
  WorkoutScheduleModel? _schedule;
  Map<String, String?> _selectedPlans = {};
  bool _isLoading = true;

  final List<String> _daysOfWeek = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  final Map<String, String> _daysOfWeekPortuguese = {
    'monday': 'Segunda-feira', 'tuesday': 'Terça-feira', 'wednesday': 'Quarta-feira',
    'thursday': 'Quinta-feira', 'friday': 'Sexta-feira', 'saturday': 'Sábado', 'sunday': 'Domingo'
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final trainerId = FirebaseAuth.instance.currentUser!.uid;

    // Buscar os modelos de treino do treinador
    final templatesSnapshot = await FirebaseFirestore.instance
        .collection('workoutTemplates')
        .where('creatorId', isEqualTo: trainerId)
        .get();
    final templates = templatesSnapshot.docs
        .map((doc) => WorkoutTemplateModel.fromSnapshot(doc))
        .toList();

    // Buscar a agenda do aluno
    final scheduleSnapshot = await FirebaseFirestore.instance
        .collection('workoutSchedules')
        .where('studentId', isEqualTo: widget.student.uid)
        .limit(1)
        .get();

    WorkoutScheduleModel? schedule;
    if (scheduleSnapshot.docs.isNotEmpty) {
      schedule = WorkoutScheduleModel.fromSnapshot(scheduleSnapshot.docs.first);
    }

    setState(() {
      _templates = templates;
      _schedule = schedule;
      _selectedPlans = Map.from(schedule?.dailyPlan ?? {});
      _isLoading = false;
    });
  }

  Future<void> _saveSchedule() async {
    final trainerId = FirebaseAuth.instance.currentUser!.uid;

    final newSchedule = WorkoutScheduleModel(
      id: _schedule?.id,
      studentId: widget.student.uid,
      trainerId: trainerId,
      dailyPlan: _selectedPlans,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('workoutSchedules');
      if (newSchedule.id == null) {
        await collection.add(newSchedule.toMap());
      } else {
        await collection.doc(newSchedule.id).update(newSchedule.toMap());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agenda salva com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a agenda: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('A gerir: ${widget.student.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Agenda de Treinos da Semana', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ..._daysOfWeek.map((day) => _buildDaySelector(day)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveSchedule,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.deepOrange,
                        ),
                        child: const Text('Salvar Agenda', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDaySelector(String day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_daysOfWeekPortuguese[day]!, style: const TextStyle(fontSize: 16)),
          DropdownButton<String?>(
            value: _selectedPlans[day],
            hint: const Text('Selecionar'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Nenhum / Descanso'),
              ),
              ..._templates.map((template) {
                return DropdownMenuItem<String?>(
                  value: template.id,
                  child: Text(template.name),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPlans[day] = value;
              });
            },
          ),
        ],
      ),
    );
  }
}