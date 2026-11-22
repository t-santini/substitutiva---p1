enum Combustivel {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  final String rotulo;
  const Combustivel(this.rotulo);

  static Combustivel porNome(String? nome) => Combustivel.values.firstWhere(
        (c) => c.name == nome,
        orElse: () => Combustivel.gasolina,
      );
}

/// Registro de um abastecimento (sempre de tanque cheio).
class Abastecimento {
  final String id;
  final Combustivel combustivel;
  final double precoLitro;
  final double quilometragem;
  final double litros;
  final DateTime dataHora;

  const Abastecimento({
    required this.id,
    required this.combustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  /// Valor total = preço por litro × litros.
  double get valorTotal => precoLitro * litros;

  Map<String, dynamic> toJson() => {
        'id': id,
        'combustivel': combustivel.name,
        'precoLitro': precoLitro,
        'quilometragem': quilometragem,
        'litros': litros,
        'dataHora': dataHora.toIso8601String(),
      };

  factory Abastecimento.fromJson(Map<String, dynamic> j) => Abastecimento(
        id: (j['id'] ?? '').toString(),
        combustivel: Combustivel.porNome(j['combustivel'] as String?),
        precoLitro: (j['precoLitro'] as num?)?.toDouble() ?? 0,
        quilometragem: (j['quilometragem'] as num?)?.toDouble() ?? 0,
        litros: (j['litros'] as num?)?.toDouble() ?? 0,
        dataHora:
            DateTime.tryParse((j['dataHora'] ?? '').toString()) ?? DateTime.now(),
      );
}

/// Abastecimento com os indicadores calculados em relação ao anterior.
class Indicador {
  final Abastecimento abastecimento;

  /// Nulos no primeiro abastecimento (referência inicial).
  final double? distancia;
  final double? kmPorLitro;
  final double? custoPorKm;

  const Indicador({
    required this.abastecimento,
    this.distancia,
    this.kmPorLitro,
    this.custoPorKm,
  });

  bool get temIndicadores => kmPorLitro != null && custoPorKm != null;
}
