import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';

/// Erro amigável lançado pelo serviço, com mensagem pronta para a interface.
class CptecException implements Exception {
  final String mensagem;
  const CptecException(this.mensagem);
  @override
  String toString() => mensagem;
}

/// Cliente HTTP para os serviços XML do CPTEC/INPE.
class CptecService {
  static const String _base = 'https://servicos.cptec.inpe.br/XML';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  CptecService({http.Client? client}) : _client = client ?? http.Client();

  /// Busca localidades pelo nome. O serviço espera o nome sem acentos.
  Future<List<Cidade>> buscarCidades(String nome) async {
    final termo = removerAcentos(nome.trim()).toLowerCase();
    if (termo.isEmpty) return [];
    final uri = Uri.parse('$_base/listaCidades')
        .replace(queryParameters: {'city': termo});
    final doc = await _getXml(uri);

    final raiz = doc.findAllElements('cidades');
    if (raiz.isEmpty) {
      throw const CptecException('Resposta inválida do serviço de cidades.');
    }

    final cidades = <Cidade>[];
    for (final el in doc.findAllElements('cidade')) {
      final id = _texto(el, 'id');
      final nomeCidade = _texto(el, 'nome');
      if (id == null || id.isEmpty || nomeCidade == null) continue;
      cidades.add(Cidade(id: id, nome: nomeCidade, uf: _texto(el, 'uf') ?? ''));
    }
    return cidades;
  }

  /// Consulta a previsão para quatro dias de uma localidade.
  Future<Previsao> buscarPrevisao(String codigo) async {
    final uri = Uri.parse('$_base/cidade/$codigo/previsao.xml');
    final doc = await _getXml(uri);

    final raiz = doc.rootElement;
    if (raiz.name.local != 'cidade') {
      throw const CptecException('Resposta inválida do serviço de previsão.');
    }

    final dias = <PrevisaoDia>[];
    for (final el in raiz.findElements('previsao')) {
      dias.add(PrevisaoDia(
        data: DateTime.tryParse(_texto(el, 'dia') ?? ''),
        sigla: _texto(el, 'tempo') ?? '',
        minima: int.tryParse(_texto(el, 'minima') ?? ''),
        maxima: int.tryParse(_texto(el, 'maxima') ?? ''),
        iuv: double.tryParse((_texto(el, 'iuv') ?? '').replaceAll(',', '.')),
      ));
    }

    return Previsao(
      cidade: _texto(raiz, 'nome') ?? '',
      uf: _texto(raiz, 'uf') ?? '',
      atualizacao: DateTime.tryParse(_texto(raiz, 'atualizacao') ?? ''),
      dias: dias,
      obtidaEm: DateTime.now(),
    );
  }

  Future<XmlDocument> _getXml(Uri uri) async {
    http.Response resp;
    try {
      resp = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const CptecException(
          'O serviço demorou demais para responder. Tente novamente.');
    } on SocketException {
      throw const CptecException(
          'Sem conexão com a internet. Verifique sua rede.');
    } on http.ClientException {
      throw const CptecException(
          'Falha de conexão com o serviço do CPTEC/INPE.');
    }

    if (resp.statusCode >= 500) {
      throw const CptecException(
          'O serviço do CPTEC/INPE está indisponível no momento.');
    }
    if (resp.statusCode != 200) {
      throw CptecException(
          'O serviço retornou um erro (código ${resp.statusCode}).');
    }

    // O CPTEC responde em ISO-8859-1; decodificamos como latin1.
    final corpo = latin1.decode(resp.bodyBytes, allowInvalid: true);
    try {
      return XmlDocument.parse(corpo);
    } on XmlException {
      throw const CptecException('O serviço retornou uma resposta inválida.');
    }
  }

  /// Retorna o texto de um elemento filho, ou null se ausente/vazio.
  String? _texto(XmlElement pai, String nome) {
    final el = pai.getElement(nome);
    final t = el?.innerText.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String removerAcentos(String s) {
    const com = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const sem = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = com.indexOf(ch);
      buf.write(i >= 0 ? sem[i] : ch);
    }
    return buf.toString();
  }
}
