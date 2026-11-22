import 'package:controle_combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/services/calculos.dart';
import 'package:flutter_test/flutter_test.dart';

Abastecimento ab(String id, double km, double litros, double preco, int dia) =>
    Abastecimento(
      id: id,
      combustivel: Combustivel.gasolina,
      precoLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: DateTime(2026, 11, dia, 10),
    );

void main() {
  test('valor total = preço × litros', () {
    expect(ab('1', 1000, 40, 5.5, 1).valorTotal, closeTo(220, 0.001));
  });

  test('primeiro abastecimento é referência e demais têm indicadores', () {
    final ind = Calculos.indicadores([
      ab('2', 1400, 32, 6.0, 5), // fora de ordem de propósito
      ab('1', 1000, 40, 5.5, 1),
    ]);
    expect(ind.first.temIndicadores, isFalse);
    expect(ind[1].distancia, 400);
    expect(ind[1].kmPorLitro, closeTo(12.5, 0.001)); // 400 / 32
    expect(ind[1].custoPorKm, closeTo(0.48, 0.001)); // 192 / 400
  });

  test('quilometragem deve ser maior que a do abastecimento anterior', () {
    final erro = Calculos.validarQuilometragem(
      existentes: [ab('1', 1000, 40, 5.5, 1)],
      km: 900,
      dataHora: DateTime(2026, 11, 2),
    );
    expect(erro, isNotNull);
  });
}
