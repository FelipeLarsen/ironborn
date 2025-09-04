import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/user_model.dart';

class ConnectionService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> sendRequest(UserModel fromUser, UserModel toProfessional) async {
    // Usa um ID previsível para evitar pedidos duplicados
    final requestId = '${fromUser.id}_${toProfessional.id}';
    final requestRef = _firestore.collection('connection_requests').doc(requestId);

    final doc = await requestRef.get();
    if (doc.exists) {
      throw Exception("Já enviou um pedido a este profissional.");
    }

    final requestData = {
      'fromUserId': fromUser.id,
      'fromUserName': fromUser.name,
      'fromUserPhotoUrl': fromUser.photoUrl ?? '',
      'toUserId': toProfessional.id,
      'professionalType': toProfessional.userType.name,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await requestRef.set(requestData);
  }

  Future<void> acceptRequest(String requestId) async {
    final requestRef = _firestore.collection('connection_requests').doc(requestId);
    final requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      throw Exception("Pedido não encontrado.");
    }

    final requestData = requestDoc.data()!;
    final studentId = requestData['fromUserId'];
    final professionalId = requestData['toUserId'];
    final professionalType = requestData['professionalType'];

    final userRef = _firestore.collection('users').doc(studentId);

    // Atualiza o perfil do aluno com o ID do profissional
    if (professionalType == 'treinador') {
      await userRef.update({'trainerId': professionalId});
    } else if (professionalType == 'nutricionista') {
      await userRef.update({'nutritionistId': professionalId});
    }

    // Atualiza o status do pedido para 'accepted'
    await requestRef.update({'status': 'accepted'});
  }

  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('connection_requests').doc(requestId).update({'status': 'rejected'});
  }
}
