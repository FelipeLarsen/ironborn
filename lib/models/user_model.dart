// ARQUIVO ATUALIZADO: lib/models/user_model.dart

// NOVO: Enum para garantir a segurança de tipos do perfil de usuário.
enum UserType {
  aluno,
  treinador,
  nutricionista;

  // Helper para converter de/para String de forma segura.
  factory UserType.fromString(String? type) {
    if (type == null) return UserType.aluno;
    return UserType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => UserType.aluno, // Valor padrão seguro
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType userType; // ALTERADO: de String para o enum UserType
  final String? trainerId;
  final String? nutritionistId;

  // ADICIONADO: construtor const
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.trainerId,
    this.nutritionistId,
  });

  // ADICIONADO: Método copyWith para criar cópias modificadas de forma imutável.
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? trainerId,
    String? nutritionistId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      trainerId: trainerId ?? this.trainerId,
      nutritionistId: nutritionistId ?? this.nutritionistId,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      // ALTERADO: Converte a string do Firestore para o enum.
      userType: UserType.fromString(map['userType']),
      trainerId: map['trainerId'],
      nutritionistId: map['nutritionistId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      // ALTERADO: Converte o enum para string antes de salvar.
      'userType': userType.name,
      'trainerId': trainerId,
      'nutritionistId': nutritionistId,
    };
  }
}