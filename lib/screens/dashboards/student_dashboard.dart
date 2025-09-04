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
import 'package:ironborn/screens/find_professionals_screen.dart'; // NOVO: Importar
import 'package:ironborn/screens/profile_screen.dart';
import 'package:ironborn/screens/progress_screen.dart';
import 'package:ironborn/services/chat_service.dart';
import 'package:ironborn/utils/helpers.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<WorkoutTemplateModel?> _todaysWorkoutFuture;
  late Future<DietPlanModel?> _dietPlanFuture;
  late Future<List<UserModel?>> _professionalsFuture;

  @override
  void initState() {
    super.initState();
    _todaysWorkoutFuture = _fetchTodaysWorkout();
    _dietPlanFuture = _fetchDietPlan();
    final trainerFuture = _fetchProfessional(widget.user.trainerId);
    final nutritionistFuture = _fetchProfessional(widget.user.nutritionistId);
    _professionalsFuture = Future.wait([trainerFuture, nutritionistFuture]);
  }

  Future<UserModel?> _fetchProfessional(String? professionalId) async {
    if (professionalId == null || professionalId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(professionalId).get();
      if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint("Erro ao buscar profissional $professionalId: $e");
    }
    return null;
  }

  void _startChatWithProfessional(UserModel professional) async {
    final chatService = ChatService();
    try {
      final conversationId = await chatService.getOrCreateConversation(widget.user, professional);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não foi possível iniciar a conversa.")));
      }
    }
  }

  Future<void> _saveWeight(String weightText) async {
    final formattedText = weightText.trim().replaceAll(',', '.');
    final weight = double.tryParse(formattedText);

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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user))),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ResponsiveLayout(
        body: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return FutureBuilder<WorkoutTemplateModel?>(
                  future: _todaysWorkoutFuture,
                  builder: (context, snapshot) {
                     return _DashboardGridCard(
                      icon: Icons.fitness_center,
                      title: snapshot.data?.name ?? 'Descanso',
                      subtitle: snapshot.data != null ? '${snapshot.data!.exercises.length} exercícios' : 'Sem treino hoje',
                      onTap: snapshot.data != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => DailyWorkoutScreen(workout: snapshot.data!))) : null,
                      isLoading: snapshot.connectionState == ConnectionState.waiting,
                    );
                  }
                );
              case 1:
                return FutureBuilder<DietPlanModel?>(
                  future: _dietPlanFuture,
                  builder: (context, snapshot) {
                    return _DashboardGridCard(
                      icon: Icons.restaurant_menu,
                      title: snapshot.data?.planName ?? 'Sem Plano',
                      subtitle: snapshot.data != null ? '${snapshot.data!.calories} kcal' : 'Fale com o seu nutri',
                      onTap: snapshot.data != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => DietPlanScreen(dietPlan: snapshot.data!))) : null,
                      isLoading: snapshot.connectionState == ConnectionState.waiting,
                    );
                  }
                );
              case 2:
                return _DashboardGridCard(
                  icon: Icons.show_chart,
                  title: 'O meu Progresso',
                  subtitle: 'Ver evolução',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProgressScreen(userId: widget.user.id, userName: widget.user.name))),
                );
              case 3:
                return FutureBuilder<List<UserModel?>>(
                  future: _professionalsFuture,
                  builder: (context, snapshot) {
                    final trainer = snapshot.data?[0];
                    final nutritionist = snapshot.data?[1];
                    return _DashboardGridCard(
                      icon: Icons.chat,
                      title: 'Conversas',
                      subtitle: trainer != null || nutritionist != null ? 'Fale com os seus prós' : 'Nenhum profissional',
                      onTap: trainer != null || nutritionist != null ? () => _showProfessionalsDialog(trainer, nutritionist) : null,
                      isLoading: snapshot.connectionState == ConnectionState.waiting,
                    );
                  }
                );
              case 4:
                return _DashboardGridCard(
                  icon: Icons.edit,
                  title: 'Registo Diário',
                  subtitle: 'Toque para registar o peso',
                  onTap: () => _showWeightLogDialog(),
                );
              case 5:
                return _InviteCodeCard(inviteCode: widget.user.id);
              case 6:
                return _DashboardGridCard(
                  icon: Icons.search,
                  title: "Encontrar Profissionais",
                  subtitle: "Procure treinadores e nutris",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => FindProfessionalsScreen(currentUser: widget.user)));
                  },
                );
              case 7:
                 return const Card(
                   color: Colors.transparent,
                   elevation: 0,
                 );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  void _showWeightLogDialog() {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registar Peso Diário"),
        content: TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'O seu peso hoje (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _saveWeight(weightController.text);
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _showProfessionalsDialog(UserModel? trainer, UserModel? nutritionist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Iniciar Conversa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (trainer != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startChatWithProfessional(trainer);
                },
                child: Text(trainer.name),
              ),
            if (nutritionist != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startChatWithProfessional(nutritionist);
                },
                child: Text(nutritionist.name),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardGridCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? child;

  const _DashboardGridCard({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.onTap,
    this.isLoading = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 24, color: onTap != null || child != null ? Colors.deepOrange : Colors.grey),
                  if (onTap != null && child == null)
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
                ],
              ),
              const Spacer(),
              if (isLoading)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else if (child != null)
                Expanded(child: child!)
              else ...[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;

  const _InviteCodeCard({required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return _DashboardGridCard(
      icon: Icons.qr_code,
      title: 'Código de Convite',
      onTap: () {
        Clipboard.setData(ClipboardData(text: inviteCode));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
      },
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SelectableText(
                inviteCode,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado!')));
            },
          ),
        ],
      ),
    );
  }
}

