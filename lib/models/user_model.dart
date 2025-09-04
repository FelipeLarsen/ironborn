// ARQUIVO ATUALIZADO: lib/models/user_model.dart

enum UserType {
  aluno,
  treinador,
  nutricionista;

  factory UserType.fromString(String? type) {
    if (type == null) return UserType.aluno;
    return UserType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => UserType.aluno,
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserType userType;
  final String? trainerId;
  final String? nutritionistId;

  // NOVOS CAMPOS PARA O PERFIL PÚBLICO DOS PROFISSIONAIS
  final String? photoUrl;
  final String? bio;
  final List<String>? specializations;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.trainerId,
    this.nutritionistId,
    this.photoUrl, // NOVO
    this.bio, // NOVO
    this.specializations, // NOVO
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserType? userType,
    String? trainerId,
    String? nutritionistId,
    String? photoUrl,
    String? bio,
    List<String>? specializations,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      trainerId: trainerId ?? this.trainerId,
      nutritionistId: nutritionistId ?? this.nutritionistId,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      userType: UserType.fromString(map['userType']),
      trainerId: map['trainerId'],
      nutritionistId: map['nutritionistId'],
      photoUrl: map['photoUrl'],
      bio: map['bio'],
      // Converte a lista do Firestore (List<dynamic>) para List<String> de forma segura.
      specializations: map['specializations'] != null ? List<String>.from(map['specializations']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'userType': userType.name,
      'trainerId': trainerId,
      'nutritionistId': nutritionistId,
      'photoUrl': photoUrl,
      'bio': bio,
      'specializations': specializations,
    };
  }
}
