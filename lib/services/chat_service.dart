// ARQUIVO ATUALIZADO COM A CORREÇÃO FINAL DO ID DA CONVERSA

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/conversation_model.dart';
import 'package:ironborn/models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getOrCreateConversation(
      UserModel currentUser, UserModel recipient) async {
    try {
      List<String> participantIds = [currentUser.id, recipient.id];
      participantIds.sort();
      String conversationId = participantIds.join('_');

      // ALTERADO: Usar o conversationId que acabámos de gerar.
      final conversationRef =
          _firestore.collection('conversations').doc(conversationId);
      final doc = await conversationRef.get();

      if (doc.exists) {
        debugPrint("Conversa encontrada: ${doc.id}");
        return doc.id;
      } else {
        debugPrint("Nenhuma conversa encontrada. A criar uma nova.");
        final conversation = ConversationModel(
          id: conversationRef.id,
          participants: participantIds,
          participantNames: {
            currentUser.id: currentUser.name,
            recipient.id: recipient.name,
          },
          lastMessage: 'Conversa iniciada',
          lastMessageTimestamp: Timestamp.now(),
        );

        await conversationRef.set(conversation.toMap());
        debugPrint("Nova conversa criada: ${conversationRef.id}");
        return conversationRef.id;
      }
    } catch (e) {
      debugPrint("!!!!!! ERRO CRÍTICO no ChatService: $e");
      rethrow;
    }
  }

  Future<String> getOrCreateProfessionalConversation(
      UserModel professionalA, UserModel professionalB, UserModel student) async {
    
    final participantIds = [professionalA.id, professionalB.id, student.id]..sort();
    final conversationId = participantIds.join('_');

    // ALTERADO: Usar o conversationId que acabámos de gerar.
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final doc = await conversationRef.get();

    if (doc.exists) {
      return doc.id;
    } else {
      final conversation = ConversationModel(
        id: conversationRef.id,
        participants: [professionalA.id, professionalB.id],
        participantNames: {
          professionalA.id: professionalA.name,
          professionalB.id: professionalB.name,
        },
        context: "Sobre: ${student.name}",
        lastMessage: 'Conversa iniciada',
        lastMessageTimestamp: Timestamp.now(),
      );
      await conversationRef.set(conversation.toMap());
      return conversationRef.id;
    }
  }
}
