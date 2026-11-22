import '../utils/condicoes.dart';

/// Previsão de um único dia.
class PrevisaoDia {
  final DateTime? data;
  final String sigla;
  final int? minima;
  final int? maxima;
  final double? iuv;

  const PrevisaoDia({
    required this.data,
    required this.sigla,
    required this.minima,
    required this.maxima,
    required this.iuv,
  });

  String get descricao => Condicoes.descricao(sigla);

  Map<String, dynamic> toJson() => {
        'data': data?.toIso8601String(),
        'sigla': sigla,
        'minima': minima,
        'maxima': maxima,
        'iuv': iuv,
      };

  factory PrevisaoDia.fromJson(Map<String, dynamic> json) => PrevisaoDia(
        data: DateTime.tryParse((json['data'] ?? '').toString()),
        sigla: (json['sigla'] ?? '').toString(),
        minima: json['minima'] as int?,
        maxima: json['maxima'] as int?,
        iuv: (json['iuv'] as num?)?.toDouble(),
      );
}

/// Previsão completa (quatro dias) de uma cidade.
class Previsao {
  final String cidade;
  final String uf;
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  /// Momento em que o app salvou esta previsão localmente.
  final DateTime obtidaEm;

  /// Indica se os dados vieram do armazenamento local (sem conexão).
  final bool doCache;

  const Previsao({
    required this.cidade,
    required this.uf,
    required this.atualizacao,
    required this.dias,
    required this.obtidaEm,
    this.doCache = false,
  });

  Previsao copyWith({bool? doCache}) => Previsao(
        cidade: cidade,
        uf: uf,
        atualizacao: atualizacao,
        dias: dias,
        obtidaEm: obtidaEm,
        doCache: doCache ?? this.doCache,
      );

  Map<String, dynamic> toJson() => {
        'cidade': cidade,
        'uf': uf,
        'atualizacao': atualizacao?.toIso8601String(),
        'dias': dias.map((d) => d.toJson()).toList(),
        'obtidaEm': obtidaEm.toIso8601String(),
      };

  factory Previsao.fromJson(Map<String, dynamic> json) => Previsao(
        cidade: (json['cidade'] ?? '').toString(),
        uf: (json['uf'] ?? '').toString(),
        atualizacao: DateTime.tryParse((json['atualizacao'] ?? '').toString()),
        dias: ((json['dias'] as List?) ?? [])
            .map((e) => PrevisaoDia.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        obtidaEm: DateTime.tryParse((json['obtidaEm'] ?? '').toString()) ??
            DateTime.now(),
      );
}
