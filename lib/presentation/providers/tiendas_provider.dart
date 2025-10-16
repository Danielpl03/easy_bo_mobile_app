import 'dart:async';
import 'dart:io';

import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart';
import 'package:easy_bo_mobile_app/models/tienda.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class TiendasProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService = LocalStorageService();

  bool _cargando = false;
  bool get cargando => _cargando;

  Mensaje? _message;
  Mensaje? get message => _message;

  bool _isDisposed = false;
  Future? _pendingRequest;

  @override
  void dispose() {
    _isDisposed = true;
    cancelPendingRequest();
    super.dispose();
  }

  void cancelPendingRequest() {
    if (_pendingRequest != null) {
      _pendingRequest!.ignore();
      _pendingRequest = null;
    }
  }

  void _actualizarEstado() {
    if (!_isDisposed) notifyListeners();
  }

  void _mostrarMensaje(Mensaje mensaje) {
    _message = mensaje;
    _actualizarEstado();
  }

  void clearMensaje() {
    _message = Mensaje();
    _actualizarEstado();
  }

  TiendasProvider(this._supabaseService) {
    getTiendasConLocalidades();
    // selectAll();
    // cargarEnSegundoPlano();
  }

  List<Tienda> _tiendas = [];
  final List<Tienda> _tiendasSeleccionadas = [];
  List<Tienda> get tiendas => _tiendas;
  List<Tienda> get tiendasSeleccionadas => _tiendasSeleccionadas;

  List<Localidad> _localidades = [];
  final List<Localidad> _localidadesSeleccionadas = [];
  List<Localidad> get localidades => _localidades;
  List<Localidad> get localidadesSeleccionadas => _localidadesSeleccionadas;

  Future<void> cargarEnSegundoPlano() async {
    unawaited(getTiendas(forceUpdate: true));
    unawaited(getLocalidades(forceUpdate: true));
    notifyListeners();
  }

  Future<void> getTiendasConLocalidades({bool forceUpdate = false}) async {
    cancelPendingRequest();
    _message = Mensaje();
    _cargando = true;

    final completer = Completer();
    _pendingRequest = completer.future;

    _actualizarEstado();

    if (!forceUpdate) {
      final tiendas = await _localStorageService.getTiendas();
      if (tiendas.isNotEmpty) {
        _tiendas = tiendas;
        final localidades = await _localStorageService.getLocalidades();
        if (localidades.isNotEmpty) {
          _localidades = localidades;
          _cargando = false;
          notifyListeners();
          return;
        }
      }
    }
    try {
      _tiendas = await _supabaseService.getTiendas();
      unawaited(updateTiendas(_tiendas));
      _localidades = await _supabaseService.getLocalidades();
      unawaited(updateLocalidades(_localidades));
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Tiendas actualizadas',
          tipoMensaje: TipoMensaje.succes,
        ),
      );
    } on SocketException catch (_) {
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Sin conexión',
          tipoMensaje: TipoMensaje.error,
        ),
      );
    } on PostgrestException catch (e) {
      _mostrarMensaje(
        Mensaje(
          mensaje: 'Error en Supabase: ${e.message}',
          tipoMensaje: TipoMensaje.error,
        ),
      );
    } finally {
      _cargando = false;
      if (!completer.isCompleted) completer.complete();
      _actualizarEstado();
    }

    _cargando = false;
    notifyListeners();
  }

  Future<void> getTiendas({bool forceUpdate = false}) async {
    if (!forceUpdate) {
      final tiendas = await _localStorageService.getTiendas();
      if (tiendas.isNotEmpty) {
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
    if (!forceUpdate) {
      final localidades = await _localStorageService.getLocalidades();
      if (localidades.isNotEmpty) {
        _localidades = localidades;
        notifyListeners();
        return;
      }
    }
    _localidades = await _supabaseService.getLocalidades();
    unawaited(updateLocalidades(_localidades));
    notifyListeners();
  }

  Future<void> updateTiendas(List<Tienda> tiendas) async {
    _localStorageService.saveTiendas(tiendas);
  }

  Future<void> updateLocalidades(List<Localidad> localidades) async {
    _localStorageService.saveLocalidades(localidades);
  }

  void selectAll() {
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
      _localidades.where((l) => l.idTienda == tienda.idTienda).forEach((
        localidad,
      ) {
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

  Tienda getTienda(idTienda) {
    return tiendas.firstWhere((t) => t.idTienda == idTienda);
  }

  Tienda getTiendaByLocalidad(idLocalidad) {
    int idTienda =
        localidades.firstWhere((l) => l.idLocalidad == idLocalidad).idTienda;
    return tiendas.firstWhere((t) => t.idTienda == idTienda);
  }

  Localidad getLocalidad(idLocalidad) {
    return localidades.firstWhere((l) => l.idLocalidad == idLocalidad);
  }

  List<Localidad> getLocalidadesByTienda(idTienda) {
    return localidades.where((l) => l.idTienda == idTienda).toList();
  }
}
