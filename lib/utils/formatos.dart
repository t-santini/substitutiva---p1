import 'package:intl/intl.dart';

/// Formatação e leitura de números/datas no padrão brasileiro.
class Fmt {
  Fmt._();

  static final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
  static final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _diaMes = DateFormat('dd/MM', 'pt_BR');

  static String moeda(double v) => _moeda.format(v);
  static String dataHora(DateTime d) => _dataHora.format(d);
  static String data(DateTime d) => _data.format(d);
  static String diaMes(DateTime d) => _diaMes.format(d);

  static String numero(double v, [int casas = 2]) =>
      NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: casas)
          .format(v);

  /// Aceita "5,79", "5.79" e "1.234,56".
  static double? lerNumero(String? texto) {
    if (texto == null) return null;
    var t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (t.isEmpty) return null;
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }
    return double.tryParse(t);
  }
}
