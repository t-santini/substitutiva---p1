import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:previsao_tempo/utils/condicoes.dart';

void main() {
  test('converte siglas do CPTEC em descrições', () {
    expect(Condicoes.descricao('ps'), 'Predomínio de sol');
    expect(Condicoes.descricao('c'), 'Chuva');
    expect(Condicoes.descricao(''), 'Condição não informada');
    expect(Condicoes.descricao('zz'), contains('desconhecida'));
  });

  test('remove acentos do nome da cidade', () {
    expect(CptecService.removerAcentos('São José dos Campos'),
        'Sao Jose dos Campos');
    expect(CptecService.removerAcentos('Jacareí'), 'Jacarei');
  });
}
