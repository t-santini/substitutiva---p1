import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../widgets/fonte_dados.dart';

/// Tela 3: gráfico das temperaturas mínimas e máximas.
class ChartScreen extends StatelessWidget {
  final Cidade cidade;
  final Previsao previsao;

  const ChartScreen({super.key, required this.cidade, required this.previsao});

  @override
  Widget build(BuildContext context) {
    // Usa só os dias que têm mínima e máxima.
    final dias = previsao.dias
        .where((d) => d.minima != null && d.maxima != null)
        .toList();
    final fmt = DateFormat('dd/MM', 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: Text('Temperaturas – ${cidade.nome}')),
      body: Column(
        children: [
          Expanded(
            child: dias.isEmpty
                ? const MensagemEstado(
                    icone: Icons.show_chart,
                    mensagem: 'Não há temperaturas suficientes para o gráfico.',
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
                    child: Column(
                      children: [
                        const _Legenda(),
                        const SizedBox(height: 16),
                        Expanded(child: _grafico(dias, fmt)),
                      ],
                    ),
                  ),
          ),
          const FonteDados(),
        ],
      ),
    );
  }

  Widget _grafico(List<PrevisaoDia> dias, DateFormat fmt) {
    final minimas = dias.map((d) => d.minima!).toList();
    final maximas = dias.map((d) => d.maxima!).toList();
    final menor = minimas.reduce((a, b) => a < b ? a : b);
    final maior = maximas.reduce((a, b) => a > b ? a : b);

    List<FlSpot> spots(List<int> v) =>
        [for (var i = 0; i < v.length; i++) FlSpot(i.toDouble(), v[i].toDouble())];

    LineChartBarData linha(List<int> v, Color cor) => LineChartBarData(
          spots: spots(v),
          isCurved: true,
          color: cor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData:
              BarAreaData(show: true, color: cor.withAlpha(30)),
        );

    return LineChart(
      LineChartData(
        minY: (menor - 3).toDouble(),
        maxY: (maior + 3).toDouble(),
        minX: 0,
        maxX: (dias.length - 1).toDouble(),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (itens) => itens
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()}°C',
                      TextStyle(color: s.bar.color, fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 2,
              getTitlesWidget: (v, _) => Text('${v.toInt()}°'),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dias.length || v != i.toDouble()) {
                  return const SizedBox.shrink();
                }
                final data = dias[i].data;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data != null ? fmt.format(data) : '-'),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          linha(maximas, Colors.red),
          linha(minimas, Colors.blue),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 16, height: 4, color: c),
            const SizedBox(width: 6),
            Text(t),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(Colors.red, 'Máxima'),
        const SizedBox(width: 24),
        item(Colors.blue, 'Mínima'),
      ],
    );
  }
}
