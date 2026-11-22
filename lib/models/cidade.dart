/// Localidade retornada pelo serviço de busca de cidades do CPTEC/INPE.
class Cidade {
  /// Identificador da localidade, retornado pelo próprio serviço.
  final String id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});

  String get nomeCompleto => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'uf': uf};

  factory Cidade.fromJson(Map<String, dynamic> json) => Cidade(
        id: (json['id'] ?? '').toString(),
        nome: (json['nome'] ?? '').toString(),
        uf: (json['uf'] ?? '').toString(),
      );

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
