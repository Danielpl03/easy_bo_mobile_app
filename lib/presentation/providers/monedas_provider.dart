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
    getMonedas().then((_) {
      try {
        _monedaSeleccionada = _monedas.firstWhere((m) => m.idMoneda == 1);
      } catch (e) {
        // Si no se encuentra la moneda con ID 1, usar la primera disponible o null
        _monedaSeleccionada = _monedas.isNotEmpty ? _monedas.first : null;
      }
    });
  }

  void setMonedaSeleccionada(Moneda moneda) {
    _monedaSeleccionada = moneda;
    notifyListeners();
  }

  void seleccionarMoneda(int idMoneda) {
    try {
      _monedaSeleccionada = _monedas.firstWhere((m) => m.idMoneda == idMoneda);
    } catch (e) {
      // Si no se encuentra la moneda, mantener la selección actual o usar null
      _monedaSeleccionada = null;
    }
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

  Moneda? getMoneda(int idMoneda) {
    try {
      return _monedas.firstWhere((m) => m.idMoneda == idMoneda);
    } catch (e) {
      // Si no se encuentra la moneda, retornar null
      return null;
    }
  }
}
