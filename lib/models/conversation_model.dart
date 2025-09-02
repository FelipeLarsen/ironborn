import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  // Lista com os IDs dos 2 (ou 3) participantes. Facilita as queries.
  final List<String> participants;
  // Nomes dos participantes para exibir na lista de conversas.
  final Map<String, String> participantNames;
  // Opcional: Contexto da conversa, como o nome do aluno em comum.
  final String? context;

  // Para ordenar a lista de conversas.
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.context,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ConversationModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      context: data['context'],
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'context': context,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp,
    };
  }
}
