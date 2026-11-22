import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/veiculo.dart';
import '../services/fipe_service.dart';
import '../services/storage_service.dart';
import 'selecao_screen.dart';

/// Cadastro do (único) veículo. Marca e modelo vêm da BrasilAPI.
class VeiculoFormScreen extends StatefulWidget {
  const VeiculoFormScreen({super.key});

  @override
  State<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends State<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fipe = FipeService();
  final _storage = StorageService();
  final _anoCtrl = TextEditingController();
  final _cilCtrl = TextEditingController();

  TipoVeiculo _tipo = TipoVeiculo.carros;
  ItemFipe? _marca;
  ItemFipe? _modelo;
  bool _tentouSalvar = false;
  bool _salvando = false;

  @override
  void dispose() {
    _anoCtrl.dispose();
    _cilCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherMarca() async {
    final item = await Navigator.of(context).push<ItemFipe>(MaterialPageRoute(
      builder: (_) => SelecaoScreen(
        titulo: 'Marca (${_tipo.rotulo})',
        carregar: () => _fipe.marcas(_tipo),
      ),
    ));
    if (item != null && item.codigo != _marca?.codigo) {
      setState(() {
        _marca = item;
        _modelo = null; // modelo depende da marca
      });
    }
  }

  Future<void> _escolherModelo() async {
    final marca = _marca;
    if (marca == null) return;
    final item = await Navigator.of(context).push<ItemFipe>(MaterialPageRoute(
      builder: (_) => SelecaoScreen(
        titulo: 'Modelo – ${marca.nome}',
        carregar: () => _fipe.modelos(_tipo, marca.codigo),
      ),
    ));
    if (item != null) setState(() => _modelo = item);
  }

  Future<void> _salvar() async {
    setState(() => _tentouSalvar = true);
    final valido = _formKey.currentState!.validate();
    if (!valido || _marca == null || _modelo == null) return;

    setState(() => _salvando = true);
    final v = Veiculo(
      tipo: _tipo,
      marcaCodigo: _marca!.codigo,
      marca: _marca!.nome,
      modelo: _modelo!.nome,
      ano: int.parse(_anoCtrl.text),
      cilindrada: int.parse(_cilCtrl.text),
    );
    await _storage.salvarVeiculo(v);
    if (mounted) Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final anoAtual = DateTime.now().year;
    final erroCor = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tipo de veículo'),
            const SizedBox(height: 8),
            SegmentedButton<TipoVeiculo>(
              segments: TipoVeiculo.values
                  .map((t) => ButtonSegment(value: t, label: Text(t.rotulo)))
                  .toList(),
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() {
                _tipo = s.first;
                _marca = null;
                _modelo = null;
              }),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.business),
                title: Text(_marca?.nome ?? 'Selecionar marca'),
                subtitle: const Text('Marca'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _escolherMarca,
              ),
            ),
            if (_tentouSalvar && _marca == null)
              Text('  Selecione a marca', style: TextStyle(color: erroCor)),
            Card(
              child: ListTile(
                enabled: _marca != null,
                leading: const Icon(Icons.directions_car),
                title: Text(_modelo?.nome ??
                    (_marca == null
                        ? 'Escolha a marca primeiro'
                        : 'Selecionar modelo')),
                subtitle: const Text('Modelo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _escolherModelo,
              ),
            ),
            if (_tentouSalvar && _modelo == null)
              Text('  Selecione o modelo', style: TextStyle(color: erroCor)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _anoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Ano',
                hintText: 'Ex.: 2018',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final ano = int.tryParse(v ?? '');
                if (ano == null) return 'Informe o ano';
                if (ano < 1900 || ano > anoAtual + 1) {
                  return 'Ano entre 1900 e ${anoAtual + 1}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cilCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Cilindrada do motor (cc)',
                hintText: 'Ex.: 1600 (motor 1.6)',
                suffixText: 'cc',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final c = int.tryParse(v ?? '');
                if (c == null || c <= 0) return 'Informe a cilindrada';
                if (c < 50 || c > 20000) return 'Valor entre 50 e 20000 cc';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar veículo'),
            ),
          ],
        ),
      ),
    );
  }
}
