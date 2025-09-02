// ARQUIVO ATUALIZADO: lib/models/diet_plan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  // ALTERADO: Adicionado 'final' para imutabilidade.
  final String description;
  final String quantity;

  // ALTERADO: Construtor agora é 'const'.
  const FoodItem({required this.description, required this.quantity});

  // NOVO: copyWith para atualizações imutáveis em formulários.
  FoodItem copyWith({String? description, String? quantity}) {
    return FoodItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }

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

class Meal {
  // ALTERADO: Adicionado 'final' para imutabilidade.
  final String name;
  final String time;
  final List<FoodItem> foods;

  // ALTERADO: Construtor agora é 'const'.
  const Meal({required this.name, required this.time, required this.foods});

  // NOVO: copyWith para atualizações imutáveis em formulários.
  Meal copyWith({String? name, String? time, List<FoodItem>? foods}) {
    return Meal(
      name: name ?? this.name,
      time: time ?? this.time,
      foods: foods ?? this.foods,
    );
  }

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

  // ALTERADO: Construtor agora é 'const'.
  const DietPlanModel({
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

  // NOVO: copyWith para atualizações imutáveis.
  DietPlanModel copyWith({
    String? id,
    String? patientId,
    String? nutritionistId,
    String? planName,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<Meal>? meals,
  }) {
    return DietPlanModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      nutritionistId: nutritionistId ?? this.nutritionistId,
      planName: planName ?? this.planName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      meals: meals ?? this.meals,
    );
  }

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

  // ALTERADO: Nome do construtor de 'fromSnapshot' para 'fromMap' para consistência.
  factory DietPlanModel.fromMap(String documentId, Map<String, dynamic> data) {
    final goals = data['goals'] as Map<String, dynamic>? ?? {};
    return DietPlanModel(
      id: documentId,
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