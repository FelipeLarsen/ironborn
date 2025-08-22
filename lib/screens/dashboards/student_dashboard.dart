import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/daily_log_model.dart';
import '../../models/diet_plan_model.dart';
import '../../models/user_model.dart';
import '../../models/workout_schedule_model.dart';
import '../../models/workout_template_model.dart';
import '../daily_workout_screen.dart';
import '../diet_plan_screen.dart';
import '../profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<WorkoutTemplateModel?> _todaysWorkoutFuture;
  late Future<DietPlanModel?> _dietPlanFuture;
  final _weightController = TextEditingController(); // Controller para o peso

  @override
  void initState() {
    super.initState();
    _todaysWorkoutFuture = _fetchTodaysWorkout();
    _dietPlanFuture = _fetchDietPlan();
  }

  // Função para obter o ID do documento de log de hoje (ou criar um se não existir)
  String _getTodayLogDocId() {
    final now = DateTime.now();
    // Formato AAAA-MM-DD garante um ID único por dia
    return '${widget.user.uid}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Função para salvar o peso
  Future<void> _saveWeight() async {
    final weightText = _weightController.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(weightText);

    if (weight == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um peso válido.')),
      );
      return;
    }

    final logDocId = _getTodayLogDocId();
    final logRef = FirebaseFirestore.instance.collection('dailyLogs').doc(logDocId);

    final logData = DailyLogModel(
      studentId: widget.user.uid,
      date: Timestamp.now(),
      bodyWeightKg: weight,
    );

    try {
      // Usamos `set` com `merge: true` para criar ou atualizar o documento sem sobrescrever outros campos
      await logRef.set(logData.toMap(), SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso salvo com sucesso!'), backgroundColor: Colors.green),
      );
      _weightController.clear(); // Limpa o campo
      FocusScope.of(context).unfocus(); // Esconde o teclado
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o peso: $e')),
      );
    }
  }

  Future<WorkoutTemplateModel?> _fetchTodaysWorkout() async {
    try {
      final scheduleSnapshot = await FirebaseFirestore.instance
          .collection('workoutSchedules')
          .where('studentId', isEqualTo: widget.user.uid)
          .limit(1)
          .get();

      if (scheduleSnapshot.docs.isEmpty) return null;

      final schedule = WorkoutScheduleModel.fromSnapshot(scheduleSnapshot.docs.first);
      final today = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
      final templateId = schedule.dailyPlan[today];

      if (templateId == null) return null;

      final templateDoc = await FirebaseFirestore.instance
          .collection('workoutTemplates')
          .doc(templateId)
          .get();

      if (!templateDoc.exists) return null;

      return WorkoutTemplateModel.fromSnapshot(templateDoc);
    } catch (e) {
      print("Erro ao buscar treino do dia: $e");
      return null;
    }
  }

  Future<DietPlanModel?> _fetchDietPlan() async {
    try {
      final planSnapshot = await FirebaseFirestore.instance
          .collection('dietPlans')
          .where('patientId', isEqualTo: widget.user.uid)
          .limit(1)
          .get();

      if (planSnapshot.docs.isEmpty) return null;

      return DietPlanModel.fromSnapshot(planSnapshot.docs.first);
    } catch (e) {
      print("Erro ao buscar plano alimentar: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${widget.user.name}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
            );
          },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card do Treino de Hoje
            const Text("Treino de Hoje", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<WorkoutTemplateModel?>(
              future: _todaysWorkoutFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final workout = snapshot.data;
                return Card(
                  child: workout == null
                      ? const ListTile(title: Text("Dia de Descanso!"), subtitle: Text("Aproveite para se recuperar."))
                      : ListTile(
                          title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${workout.exercises.length} exercícios para hoje."),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DailyWorkoutScreen(workout: workout)));
                          },
                        ),
                );
              },
            ),
            const SizedBox(height: 24),

            // CARD: Plano Alimentar
            const Text("Plano Alimentar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<DietPlanModel?>(
              future: _dietPlanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final dietPlan = snapshot.data;
                return Card(
                  child: dietPlan == null
                      ? const ListTile(title: Text("Nenhum plano alimentar atribuído."))
                      : ListTile(
                          title: Text(dietPlan.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Meta: ${dietPlan.calories} kcal"),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DietPlanScreen(dietPlan: dietPlan)));
                          },
                        ),
                );
              },
            ),
            const SizedBox(height: 24),

            // CARD: Registo de Peso Funcional
            const Text("Registo Diário", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Seu peso hoje (kg)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _saveWeight,
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card do Código de Convite
            const Text("O seu Código de Convite", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: SelectableText(
                  widget.user.uid,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.user.uid));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}