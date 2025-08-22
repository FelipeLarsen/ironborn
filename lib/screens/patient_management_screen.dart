import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/diet_plan_model.dart';

class PatientManagementScreen extends StatefulWidget {
  final UserModel patient;
  const PatientManagementScreen({super.key, required this.patient});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  DietPlanModel? _dietPlan;
  bool _isLoading = true;

  // Controllers
  final _planNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _fetchDietPlan();
  }

  @override
  void dispose() {
    // Limpar todos os controllers para evitar memory leaks
    _planNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _fetchDietPlan() async {
    final planSnapshot = await FirebaseFirestore.instance
        .collection('dietPlans')
        .where('patientId', isEqualTo: widget.patient.uid)
        .limit(1)
        .get();

    if (planSnapshot.docs.isNotEmpty) {
      final plan = DietPlanModel.fromSnapshot(planSnapshot.docs.first);
      setState(() {
        _dietPlan = plan;
        _planNameController.text = plan.planName;
        _caloriesController.text = plan.calories.toString();
        _proteinController.text = plan.protein.toString();
        _carbsController.text = plan.carbs.toString();
        _fatController.text = plan.fat.toString();
        _meals = List.from(plan.meals);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveDietPlan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final nutritionistId = FirebaseAuth.instance.currentUser!.uid;
    final newPlan = DietPlanModel(
      id: _dietPlan?.id,
      patientId: widget.patient.uid,
      nutritionistId: nutritionistId,
      planName: _planNameController.text,
      calories: int.tryParse(_caloriesController.text) ?? 0,
      protein: int.tryParse(_proteinController.text) ?? 0,
      carbs: int.tryParse(_carbsController.text) ?? 0,
      fat: int.tryParse(_fatController.text) ?? 0,
      meals: _meals,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('dietPlans');
      if (newPlan.id == null) {
        await collection.add(newPlan.toMap());
      } else {
        await collection.doc(newPlan.id).update(newPlan.toMap());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plano salvo com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _addMeal() {
    setState(() {
      _meals.add(Meal(name: '', time: '', foods: []));
    });
  }

  void _removeMeal(int mealIndex) {
    setState(() {
      _meals.removeAt(mealIndex);
    });
  }

  void _addFoodToMeal(int mealIndex) {
    setState(() {
      _meals[mealIndex].foods.add(FoodItem(description: '', quantity: ''));
    });
  }

  void _removeFoodFromMeal(int mealIndex, int foodIndex) {
    setState(() {
      _meals[mealIndex].foods.removeAt(foodIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('A gerir: ${widget.patient.name}'),
        actions: [
          if (_isLoading) const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white))
          else IconButton(icon: const Icon(Icons.save), onPressed: _saveDietPlan),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(controller: _planNameController, decoration: const InputDecoration(labelText: 'Nome do Plano'), validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
                  const SizedBox(height: 16),
                  const Text('Metas Diárias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(controller: _caloriesController, decoration: const InputDecoration(labelText: 'Calorias (kcal)'), keyboardType: TextInputType.number),
                  TextFormField(controller: _proteinController, decoration: const InputDecoration(labelText: 'Proteínas (g)'), keyboardType: TextInputType.number),
                  TextFormField(controller: _carbsController, decoration: const InputDecoration(labelText: 'Carboidratos (g)'), keyboardType: TextInputType.number),
                  TextFormField(controller: _fatController, decoration: const InputDecoration(labelText: 'Gorduras (g)'), keyboardType: TextInputType.number),
                  const SizedBox(height: 24),
                  const Text('Refeições', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._meals.asMap().entries.map((entry) => _buildMealCard(entry.key)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Adicionar Refeição'),
                    onPressed: _addMeal,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMealCard(int mealIndex) {
    final meal = _meals[mealIndex];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: meal.name,
                    onChanged: (value) => meal.name = value,
                    decoration: const InputDecoration(labelText: 'Nome da Refeição'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: meal.time,
                    onChanged: (value) => meal.time = value,
                    decoration: const InputDecoration(labelText: 'Horário (ex: 09:00)'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removeMeal(mealIndex),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Alimentos', style: TextStyle(fontWeight: FontWeight.bold)),
            ...meal.foods.asMap().entries.map((entry) => _buildFoodItemTile(mealIndex, entry.key)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar Alimento'),
                onPressed: () => _addFoodToMeal(mealIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemTile(int mealIndex, int foodIndex) {
    final food = _meals[mealIndex].foods[foodIndex];
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: food.description,
            onChanged: (value) => food.description = value,
            decoration: const InputDecoration(labelText: 'Alimento'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: food.quantity,
            onChanged: (value) => food.quantity = value,
            decoration: const InputDecoration(labelText: 'Quantidade'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: () => _removeFoodFromMeal(mealIndex, foodIndex),
        ),
      ],
    );
  }
}