import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/workout_schedule_model.dart';
import '../../models/workout_template_model.dart';
import '../../models/diet_plan_model.dart'; // Importar o novo modelo
import '../daily_workout_screen.dart';
import '../diet_plan_screen.dart'; // Importar a nova tela

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<WorkoutTemplateModel?> _todaysWorkoutFuture;
  late Future<DietPlanModel?> _dietPlanFuture; // Novo Future para a dieta

  @override
  void initState() {
    super.initState();
    _todaysWorkoutFuture = _fetchTodaysWorkout();
    _dietPlanFuture = _fetchDietPlan(); // Chamar a nova função
  }

  Future<WorkoutTemplateModel?> _fetchTodaysWorkout() async {
    // ... (código existente, sem alterações)
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

  // NOVA FUNÇÃO para buscar o plano alimentar
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
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView( // Adicionado para evitar overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card do Treino de Hoje (sem alterações)
            const Text("Treino de Hoje", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<WorkoutTemplateModel?>(
              future: _todaysWorkoutFuture,
              builder: (context, snapshot) {
                // ... (código existente, sem alterações)
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

            // NOVO CARD: Plano Alimentar
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
            
            // Card do Código de Convite (sem alterações)
            const Text("O seu Código de Convite", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: SelectableText(widget.user.uid, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
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