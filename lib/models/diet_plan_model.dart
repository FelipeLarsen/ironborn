import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo para um alimento dentro de uma refeição
class FoodItem {
  String description;
  String quantity;

  FoodItem({required this.description, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'description': description, 'quantity': quantity};
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? '',
    );
  }
}

// Modelo para uma refeição
class Meal {
  String name;
  String time;
  List<FoodItem> foods;

  Meal({required this.name, required this.time, required this.foods});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'foods': foods.map((food) => food.toMap()).toList(),
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      name: map['name'] ?? '',
      time: map['time'] ?? '',
      foods: (map['foods'] as List<dynamic>?)
              ?.map((food) => FoodItem.fromMap(food as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// Modelo para o plano alimentar completo
class DietPlanModel {
  final String? id;
  final String patientId;
  final String nutritionistId;
  final String planName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<Meal> meals;

  DietPlanModel({
    this.id,
    required this.patientId,
    required this.nutritionistId,
    required this.planName,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.meals,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'nutritionistId': nutritionistId,
      'planName': planName,
      'goals': {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      },
      'meals': meals.map((meal) => meal.toMap()).toList(),
    };
  }

  factory DietPlanModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final goals = data['goals'] as Map<String, dynamic>? ?? {};
    return DietPlanModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      nutritionistId: data['nutritionistId'] ?? '',
      planName: data['planName'] ?? '',
      calories: goals['calories'] ?? 0,
      protein: goals['protein'] ?? 0,
      carbs: goals['carbs'] ?? 0,
      fat: goals['fat'] ?? 0,
      meals: (data['meals'] as List<dynamic>?)
              ?.map((meal) => Meal.fromMap(meal as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}