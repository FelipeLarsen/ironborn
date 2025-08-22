import 'package:flutter/material.dart';
import '../models/diet_plan_model.dart';

class DietPlanScreen extends StatelessWidget {
  final DietPlanModel dietPlan;

  const DietPlanScreen({super.key, required this.dietPlan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dietPlan.planName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card de Metas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metas Diárias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Calorias: ${dietPlan.calories} kcal'),
                  Text('Proteínas: ${dietPlan.protein} g'),
                  Text('Carboidratos: ${dietPlan.carbs} g'),
                  Text('Gorduras: ${dietPlan.fat} g'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de Refeições
          ...dietPlan.meals.map((meal) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ExpansionTile(
                title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(meal.time),
                children: meal.foods.map((food) {
                  return ListTile(
                    title: Text(food.description),
                    trailing: Text(food.quantity),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}