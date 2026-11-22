/// Tipos de veículo aceitos pela API FIPE da BrasilAPI.
enum TipoVeiculo {
  carros('Carro'),
  motos('Moto'),
  caminhoes('Caminhão');

  final String rotulo;
  const TipoVeiculo(this.rotulo);

  static TipoVeiculo porNome(String? nome) => TipoVeiculo.values.firstWhere(
        (t) => t.name == nome,
        orElse: () => TipoVeiculo.carros,
      );
}

/// Único veículo cadastrado no aplicativo.
class Veiculo {
  final TipoVeiculo tipo;
  final String marcaCodigo;
  final String marca;
  final String modelo;
  final int ano;

  /// Cilindrada do motor em cilindradas (cc). Ex.: 1600.
  final int cilindrada;

  const Veiculo({
    required this.tipo,
    required this.marcaCodigo,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  String get descricao => '$marca $modelo';

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        'marcaCodigo': marcaCodigo,
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'cilindrada': cilindrada,
      };

  factory Veiculo.fromJson(Map<String, dynamic> j) => Veiculo(
        tipo: TipoVeiculo.porNome(j['tipo'] as String?),
        marcaCodigo: (j['marcaCodigo'] ?? '').toString(),
        marca: (j['marca'] ?? '').toString(),
        modelo: (j['modelo'] ?? '').toString(),
        ano: (j['ano'] as num?)?.toInt() ?? 0,
        cilindrada: (j['cilindrada'] as num?)?.toInt() ?? 0,
      );
}
