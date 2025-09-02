import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ironborn/models/conversation_model.dart';
import 'package:ironborn/screens/chat_screen.dart';
import 'package:ironborn/widgets/responsive_layout.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String _getRecipientName(ConversationModel conversation) {
    // Retorna o nome do outro participante da conversa.
    final recipientEntry = conversation.participantNames.entries
        .firstWhere((entry) => entry.key != _currentUserId, orElse: () => const MapEntry('', 'Utilizador'));
    return recipientEntry.value;
  }
  
  String _getRecipientId(ConversationModel conversation) {
    // Retorna o ID do outro participante da conversa.
    return conversation.participants.firstWhere((id) => id != _currentUserId, orElse: () => '');
  }

  @override
  Widget build(BuildContext context) {
    // Configura o timeago para português para mostrar "há 5 minutos", etc.
    timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());

    return ResponsiveLayout(
      appBar: AppBar(
        title: const Text('As minhas Mensagens'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: _currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Erro ao carregar conversas: ${snapshot.error}");
            return const Center(child: Text("Ocorreu um erro."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Ainda não tem conversas."),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation =
                  ConversationModel.fromSnapshot(conversations[index]);
              final recipientName = _getRecipientName(conversation);
              final recipientId = _getRecipientId(conversation);

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(recipientName.isNotEmpty ? recipientName[0] : '?'),
                    ),
                    title: Text(
                      recipientName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      timeago.format(conversation.lastMessageTimestamp.toDate(), locale: 'pt_BR'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      if (recipientId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              conversationId: conversation.id,
                              recipientName: recipientName,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
