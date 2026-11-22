import 'package:flutter/material.dart';

/// Conversão das siglas de condição do tempo do CPTEC/INPE
/// em descrições compreensíveis e ícones.
/// Fonte: documentação oficial do CPTEC/INPE (http://servicos.cptec.inpe.br/XML/).
class Condicoes {
  Condicoes._();

  static const Map<String, String> _descricoes = {
    'ec': 'Encoberto com chuvas isoladas',
    'ci': 'Chuvas isoladas',
    'c': 'Chuva',
    'in': 'Instável',
    'pp': 'Possibilidade de pancadas de chuva',
    'cm': 'Chuva pela manhã',
    'cn': 'Chuva à noite',
    'pt': 'Pancadas de chuva à tarde',
    'pm': 'Pancadas de chuva pela manhã',
    'np': 'Nublado e pancadas de chuva',
    'pc': 'Pancadas de chuva',
    'pn': 'Parcialmente nublado',
    'cv': 'Chuvisco',
    'ch': 'Chuvoso',
    't': 'Tempestade',
    'ps': 'Predomínio de sol',
    'e': 'Encoberto',
    'n': 'Nublado',
    'cl': 'Céu claro',
    'nv': 'Nevoeiro',
    'g': 'Geada',
    'ne': 'Neve',
    'nd': 'Não definido',
    'pnt': 'Pancadas de chuva à noite',
    'psc': 'Possibilidade de chuva',
    'pcm': 'Possibilidade de chuva pela manhã',
    'pct': 'Possibilidade de chuva à tarde',
    'pcn': 'Possibilidade de chuva à noite',
    'npt': 'Nublado com pancadas à tarde',
    'npn': 'Nublado com pancadas à noite',
    'ncn': 'Nublado com possibilidade de chuva à noite',
    'nct': 'Nublado com possibilidade de chuva à tarde',
    'ncm': 'Nublado com possibilidade de chuva pela manhã',
    'npm': 'Nublado com pancadas pela manhã',
    'npp': 'Nublado com possibilidade de chuva',
    'vn': 'Variação de nebulosidade',
    'ct': 'Chuva à tarde',
    'ppn': 'Possibilidade de pancadas de chuva à noite',
    'ppt': 'Possibilidade de pancadas de chuva à tarde',
    'ppm': 'Possibilidade de pancadas de chuva pela manhã',
  };

  static String descricao(String sigla) {
    final s = sigla.trim().toLowerCase();
    if (s.isEmpty) return 'Condição não informada';
    return _descricoes[s] ?? 'Condição desconhecida ($s)';
  }

  static IconData icone(String sigla) {
    final s = sigla.trim().toLowerCase();
    switch (s) {
      case 'cl':
        return Icons.wb_sunny;
      case 'ps':
        return Icons.wb_sunny_outlined;
      case 'pn':
      case 'vn':
        return Icons.wb_cloudy_outlined;
      case 'n':
      case 'e':
        return Icons.cloud;
      case 't':
        return Icons.thunderstorm;
      case 'nv':
        return Icons.foggy;
      case 'g':
      case 'ne':
        return Icons.ac_unit;
      case 'cv':
        return Icons.grain;
      case 'nd':
      case '':
        return Icons.help_outline;
    }
    // Demais siglas envolvem chuva/pancadas.
    if (_descricoes.containsKey(s)) return Icons.water_drop;
    return Icons.help_outline;
  }

  static Color cor(String sigla) {
    final icon = icone(sigla);
    if (icon == Icons.wb_sunny || icon == Icons.wb_sunny_outlined) {
      return Colors.orange;
    }
    if (icon == Icons.thunderstorm) return Colors.deepPurple;
    if (icon == Icons.water_drop || icon == Icons.grain) return Colors.blue;
    if (icon == Icons.ac_unit) return Colors.lightBlue;
    return Colors.blueGrey;
  }

  /// Classificação do índice UV segundo a OMS.
  static String classificacaoUv(double iuv) {
    if (iuv < 3) return 'Baixo';
    if (iuv < 6) return 'Moderado';
    if (iuv < 8) return 'Alto';
    if (iuv < 11) return 'Muito alto';
    return 'Extremo';
  }
}
