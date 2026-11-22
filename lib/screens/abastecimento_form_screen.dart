import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../services/calculos.dart';
import '../services/storage_service.dart';
import '../utils/formatos.dart';

/// Registro (ou edição) de um abastecimento.
class AbastecimentoFormScreen extends StatefulWidget {
  final List<Abastecimento> existentes;
  final Abastecimento? editar;

  const AbastecimentoFormScreen(
      {super.key, required this.existentes, this.editar});

  @override
  State<AbastecimentoFormScreen> createState() =>
      _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();
  late final TextEditingController _precoCtrl;
  late final TextEditingController _kmCtrl;
  late final TextEditingController _litrosCtrl;

  late Combustivel _combustivel;
  late DateTime _dataHora;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    _combustivel = e?.combustivel ?? Combustivel.gasolina;
    _dataHora = e?.dataHora ?? DateTime.now();
    _precoCtrl = TextEditingController(
        text: e != null ? Fmt.numero(e.precoLitro, 3) : '');
    _kmCtrl = TextEditingController(
        text: e != null ? e.quilometragem.toStringAsFixed(0) : '');
    _litrosCtrl =
        TextEditingController(text: e != null ? Fmt.numero(e.litros, 2) : '');
    for (final c in [_precoCtrl, _litrosCtrl]) {
      c.addListener(() => setState(() {})); // atualiza o total na tela
    }
  }

  @override
  void dispose() {
    _precoCtrl.dispose();
    _kmCtrl.dispose();
    _litrosCtrl.dispose();
    super.dispose();
  }

  double? get _total {
    final p = Fmt.lerNumero(_precoCtrl.text);
    final l = Fmt.lerNumero(_litrosCtrl.text);
    if (p == null || l == null) return null;
    return p * l;
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (!mounted) return;
    final hora = h ?? TimeOfDay.fromDateTime(_dataHora);
    setState(() =>
        _dataHora = DateTime(d.year, d.month, d.day, hora.hour, hora.minute));
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final a = Abastecimento(
      id: widget.editar?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      combustivel: _combustivel,
      precoLitro: Fmt.lerNumero(_precoCtrl.text)!,
      quilometragem: Fmt.lerNumero(_kmCtrl.text)!,
      litros: Fmt.lerNumero(_litrosCtrl.text)!,
      dataHora: _dataHora,
    );
    await _storage.salvarAbastecimento(a);
    if (mounted) Navigator.of(context).pop(true);
  }

  String? _validarPositivo(String? v, String campo) {
    final n = Fmt.lerNumero(v);
    if (n == null) return 'Informe $campo';
    if (n <= 0) return 'Deve ser maior que zero';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editar == null
            ? 'Novo abastecimento'
            : 'Editar abastecimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Combustivel>(
              value: _combustivel,
              decoration: const InputDecoration(
                labelText: 'Tipo de combustível',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: Combustivel.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.rotulo)))
                  .toList(),
              onChanged: (c) => setState(() => _combustivel = c!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço por litro',
                prefixText: 'R\$ ',
                hintText: '5,89',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _validarPositivo(v, 'o preço'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _kmCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quilometragem do veículo',
                suffixText: 'km',
                hintText: '45210',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final erro = _validarPositivo(v, 'a quilometragem');
                if (erro != null) return erro;
                return Calculos.validarQuilometragem(
                  existentes: widget.existentes,
                  km: Fmt.lerNumero(v)!,
                  dataHora: _dataHora,
                  ignorarId: widget.editar?.id,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _litrosCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Litros abastecidos',
                suffixText: 'L',
                hintText: '40,5',
                border: OutlineInputBorder(),
              ),
              validator: (v) => _validarPositivo(v, 'os litros'),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: Text(Fmt.dataHora(_dataHora)),
                subtitle: const Text('Data e horário do abastecimento'),
                trailing: const Icon(Icons.edit),
                onTap: _escolherData,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Valor total'),
                subtitle: const Text('Preço por litro × litros'),
                trailing: Text(
                  total != null ? Fmt.moeda(total) : '—',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar abastecimento'),
            ),
          ],
        ),
      ),
    );
  }
}
