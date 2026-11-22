import 'package:flutter/material.dart';

import '../services/fipe_service.dart';

/// Tela genérica de seleção com busca (usada para marcas e modelos).
/// Retorna o [ItemFipe] escolhido via Navigator.pop.
class SelecaoScreen extends StatefulWidget {
  final String titulo;
  final Future<List<ItemFipe>> Function() carregar;

  const SelecaoScreen({super.key, required this.titulo, required this.carregar});

  @override
  State<SelecaoScreen> createState() => _SelecaoScreenState();
}

class _SelecaoScreenState extends State<SelecaoScreen> {
  List<ItemFipe> _itens = [];
  String _filtro = '';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final itens = await widget.carregar();
      if (mounted) setState(() => _itens = itens);
    } on FipeException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro inesperado ao carregar a lista.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _itens
        .where((i) => i.nome.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Filtrar...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, size: 56),
                            const SizedBox(height: 8),
                            Text(_erro!, textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            FilledButton(
                                onPressed: _buscar,
                                child: const Text('Tentar novamente')),
                          ],
                        ),
                      )
                    : filtrados.isEmpty
                        ? const Center(child: Text('Nenhum item encontrado.'))
                        : ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(filtrados[i].nome),
                              onTap: () =>
                                  Navigator.of(context).pop(filtrados[i]),
                            ),
                          ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Dados: BrasilAPI (Tabela FIPE)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
