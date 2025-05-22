import 'dart:async';

import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';

class MonedasProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService = LocalStorageService();

  List<Moneda> _monedas = [];
  Moneda? _monedaSeleccionada;

  List<Moneda> get monedas => _monedas;
  Moneda? get monedaSeleccionada => _monedaSeleccionada;



  MonedasProvider(this._supabaseService) {
    getMonedas().then( (_) => _monedaSeleccionada = _monedas.firstWhere((m) => m.idMoneda == 1));
  }

  void setMonedaSeleccionada(Moneda moneda) {
    _monedaSeleccionada = moneda;
    notifyListeners();
  }

  void seleccionarMoneda(int idMoneda) {
    _monedaSeleccionada = _monedas.firstWhere((m) => m.idMoneda == idMoneda);
    notifyListeners();
  }

  Future<void> getMonedas({bool forceUpdate = false}) async {
    if (!forceUpdate) {
      final monedas = await _localStorageService.getMonedas();
      if (monedas.isNotEmpty) {
        _monedas = monedas;
        return;
      }
    }

    _monedas = await _supabaseService.getMonedas();
    print('Monedas obtenidas de Supabase: ${_monedas.length}');
    unawaited(updateMonedas(_monedas));
  }

  Future<void> updateMonedas(List<Moneda> monedas) async {
    _localStorageService.saveMonedas(monedas);
  }
}
