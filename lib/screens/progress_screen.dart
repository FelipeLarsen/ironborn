// ARQUIVO ATUALIZADO: lib/screens/progress_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ironborn/models/daily_log_model.dart';
import 'package:ironborn/widgets/responsive_layout.dart';

class ProgressScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProgressScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<List<DailyLogModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _fetchWeightLogs();
  }

  Future<List<DailyLogModel>> _fetchWeightLogs() async {
    // ALTERADO: Simplificámos a consulta do Firestore.
    final snapshot = await FirebaseFirestore.instance
        .collection('dailyLogs')
        .where('studentId', isEqualTo: widget.userId)
        // REMOVIDO: .where('bodyWeightKg', isNotEqualTo: null)
        .orderBy('date')
        .get();

    final allLogs = snapshot.docs.map((doc) => DailyLogModel.fromSnapshot(doc)).toList();

    // ADICIONADO: O filtro agora é feito no lado do cliente (em Dart).
    // Isto torna a consulta mais simples e não requer um índice composto.
    final logsWithWeight = allLogs.where((log) => log.bodyWeightKg != null).toList();

    return logsWithWeight;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: AppBar(
        title: Text('Progresso de ${widget.userName}'),
      ),
      body: FutureBuilder<List<DailyLogModel>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Adicionamos o print do erro para ajudar a depurar no futuro.
            debugPrint("Erro no FutureBuilder do gráfico: ${snapshot.error}");
            return const Center(child: Text("Erro ao carregar os dados."));
          }
          if (!snapshot.hasData || snapshot.data!.length < 2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "São necessários pelo menos dois registos de peso para exibir um gráfico.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final logs = snapshot.data!;
          final spots = logs.asMap().entries.map((entry) {
            // X: índice (0, 1, 2...), Y: peso
            return FlSpot(entry.key.toDouble(), entry.value.bodyWeightKg!);
          }).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Evolução do Peso Corporal (kg)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: LineChart(
                    _buildChartData(spots, logs),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LineChartData _buildChartData(List<FlSpot> spots, List<DailyLogModel> logs) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return const FlLine(color: Colors.white10, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(color: Colors.white10, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < logs.length) {
                // Lógica melhorada para mostrar mais datas sem sobreposição.
                final int total = logs.length;
                int interval = (total / 4).ceil(); // Mostra cerca de 4-5 datas.
                if (index % interval == 0 || index == total - 1) {
                  final date = logs[index].date.toDate();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              // Mostra apenas alguns valores no eixo Y para não poluir.
              if (value == meta.min || value == meta.max) {
                 return const SizedBox.shrink();
              }
              return Text(
                '${value.toInt()}kg',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white10),
      ),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.deepOrange,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.deepOrange.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}

