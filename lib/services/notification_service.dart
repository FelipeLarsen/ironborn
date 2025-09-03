// NOVO FICHEIRO

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Inicializa o serviço e as configurações
  Future<void> initialize() async {
    // Pede permissão ao utilizador (iOS e Android 13+)
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Configura listeners para quando a app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Recebida uma mensagem em primeiro plano!');
      debugPrint('Conteúdo da mensagem: ${message.notification?.title}');
      
      // Aqui pode mostrar um In-App Notification (Snackbar, Dialog, etc.)
    });
  }

  // 2. Obtém o token FCM único do dispositivo
  Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('Token FCM do dispositivo: $token');
      return token;
    } catch (e) {
      debugPrint('Erro ao obter o token FCM: $e');
      return null;
    }
  }

  // 3. Salva o token no perfil do utilizador no Firestore
  Future<void> saveTokenToDatabase(String userId) async {
    final token = await getFCMToken();
    if (token != null) {
      final userDocRef = _firestore.collection('users').doc(userId);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // Usa um array para o caso de o utilizador ter múltiplos dispositivos.
        // O FieldValue.arrayUnion garante que não adicionamos tokens duplicados.
        await userDocRef.update({
          'fcmTokens': FieldValue.arrayUnion([token])
        });
        debugPrint('Token salvo para o utilizador: $userId');
      }
    }
  }

  // 4. Remove o token ao fazer logout
  Future<void> removeTokenFromDatabase(String userId) async {
    final token = await getFCMToken();
    if (token != null) {
       final userDocRef = _firestore.collection('users').doc(userId);
       await userDocRef.update({
          'fcmTokens': FieldValue.arrayRemove([token])
        });
       debugPrint('Token removido para o utilizador: $userId');
    }
  }
}
