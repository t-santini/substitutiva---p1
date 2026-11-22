import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import '../utils/condicoes.dart';
import '../widgets/fonte_dados.dart';
import 'chart_screen.dart';

/// Tela 2: previsão de quatro dias da cidade selecionada.
class ForecastScreen extends StatefulWidget {
  final Cidade cidade;
  const ForecastScreen({super.key, required this.cidade});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _service = CptecService();
  final _storage = StorageService();

  bool _carregando = true;
  String? _erro;
  Previsao? _previsao;
  bool _favorita = false;

  final _fmtDia = DateFormat("EEEE, dd/MM", 'pt_BR');
  final _fmtData = DateFormat('dd/MM/yyyy', 'pt_BR');
  final _fmtDataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _favorita = await _storage.ehFavorita(widget.cidade);
    // Mostra o cache imediatamente (se houver) enquanto busca dados novos.
    final cache = await _storage.carregarPrevisao(widget.cidade.id);
    if (mounted && cache != null) setState(() => _previsao = cache);
    await _atualizar();
  }

  Future<void> _atualizar() async {
    if (!mounted) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await _service.buscarPrevisao(widget.cidade.id);
      if (p.dias.isNotEmpty) {
        await _storage.salvarPrevisao(widget.cidade.id, p);
      }
      if (!mounted) return;
      setState(() => _previsao = p);
    } on CptecException catch (e) {
      await _tratarErro(e.mensagem);
    } catch (_) {
      await _tratarErro('Ocorreu um erro inesperado ao obter a previsão.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Em caso de falha, tenta exibir a última previsão salva localmente.
  Future<void> _tratarErro(String msg) async {
    final cache = await _storage.carregarPrevisao(widget.cidade.id);
    if (!mounted) return;
    setState(() {
      _erro = msg;
      if (cache != null) _previsao = cache;
    });
    if (cache != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$msg Exibindo a última previsão salva.')),
      );
    }
  }

  Future<void> _alternarFavorita() async {
    final f = await _storage.alternarFavorita(widget.cidade);
    if (!mounted) return;
    setState(() => _favorita = f);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(f ? 'Adicionada às favoritas.' : 'Removida das favoritas.'),
      duration: const Duration(seconds: 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final temDias = _previsao != null && _previsao!.dias.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cidade.nomeCompleto),
        actions: [
          IconButton(
            tooltip: _favorita ? 'Remover dos favoritos' : 'Favoritar',
            icon: Icon(_favorita ? Icons.star : Icons.star_border),
            onPressed: _alternarFavorita,
          ),
          IconButton(
            tooltip: 'Gráfico de temperaturas',
            icon: const Icon(Icons.show_chart),
            onPressed: temDias
                ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChartScreen(
                        cidade: widget.cidade,
                        previsao: _previsao!,
                      ),
                    ))
                : null,
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _atualizar,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_carregando) const LinearProgressIndicator(),
          Expanded(child: _corpo()),
          const FonteDados(),
        ],
      ),
    );
  }

  Widget _corpo() {
    final p = _previsao;
    if (p == null) {
      if (_carregando) {
        return const Center(child: CircularProgressIndicator());
      }
      return MensagemEstado(
        icone: Icons.cloud_off,
        mensagem: _erro ?? 'Não há previsão disponível para esta cidade.',
        textoBotao: 'Tentar novamente',
        aoPressionar: _atualizar,
      );
    }
    if (p.dias.isEmpty) {
      return MensagemEstado(
        icone: Icons.event_busy,
        mensagem: 'Não há previsão disponível para esta cidade no momento.',
        textoBotao: 'Atualizar',
        aoPressionar: _atualizar,
      );
    }

    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p.doCache)
            Card(
              color: Colors.amber[100],
              child: ListTile(
                leading: const Icon(Icons.offline_bolt),
                title: const Text('Dados salvos no dispositivo'),
                subtitle: Text(
                    'Obtidos em ${_fmtDataHora.format(p.obtidaEm)}. '
                    'Toque em atualizar para buscar dados novos.'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Atualizado pelo CPTEC/INPE em: '
              '${p.atualizacao != null ? _fmtData.format(p.atualizacao!) : 'não informado'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ...p.dias.map(_cardDia),
        ],
      ),
    );
  }

  Widget _cardDia(PrevisaoDia d) {
    final dataTxt = d.data != null
        ? _capitalizar(_fmtDia.format(d.data!))
        : 'Data não informada';
    final min = d.minima != null ? '${d.minima}°C' : '--';
    final max = d.maxima != null ? '${d.maxima}°C' : '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Condicoes.icone(d.sigla),
                size: 48, color: Condicoes.cor(d.sigla)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dataTxt,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(d.descricao),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward,
                          size: 16, color: Colors.blue),
                      Text(' Mín: $min   '),
                      const Icon(Icons.arrow_upward,
                          size: 16, color: Colors.red),
                      Text(' Máx: $max'),
                    ],
                  ),
                  if (d.iuv != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Índice UV: ${d.iuv!.toStringAsFixed(1)} '
                      '(${Condicoes.classificacaoUv(d.iuv!)})',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
