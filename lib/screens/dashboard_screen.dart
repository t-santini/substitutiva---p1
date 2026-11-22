import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../services/calculos.dart';
import '../utils/formatos.dart';

/// Dashboard com indicadores e gráficos (fl_chart).
class DashboardScreen extends StatelessWidget {
  final List<Abastecimento> abastecimentos;
  const DashboardScreen({super.key, required this.abastecimentos});

  @override
  Widget build(BuildContext context) {
    if (abastecimentos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Registre abastecimentos para ver o dashboard.',
              textAlign: TextAlign.center),
        ),
      );
    }

    final ind = Calculos.indicadores(abastecimentos);
    final comInd = ind.where((i) => i.temIndicadores).toList();
    final totalGasto =
        ind.fold<double>(0, (s, i) => s + i.abastecimento.valorTotal);
    final totalLitros =
        ind.fold<double>(0, (s, i) => s + i.abastecimento.litros);
    final kmRodados = comInd.fold<double>(0, (s, i) => s + i.distancia!);
    final mediaKmL = Calculos.media(comInd.map((i) => i.kmPorLitro));
    final mediaRsKm = Calculos.media(comInd.map((i) => i.custoPorKm));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _Resumo('Total gasto', Fmt.moeda(totalGasto), Icons.payments),
            _Resumo('Litros', '${Fmt.numero(totalLitros)} L', Icons.water_drop),
            _Resumo('Média km/L',
                mediaKmL != null ? Fmt.numero(mediaKmL) : '—', Icons.speed),
            _Resumo('Média R\$/km',
                mediaRsKm != null ? Fmt.moeda(mediaRsKm) : '—', Icons.route),
          ],
        ),
        const SizedBox(height: 4),
        Text('${Fmt.numero(kmRodados, 0)} km rodados entre abastecimentos',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),

        _Secao(
          titulo: 'Valor de cada abastecimento (R\$)',
          child: _graficoBarras(ind),
        ),
        if (comInd.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'O primeiro abastecimento é a referência inicial. '
                'Registre o segundo para ver km/L e R\$/km.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          _Secao(
            titulo: 'Consumo (km/L) por abastecimento',
            child: _graficoLinha(
              comInd,
              (i) => i.kmPorLitro!,
              Colors.teal,
              (v) => Fmt.numero(v, 1),
            ),
          ),
          _Secao(
            titulo: 'Custo por km (R\$/km) por abastecimento',
            child: _graficoLinha(
              comInd,
              (i) => i.custoPorKm!,
              Colors.deepOrange,
              (v) => Fmt.numero(v, 2),
            ),
          ),
        ],
        _Secao(titulo: 'Detalhamento', child: _tabela(ind), altura: null),
      ],
    );
  }

  String _rotulo(Indicador i) => Fmt.diaMes(i.abastecimento.dataHora);

  Widget _rodape(List<Indicador> lista, double v) {
    final i = v.toInt();
    if (v != i.toDouble() || i < 0 || i >= lista.length) {
      return const SizedBox.shrink();
    }
    // Evita sobreposição quando há muitos pontos.
    final passo = (lista.length / 6).ceil();
    if (i % passo != 0 && i != lista.length - 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(_rotulo(lista[i]), style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _graficoBarras(List<Indicador> lista) {
    final maior = lista
        .map((i) => i.abastecimento.valorTotal)
        .reduce((a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maior * 1.2,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, _, rod, __) => BarTooltipItem(
              Fmt.moeda(rod.toY),
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => _rodape(lista, v),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < lista.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: lista[i].abastecimento.valorTotal,
                color: Colors.teal,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _graficoLinha(
    List<Indicador> lista,
    double Function(Indicador) valor,
    Color cor,
    String Function(double) formatar,
  ) {
    final valores = lista.map(valor).toList();
    final menor = valores.reduce((a, b) => a < b ? a : b);
    final maior = valores.reduce((a, b) => a > b ? a : b);
    final folgaCalc = (maior - menor) * 0.2;
    final folga = folgaCalc < 0.05 ? 0.05 : folgaCalc;
    final minY = menor - folga < 0 ? 0.0 : menor - folga;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: lista.length == 1 ? 1 : (lista.length - 1).toDouble(),
        minY: minY,
        maxY: maior + folga,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      formatar(s.y),
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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
              reservedSize: 44,
              getTitlesWidget: (v, meta) =>
                  Text(formatar(v), style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) => _rodape(lista, v),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < valores.length; i++)
                FlSpot(i.toDouble(), valores[i]),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: cor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: cor.withAlpha(30)),
          ),
        ],
      ),
    );
  }

  Widget _tabela(List<Indicador> lista) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Valor'), numeric: true),
          DataColumn(label: Text('Distância'), numeric: true),
          DataColumn(label: Text('km/L'), numeric: true),
          DataColumn(label: Text('R\$/km'), numeric: true),
        ],
        rows: [
          for (final i in lista)
            DataRow(cells: [
              DataCell(Text(Fmt.data(i.abastecimento.dataHora))),
              DataCell(Text(Fmt.moeda(i.abastecimento.valorTotal))),
              DataCell(Text(i.distancia != null
                  ? '${Fmt.numero(i.distancia!, 0)} km'
                  : 'Referência')),
              DataCell(Text(
                  i.kmPorLitro != null ? Fmt.numero(i.kmPorLitro!) : '—')),
              DataCell(Text(
                  i.custoPorKm != null ? Fmt.moeda(i.custoPorKm!) : '—')),
            ]),
        ],
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  const _Resumo(this.titulo, this.valor, this.icone);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icone, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.bodySmall),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(valor,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;
  final Widget child;
  final double? altura;
  const _Secao({required this.titulo, required this.child, this.altura = 220});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            altura == null ? child : SizedBox(height: altura, child: child),
          ],
        ),
      ),
    );
  }
}
