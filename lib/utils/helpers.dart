// NOVO ARQUIVO
// Centraliza funções úteis para evitar duplicação de código no projeto.

import 'package:intl/intl.dart';

/// Gera um ID de documento único para o log diário de um usuário.
/// O formato é 'userId_AAAA-MM-DD'.
String getTodayLogDocId(String userId) {
  final now = DateTime.now();
  // O formato AAAA-MM-DD garante um ID único e ordenável por dia.
  return '${userId}_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

/// Retorna o nome do dia da semana em inglês (ex: 'monday') de forma segura,
/// independente do idioma do dispositivo do usuário.
String getDayOfWeekInEnglish() {
  // Usar o locale 'en_US' garante que a saída seja sempre em inglês,
  // correspondendo às chaves salvas no Firestore.
  return DateFormat('EEEE', 'en_US').format(DateTime.now()).toLowerCase();
}