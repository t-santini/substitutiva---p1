import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../services/calculos.dart';
import '../services/storage_service.dart';
import '../utils/formatos.dart';
import 'abastecimento_form_screen.dart';
import 'dashboard_screen.dart';
import 'veiculo_form_screen.dart';

/// Tela principal: controla qual conteúdo aparece conforme haja ou não
/// veículo cadastrado, e navega entre Abastecimentos, Dashboard e Veículo.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _storage = StorageService();
  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = [];
  bool _carregando = true;
  int _aba = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final v = await _storage.carregarVeiculo();
    final a = v == null ? <Abastecimento>[] : await _storage.carregarAbastecimentos();
    if (!mounted) return;
    setState(() {
      _veiculo = v;
      _abastecimentos = a;
      _carregando = false;
    });
  }

  Future<void> _cadastrarVeiculo() async {
    final v = await Navigator.of(context).push<Veiculo>(
      MaterialPageRoute(builder: (_) => const VeiculoFormScreen()),
    );
    if (v != null) {
      _aba = 0;
      _carregar();
    }
  }

  Future<void> _excluirVeiculo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red),
        title: const Text('Excluir veículo?'),
        content: Text(
          'O veículo ${_veiculo!.descricao} e TODOS os '
          '${_abastecimentos.length} abastecimento(s) registrados serão '
          'apagados. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _storage.excluirVeiculo();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo e abastecimentos excluídos.')),
      );
      _carregar();
    }
  }

  Future<void> _abrirFormAbastecimento([Abastecimento? editar]) async {
    final salvou = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => AbastecimentoFormScreen(
        existentes: _abastecimentos,
        editar: editar,
      ),
    ));
    if (salvou == true) _carregar();
  }

  Future<void> _excluirAbastecimento(Abastecimento a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text('Registro de ${Fmt.dataHora(a.dataHora)} '
            '(${Fmt.moeda(a.valorTotal)}).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok == true) {
      await _storage.excluirAbastecimento(a.id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_veiculo == null) return _semVeiculo();

    final titulos = ['Abastecimentos', 'Dashboard', 'Meu veículo'];
    return Scaffold(
      appBar: AppBar(title: Text(titulos[_aba])),
      body: switch (_aba) {
        0 => _listaAbastecimentos(),
        1 => DashboardScreen(abastecimentos: _abastecimentos),
        _ => _dadosVeiculo(),
      },
      floatingActionButton: _aba == 0
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormAbastecimento(),
              icon: const Icon(Icons.add),
              label: const Text('Abastecer'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_gas_station), label: 'Abastecimentos'),
          NavigationDestination(
              icon: Icon(Icons.insights), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.directions_car), label: 'Veículo'),
        ],
      ),
    );
  }

  Widget _semVeiculo() {
    return Scaffold(
      appBar: AppBar(title: const Text('Controle de Combustível')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_car, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Nenhum veículo cadastrado.\nCadastre seu veículo para começar '
                'a registrar os abastecimentos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _cadastrarVeiculo,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaAbastecimentos() {
    if (_abastecimentos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum abastecimento registrado.\nToque em "Abastecer" para '
            'adicionar o primeiro.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // Mais recentes primeiro.
    final indicadores = Calculos.indicadores(_abastecimentos).reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88, top: 8),
      itemCount: indicadores.length,
      itemBuilder: (_, i) {
        final ind = indicadores[i];
        final a = ind.abastecimento;
        final detalhe = ind.temIndicadores
            ? '${Fmt.numero(ind.kmPorLitro!)} km/L · '
                '${Fmt.moeda(ind.custoPorKm!)}/km · '
                '${Fmt.numero(ind.distancia!, 0)} km rodados'
            : 'Abastecimento de referência';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(a.combustivel.rotulo[0])),
            title: Text('${Fmt.moeda(a.valorTotal)} · '
                '${Fmt.numero(a.litros)} L de ${a.combustivel.rotulo}'),
            subtitle: Text(
              '${Fmt.dataHora(a.dataHora)} · '
              '${Fmt.numero(a.quilometragem, 0)} km · '
              '${Fmt.moeda(a.precoLitro)}/L\n$detalhe',
            ),
            isThreeLine: true,
            onTap: () => _abrirFormAbastecimento(a),
            trailing: IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _excluirAbastecimento(a),
            ),
          ),
        );
      },
    );
  }

  Widget _dadosVeiculo() {
    final v = _veiculo!;
    Widget linha(IconData i, String rotulo, String valor) => ListTile(
          leading: Icon(i),
          title: Text(valor),
          subtitle: Text(rotulo),
        );
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Column(
            children: [
              linha(Icons.category, 'Tipo', v.tipo.rotulo),
              linha(Icons.business, 'Marca', v.marca),
              linha(Icons.directions_car, 'Modelo', v.modelo),
              linha(Icons.calendar_today, 'Ano', '${v.ano}'),
              linha(Icons.settings, 'Cilindrada do motor', '${v.cilindrada} cc'),
              linha(Icons.local_gas_station, 'Abastecimentos registrados',
                  '${_abastecimentos.length}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Só é possível ter um veículo por vez. Para cadastrar outro, '
          'exclua o atual (os abastecimentos dele também serão apagados).',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          onPressed: _excluirVeiculo,
          icon: const Icon(Icons.delete_forever),
          label: const Text('Excluir veículo'),
        ),
      ],
    );
  }
}
