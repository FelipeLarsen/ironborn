// ARQUIVO ATUALIZADO: lib/screens/dashboards/student_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironborn/models/daily_log_model.dart';
import 'package:ironborn/models/diet_plan_model.dart';
import 'package:ironborn/models/user_model.dart';
import 'package:ironborn/models/workout_schedule_model.dart';
import 'package:ironborn/models/workout_template_model.dart';
import 'package:ironborn/screens/chat_screen.dart';
import 'package:ironborn/screens/daily_workout_screen.dart';
import 'package:ironborn/screens/diet_plan_screen.dart';
import 'package:ironborn/screens/profile_screen.dart';
import 'package:ironborn/screens/progress_screen.dart';
import 'package:ironborn/services/chat_service.dart';
import 'package:ironborn/utils/helpers.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<WorkoutTemplateModel?> _todaysWorkoutFuture;
  late Future<DietPlanModel?> _dietPlanFuture;
  final _weightController = TextEditingController();

  // NOVO: Futuros para buscar os modelos dos profissionais para o chat.
  late Future<UserModel?> _trainerFuture;
  late Future<UserModel?> _nutritionistFuture;

  @override
  void initState() {
    super.initState();
    _todaysWorkoutFuture = _fetchTodaysWorkout();
    _dietPlanFuture = _fetchDietPlan();
    // NOVO: Inicia a busca pelos profissionais.
    _trainerFuture = _fetchProfessional(widget.user.trainerId);
    _nutritionistFuture = _fetchProfessional(widget.user.nutritionistId);
  }

  // NOVO: Função genérica para buscar o perfil de um profissional.
  Future<UserModel?> _fetchProfessional(String? professionalId) async {
    if (professionalId == null || professionalId.isEmpty) {
      return null;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(professionalId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint("Erro ao buscar profissional $professionalId: $e");
    }
    return null;
  }

  // NOVO: Função para iniciar o chat com um profissional.
  void _startChatWithProfessional(UserModel professional) async {
    final chatService = ChatService();
    try {
      final conversationId =
          await chatService.getOrCreateConversation(widget.user, professional);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              recipientName: professional.name,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao iniciar chat: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível iniciar a conversa.")),
        );
      }
    }
  }

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

    final logData = DailyLogModel(
      studentId: widget.user.id,
      date: Timestamp.now(),
      bodyWeightKg: weight,
    );

    try {
      await FirebaseFirestore.instance.collection('dailyLogs').add(logData.toMap());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Peso salvo com sucesso!'),
            backgroundColor: Colors.green),
      );
      _weightController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar o peso: $e')),
      );
    }
  }

  Future<WorkoutTemplateModel?> _fetchTodaysWorkout() async {
    if (widget.user.trainerId == null || widget.user.trainerId!.isEmpty) {
      return null;
    }

    try {
      final scheduleDoc = await FirebaseFirestore.instance
          .collection('workoutSchedules')
          .doc(widget.user.id)
          .get();

      if (!scheduleDoc.exists) {
        return null;
      }

      final schedule =
          WorkoutScheduleModel.fromMap(scheduleDoc.data()!, scheduleDoc.id);

      final today = getDayOfWeekInEnglish();

      final templateId = schedule.weeklySchedule[today];

      if (templateId == null) {
        return null;
      }

      final templateDoc = await FirebaseFirestore.instance
          .collection('workoutTemplates')
          .doc(templateId)
          .get();

      if (!templateDoc.exists) {
        return null;
      }

      return WorkoutTemplateModel.fromMap(templateDoc.data()!, templateDoc.id);
    } catch (e) {
      debugPrint("Erro ao buscar treino do dia: $e");
      return null;
    }
  }

  Future<DietPlanModel?> _fetchDietPlan() async {
    if (widget.user.nutritionistId == null ||
        widget.user.nutritionistId!.isEmpty) {
      return null;
    }
    try {
      final planSnapshot = await FirebaseFirestore.instance
          .collection('dietPlans')
          .where('patientId', isEqualTo: widget.user.id)
          .limit(1)
          .get();

      if (planSnapshot.docs.isEmpty) return null;

      final doc = planSnapshot.docs.first;
      return DietPlanModel.fromMap(doc.id, doc.data());
    } catch (e) {
      debugPrint("Erro ao buscar plano alimentar: $e");
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
                MaterialPageRoute(
                    builder: (context) => ProfileScreen(user: widget.user)),
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
            // ... (Card do Treino e Card do Plano Alimentar permanecem iguais)
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
                      ? const ListTile(title: Text("Dia de Descanso ou sem treino!"), subtitle: Text("Aproveite para se recuperar ou fale com o seu treinador."))
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
                      ? const ListTile(title: Text("Nenhum plano alimentar atribuído."), subtitle: Text("Fale com o seu nutricionista."))
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
            
            // NOVO CARD: Conversas com Profissionais
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Fale com os seus Profissionais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    FutureBuilder<UserModel?>(
                      future: _trainerFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final trainer = snapshot.data!;
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.fitness_center),
                          label: Text("Conversar com ${trainer.name}"),
                          onPressed: () => _startChatWithProfessional(trainer),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                     FutureBuilder<UserModel?>(
                      future: _nutritionistFuture,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final nutritionist = snapshot.data!;
                        return OutlinedButton.icon(
                          icon: const Icon(Icons.restaurant_menu),
                          label: Text("Conversar com ${nutritionist.name}"),
                          onPressed: () => _startChatWithProfessional(nutritionist),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              child: ListTile(
                leading: const Icon(Icons.show_chart, color: Colors.deepOrange),
                title: const Text("Ver o meu Progresso", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ProgressScreen(
                      userId: widget.user.id,
                      userName: widget.user.name,
                    ),
                  ));
                },
              ),
            ),
            const SizedBox(height: 24),

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
                        decoration: const InputDecoration(labelText: 'O seu peso hoje (kg)'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(onPressed: _saveWeight, child: const Text('Salvar')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text("O seu Código de Convite", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: SelectableText(
                  widget.user.id,
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.user.id));
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

