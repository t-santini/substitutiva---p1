import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';

/// Persistência local com shared_preferences (dados em JSON).
///
/// Chaves:
///  - `veiculo`         → JSON do único veículo cadastrado
///  - `abastecimentos`  → lista de JSON dos abastecimentos desse veículo
class StorageService {
  static const _kVeiculo = 'veiculo';
  static const _kAbastecimentos = 'abastecimentos';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------- Veículo ----------
  Future<Veiculo?> carregarVeiculo() async {
    final s = (await _prefs).getString(_kVeiculo);
    if (s == null) return null;
    try {
      return Veiculo.fromJson(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  Future<void> salvarVeiculo(Veiculo v) async =>
      (await _prefs).setString(_kVeiculo, jsonEncode(v.toJson()));

  /// Exclui o veículo e TODOS os abastecimentos associados.
  Future<void> excluirVeiculo() async {
    final p = await _prefs;
    await p.remove(_kVeiculo);
    await p.remove(_kAbastecimentos);
  }

  // ---------- Abastecimentos ----------
  Future<List<Abastecimento>> carregarAbastecimentos() async {
    final lista = (await _prefs).getStringList(_kAbastecimentos) ?? [];
    final res = <Abastecimento>[];
    for (final s in lista) {
      try {
        res.add(Abastecimento.fromJson(jsonDecode(s)));
      } catch (_) {/* registro inválido ignorado */}
    }
    return res;
  }

  Future<void> _salvarLista(List<Abastecimento> lista) async =>
      (await _prefs).setStringList(
          _kAbastecimentos, lista.map((a) => jsonEncode(a.toJson())).toList());

  /// Insere ou atualiza (pelo id).
  Future<void> salvarAbastecimento(Abastecimento a) async {
    final lista = await carregarAbastecimentos();
    final i = lista.indexWhere((x) => x.id == a.id);
    if (i >= 0) {
      lista[i] = a;
    } else {
      lista.add(a);
    }
    await _salvarLista(lista);
  }

  Future<void> excluirAbastecimento(String id) async {
    final lista = await carregarAbastecimentos();
    lista.removeWhere((a) => a.id == id);
    await _salvarLista(lista);
  }
}
