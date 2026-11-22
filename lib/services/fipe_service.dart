import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/veiculo.dart';

class FipeException implements Exception {
  final String mensagem;
  const FipeException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Item simples retornado pela API (nome + código).
class ItemFipe {
  final String nome;
  final String codigo;
  const ItemFipe(this.nome, this.codigo);
}

/// Consulta marcas e modelos na API FIPE da BrasilAPI.
/// Docs: https://brasilapi.com.br/docs#tag/FIPE
class FipeService {
  static const _base = 'https://brasilapi.com.br/api/fipe';
  static const _timeout = Duration(seconds: 20);

  final http.Client _client;
  FipeService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /fipe/marcas/v1/{tipoVeiculo}
  Future<List<ItemFipe>> marcas(TipoVeiculo tipo) async {
    final dados = await _get('$_base/marcas/v1/${tipo.name}');
    final itens = <ItemFipe>[];
    for (final e in dados) {
      if (e is Map && e['nome'] != null) {
        itens.add(ItemFipe(e['nome'].toString(), (e['valor'] ?? '').toString()));
      }
    }
    itens.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return itens;
  }

  /// GET /fipe/veiculos/v1/{tipoVeiculo}/{codigoMarca}
  /// Modelos da marca escolhida pelo usuário.
  Future<List<ItemFipe>> modelos(TipoVeiculo tipo, String codigoMarca) async {
    final dados = await _get('$_base/veiculos/v1/${tipo.name}/$codigoMarca');
    final vistos = <String>{};
    final itens = <ItemFipe>[];
    for (final e in dados) {
      if (e is Map && e['modelo'] != null) {
        final nome = e['modelo'].toString().trim();
        if (vistos.add(nome)) {
          itens.add(ItemFipe(nome, (e['valor'] ?? '').toString()));
        }
      }
    }
    itens.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return itens;
  }

  Future<List<dynamic>> _get(String url) async {
    http.Response resp;
    try {
      resp = await _client.get(Uri.parse(url)).timeout(_timeout);
    } on TimeoutException {
      throw const FipeException('A BrasilAPI demorou para responder.');
    } catch (_) {
      throw const FipeException(
          'Sem conexão com a internet ou BrasilAPI indisponível.');
    }
    if (resp.statusCode != 200) {
      throw FipeException('Erro ao consultar a BrasilAPI (${resp.statusCode}).');
    }
    try {
      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (json is List) return json;
      throw const FormatException();
    } catch (_) {
      throw const FipeException('Resposta inválida da BrasilAPI.');
    }
  }
}
