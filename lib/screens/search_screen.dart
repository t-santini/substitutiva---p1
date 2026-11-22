import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import '../widgets/fonte_dados.dart';
import 'forecast_screen.dart';

/// Tela 1: pesquisa de cidades no CPTEC/INPE.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _service = CptecService();
  final _storage = StorageService();

  bool _carregando = false;
  String? _erro;
  List<Cidade>? _resultados; // null = nenhuma busca feita ainda
  String _ultimoTermo = '';

  List<Cidade> _historico = [];
  List<Cidade> _favoritas = [];

  @override
  void initState() {
    super.initState();
    _carregarSalvos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregarSalvos() async {
    final h = await _storage.carregarHistorico();
    final f = await _storage.carregarFavoritas();
    if (!mounted) return;
    setState(() {
      _historico = h;
      _favoritas = f;
    });
  }

  Future<void> _buscar() async {
    final termo = _controller.text.trim();
    FocusScope.of(context).unfocus();
    if (termo.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite pelo menos 2 letras.')),
      );
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
      _ultimoTermo = termo;
    });
    try {
      final cidades = await _service.buscarCidades(termo);
      if (!mounted) return;
      setState(() => _resultados = cidades);
    } on CptecException catch (e) {
      if (!mounted) return;
      setState(() => _erro = e.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Ocorreu um erro inesperado na busca.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrir(Cidade cidade) async {
    await _storage.adicionarAoHistorico(cidade);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ForecastScreen(cidade: cidade)),
    );
    _carregarSalvos(); // favoritas podem ter mudado
  }

  void _limparBusca() {
    _controller.clear();
    setState(() {
      _resultados = null;
      _erro = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Nome da cidade',
                hintText: 'Ex.: São Paulo',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_resultados != null || _erro != null)
                      IconButton(
                        tooltip: 'Limpar',
                        icon: const Icon(Icons.clear),
                        onPressed: _limparBusca,
                      ),
                    IconButton(
                      tooltip: 'Pesquisar',
                      icon: const Icon(Icons.search),
                      onPressed: _carregando ? null : _buscar,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _corpo()),
          const FonteDados(),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return MensagemEstado(
        icone: Icons.cloud_off,
        mensagem: _erro!,
        textoBotao: 'Tentar novamente',
        aoPressionar: _buscar,
      );
    }
    if (_resultados != null) {
      if (_resultados!.isEmpty) {
        return MensagemEstado(
          icone: Icons.search_off,
          mensagem: 'Nenhuma cidade encontrada para "$_ultimoTermo".',
        );
      }
      return ListView.separated(
        itemCount: _resultados!.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = _resultados![i];
          return ListTile(
            leading: CircleAvatar(child: Text(c.uf.isEmpty ? '?' : c.uf)),
            title: Text(c.nome),
            subtitle: Text('UF: ${c.uf}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrir(c),
          );
        },
      );
    }
    return _listasSalvas();
  }

  Widget _listasSalvas() {
    if (_historico.isEmpty && _favoritas.isEmpty) {
      return const MensagemEstado(
        icone: Icons.travel_explore,
        mensagem: 'Pesquise uma cidade para ver a previsão do tempo.',
      );
    }
    return ListView(
      children: [
        if (_favoritas.isNotEmpty) ...[
          _titulo('Favoritas'),
          ..._favoritas.map((c) => ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(c.nomeCompleto),
                onTap: () => _abrir(c),
              )),
        ],
        if (_historico.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: _titulo('Pesquisas recentes')),
              TextButton(
                onPressed: () async {
                  await _storage.limparHistorico();
                  _carregarSalvos();
                },
                child: const Text('Limpar'),
              ),
            ],
          ),
          ..._historico.map((c) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(c.nomeCompleto),
                onTap: () => _abrir(c),
              )),
        ],
      ],
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium),
      );
}
