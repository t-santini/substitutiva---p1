import '../models/abastecimento.dart';

/// Regras de cálculo dos indicadores do dashboard.
///
/// Todos os abastecimentos completam o tanque. A partir do segundo:
///  - distância = km atual − km do abastecimento anterior
///  - km/L      = distância ÷ litros do abastecimento atual
///  - R$/km     = valor total do abastecimento atual ÷ distância
/// O primeiro serve só como referência (sem km/L nem R$/km).
class Calculos {
  Calculos._();

  /// Ordena por data/hora (e km como desempate).
  static List<Abastecimento> ordenar(List<Abastecimento> lista) {
    final copia = [...lista];
    copia.sort((a, b) {
      final c = a.dataHora.compareTo(b.dataHora);
      return c != 0 ? c : a.quilometragem.compareTo(b.quilometragem);
    });
    return copia;
  }

  static List<Indicador> indicadores(List<Abastecimento> lista) {
    final ordenada = ordenar(lista);
    final resultado = <Indicador>[];
    for (var i = 0; i < ordenada.length; i++) {
      final atual = ordenada[i];
      if (i == 0) {
        resultado.add(Indicador(abastecimento: atual));
        continue;
      }
      final distancia = atual.quilometragem - ordenada[i - 1].quilometragem;
      if (distancia <= 0 || atual.litros <= 0) {
        // Dados inconsistentes: não calcula para evitar divisão por zero.
        resultado.add(Indicador(abastecimento: atual));
        continue;
      }
      resultado.add(Indicador(
        abastecimento: atual,
        distancia: distancia,
        kmPorLitro: distancia / atual.litros,
        custoPorKm: atual.valorTotal / distancia,
      ));
    }
    return resultado;
  }

  /// Valida a quilometragem de um novo/alterado abastecimento: precisa ser
  /// maior que a do anterior e menor que a do posterior (por data/hora).
  /// Retorna a mensagem de erro, ou null se estiver ok.
  static String? validarQuilometragem({
    required List<Abastecimento> existentes,
    required double km,
    required DateTime dataHora,
    String? ignorarId,
  }) {
    final outros = existentes.where((a) => a.id != ignorarId).toList();
    Abastecimento? anterior;
    Abastecimento? posterior;
    for (final a in ordenar(outros)) {
      if (!a.dataHora.isAfter(dataHora)) {
        anterior = a;
      } else {
        posterior ??= a;
      }
    }
    if (anterior != null && km <= anterior.quilometragem) {
      return 'Deve ser maior que ${anterior.quilometragem.toStringAsFixed(0)} km '
          '(abastecimento anterior).';
    }
    if (posterior != null && km >= posterior.quilometragem) {
      return 'Deve ser menor que ${posterior.quilometragem.toStringAsFixed(0)} km '
          '(abastecimento posterior).';
    }
    return null;
  }

  static double? media(Iterable<double?> valores) {
    final v = valores.whereType<double>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }
}
