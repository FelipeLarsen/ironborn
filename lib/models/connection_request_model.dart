// ARQUIVO ATUALIZADO E CORRIGIDO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ironborn/models/user_model.dart'; // NOVO: Importa o user_model para ter acesso ao UserType real.

enum RequestStatus { pending, accepted, rejected }

class ConnectionRequestModel {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhotoUrl;
  final String toUserId;
  final UserType professionalType;
  final RequestStatus status;
  final Timestamp timestamp;

  const ConnectionRequestModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserPhotoUrl,
    required this.toUserId,
    required this.professionalType,
    required this.status,
    required this.timestamp,
  });

  factory ConnectionRequestModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConnectionRequestModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserPhotoUrl: data['fromUserPhotoUrl'] ?? '',
      toUserId: data['toUserId'] ?? '',
      // Agora esta chamada funciona, pois o UserType importado tem o método fromString.
      professionalType: UserType.fromString(data['professionalType']),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhotoUrl': fromUserPhotoUrl,
      'toUserId': toUserId,
      'professionalType': professionalType.name,
      'status': status.name,
      'timestamp': timestamp,
    };
  }
}
