// ARQUIVO ATUALIZADO: lib/screens/student_management_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironborn/models/daily_log_model.dart';
import 'package:ironborn/models/user_model.dart';
// CORRIGIDO: Caminhos de importação ajustados
import 'package:ironborn/models/workout_schedule_model.dart';
import 'package:ironborn/models/workout_template_model.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class StudentManagementScreen extends StatefulWidget {
  final UserModel student;
  const StudentManagementScreen({super.key, required this.student});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<WorkoutTemplateModel> _templates = [];
  WorkoutScheduleModel _schedule = WorkoutScheduleModel.empty();
  bool _isLoading = true;

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await _fetchTemplates();
    await _fetchSchedule();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTemplates() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('workoutTemplates')
        .where('trainerId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    final templates = snapshot.docs
        .map((doc) =>
            WorkoutTemplateModel.fromMap(doc.data(), doc.id))
        .toList();
    
    if (mounted) {
      setState(() {
        _templates = templates;
      });
    }
  }

  Future<void> _fetchSchedule() async {
    final scheduleDoc = await FirebaseFirestore.instance
        .collection('workoutSchedules')
        .doc(widget.student.id)
        .get();

    if (scheduleDoc.exists && mounted) {
      setState(() {
        _schedule = WorkoutScheduleModel.fromMap(scheduleDoc.data()!, scheduleDoc.id);
      });
    }
  }

  Future<void> _saveSchedule() async {
    final scheduleToSave = _schedule.copyWith();

    final scheduleRef = FirebaseFirestore.instance
        .collection('workoutSchedules')
        .doc(widget.student.id);

    await scheduleRef.set(scheduleToSave.toMap());

    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Agenda salva com sucesso!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _translateDay(String day) {
    const translations = {
      'monday': 'Segunda-feira',
      'tuesday': 'Terça-feira',
      'wednesday': 'Quarta-feira',
      'thursday': 'Quinta-feira',
      'friday': 'Sexta-feira',
      'saturday': 'Sábado',
      'sunday': 'Domingo'
    };
    return translations[day] ?? day;
  }

  Widget _buildDaySelector(String day) {
    final items = [
      const DropdownMenuItem<String>(
        value: null,
        child: Text("Nenhum / Descanso"),
      ),
      ..._templates.map((template) {
        return DropdownMenuItem<String>(
          value: template.id,
          child: Text(template.name),
        );
      }),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_translateDay(day), style: const TextStyle(fontSize: 16)),
          DropdownButton<String>(
            value: _schedule.weeklySchedule[day],
            items: items,
            onChanged: (String? newValue) {
              setState(() {
                final newWeeklySchedule = Map<String, String?>.from(_schedule.weeklySchedule);
                newWeeklySchedule[day] = newValue;
                _schedule = _schedule.copyWith(weeklySchedule: newWeeklySchedule);
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: Text('A gerir: ${widget.student.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Agenda de Treinos da Semana",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ..._daysOfWeek.map((day) => _buildDaySelector(day)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveSchedule,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text("Salvar Agenda"),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildHistorySection(),
              ],
            ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Histórico Recente",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dailyLogs')
                  .where('studentId', isEqualTo: widget.student.id)
                  .orderBy('date', descending: true)
                  .limit(15)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Nenhum registo de log encontrado."),
                    ),
                  );
                }

                final logDocs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logDocs.length,
                  itemBuilder: (context, index) {
                    final log = DailyLogModel.fromSnapshot(logDocs[index]);
                    return _buildLogTile(log);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(DailyLogModel log) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(log.date.toDate());
    final bool workoutCompleted = log.workoutCompleted ?? false;
    
    return ListTile(
      leading: Icon(
        workoutCompleted ? Icons.check_circle : Icons.cancel,
        color: workoutCompleted ? Colors.green : Colors.redAccent,
      ),
      title: Text("Treino ${workoutCompleted ? 'Concluído' : 'Não Concluído'}"),
      subtitle: Text(formattedDate),
      trailing: log.bodyWeightKg != null
        ? Text(
            "${log.bodyWeightKg} kg",
            style: const TextStyle(fontWeight: FontWeight.bold),
          )
        : null,
    );
  }
}

