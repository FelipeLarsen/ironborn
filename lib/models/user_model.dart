class UserModel {
  final String uid;
  final String email;
  final String name;
  final String userType;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
  });

  // Converte um objeto UserModel para um Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
    };
  }

  // NOVO: Converte um Map (do Firestore) para um objeto UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? 'aluno', // 'aluno' como fallback
    );
  }
}