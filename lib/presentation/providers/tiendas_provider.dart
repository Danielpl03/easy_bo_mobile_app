import 'dart:async';

import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';

class TiendasProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService = LocalStorageService();

  TiendasProvider(this._supabaseService) {
    getTiendas();
    getLocalidades();
    selectAll();
  }

  List<Tienda> _tiendas = [];
  final List<Tienda> _tiendasSeleccionadas = [];
  List<Tienda> get tiendas => _tiendas;
  List<Tienda> get tiendasSeleccionadas => _tiendasSeleccionadas;

  List<Localidad> _localidades = [];
  final List<Localidad> _localidadesSeleccionadas = [];
  List<Localidad> get localidades => _localidades;
  List<Localidad> get localidadesSeleccionadas => _localidadesSeleccionadas;


  Future<void> getTiendas({bool forceUpdate = false}) async {

    if ( !forceUpdate ){
      final tiendas = await _localStorageService.getTiendas();
      if(tiendas.isNotEmpty){
        _tiendas = tiendas;
        notifyListeners();
        return;
      }
    }
    
    _tiendas = await _supabaseService.getTiendas();
    unawaited(updateTiendas(_tiendas));
    notifyListeners();
  }

  Future<void> getLocalidades({bool forceUpdate = false}) async {
    if ( !forceUpdate ){
      final localidades = await _localStorageService.getLocalidades();
      if(localidades.isNotEmpty){
        _localidades = localidades;
        notifyListeners();
        return;
      }
    }
    _localidades = await _supabaseService.getLocalidades();
    unawaited(updateLocalidades(_localidades));
    notifyListeners();
  }

  Future<void> updateTiendas(List<Tienda> tiendas) async{
    _localStorageService.saveTiendas(tiendas);
  }
  Future<void> updateLocalidades(List<Localidad> localidades) async{
    _localStorageService.saveLocalidades(localidades);
  }

  void selectAll(){
    _tiendas.forEach(seleccionarTienda);
  }

  void seleccionarTienda(Tienda tienda) {
    if (_tiendasSeleccionadas.contains(tienda)) {
      _tiendasSeleccionadas.remove(tienda);
      // Deseleccionar todas las localidades de la tienda
      _localidadesSeleccionadas.removeWhere(
        (localidad) => localidad.idTienda == tienda.idTienda,
      );
    } else {
      _tiendasSeleccionadas.add(tienda);
      // Seleccionar todas las localidades de la tienda
      _localidades.where((l) => l.idTienda == tienda.idTienda).forEach((localidad) {
        if (!_localidadesSeleccionadas.contains(localidad)) {
          _localidadesSeleccionadas.add(localidad);
        }
      });
    }
    notifyListeners();
  }

  void seleccionarLocalidad(Localidad localidad) {
    if (_localidadesSeleccionadas.contains(localidad)) {
      _localidadesSeleccionadas.remove(localidad);
    } else {
      _localidadesSeleccionadas.add(localidad);
    }
    notifyListeners();
  }
  
}
