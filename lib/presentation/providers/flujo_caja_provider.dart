import 'package:easy_bo_mobile_app/models/pago.dart' show Pago;
import 'package:flutter/material.dart';
import 'package:easy_bo_mobile_app/models/flujo_caja.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResumenFlujo {
  Pago formaPago;
  num monto;
  num importe;

  ResumenFlujo({
    required this.formaPago,
    required this.importe,
    required this.monto,
  });
}

class FlujoCajaProvider extends ChangeNotifier {
  FlujoCajaProvider() {
    final ahora = DateTime.now();

    // Calcular inicio de la semana (lunes)
    final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));

    // Calcular fin de la semana (domingo)
    final finSemana = inicioSemana.add(Duration(days: 6));

    rangoFechas = DateTimeRange(
      start: DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day),
      end: DateTime(finSemana.year, finSemana.month, finSemana.day, 23, 59, 59),
    );

    getPagos();
  }

  Future<void> getPagos() async {
    List<Pago> pagosR = await _localStorageService.getPagos();
    if (pagosR.isEmpty) {
      pagosR = await _supabaseService.getPagos();
      if (pagosR.isEmpty) {
        throw Exception("No hay metodos de pago");
      }
      _localStorageService.savePagos(pagosR);
    }
    _pagos = pagosR;
  }

  Pago getPago(int idPago) {
    return _pagos.firstWhere(
      (p) => p.idPago == idPago,
      orElse:
          () => Pago(idPago: -1, tipoPago: "", idMoneda: -1, efectivo: false),
    );
  }

  DateTimeRange _rangoFechas = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );
  DateTimeRange get rangoFechas => _rangoFechas;

  set rangoFechas(DateTimeRange nuevoRango) {
    _rangoFechas = nuevoRango;
    notifyListeners();
  }

  final LocalStorageService _localStorageService = LocalStorageService();
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );

  List<FlujoCaja> _flujos = [];
  List<FlujoCaja> get flujos => _flujos;

  List<Pago> _pagos = [];
  List<Pago> get pagos => _pagos;

  Map<int, Map<int, ResumenFlujo>> _resumenFlujos = {};
  Map<int, Map<int, ResumenFlujo>> get resumenFlujos => _resumenFlujos;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  Future<void> cargarFlujosLocal() async {
    _flujos = await _localStorageService.getFlujosCaja();
    notifyListeners();
  }

  Future<void> cargarFlujosRemoto({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      // _cargando = true;
      // notifyListeners();
      final flujosRemotos = await _supabaseService.getFlujosCaja(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      _flujos = flujosRemotos;
      await _localStorageService.saveFlujosCaja(_flujos);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      // _cargando = false;
      // notifyListeners();
    }
  }

  Future<void> getFlujos() async {
    cancelPendingRequest();
    _errorMessage = null;
    _cargando = true;
    _actualizarEstado();

    await cargarFlujosLocal();
    resumenPorLocalidadYMetodoPago();
    _actualizarEstado();

    final completer = Completer();
    _pendingRequest = completer.future;

    try {
      await cargarFlujosRemoto(
        fechaInicio: rangoFechas.start,
        fechaFin: rangoFechas.end,
      );
      resumenPorLocalidadYMetodoPago();
    } on SocketException catch (_) {
      _mostrarError(
        'Sin conexión - Mostrando datos locales (pueden no estar actualizados)',
      );
    } on PostgrestException catch (e) {
      _mostrarError('Error en Supabase: ${e.message}');
    } finally {
      _cargando = false;
      if (!completer.isCompleted) completer.complete();
      _actualizarEstado();
    }
  }

  void _mostrarError(String mensaje) {
    _errorMessage = mensaje;
    _actualizarEstado();
  }

  void clearError() {
    _errorMessage = null;
    _actualizarEstado();
  }

  void _actualizarEstado() {
    if (!_isDisposed) notifyListeners();
  }

  resumenPorLocalidadYMetodoPago() {
    final Map<int, Map<int, ResumenFlujo>> resumen = {};
    final flujosFiltrados =
        _flujos.where((f) {
          final fechaFlujo = f.fecha;
          bool cumpleFechaInicio = true;
          bool cumpleFechaFin = true;

          cumpleFechaInicio = _esMismoDiaOPosterior(
            fechaFlujo,
            rangoFechas.start,
          );
          cumpleFechaFin = _esMismoDiaOAnterior(fechaFlujo, rangoFechas.end);
          return cumpleFechaInicio && cumpleFechaFin;
        }).toList();

    for (final flujo in flujosFiltrados) {
      if (flujo.motivo == "FONDO_CAJA" || flujo.motivo == "ARQUEO") continue;
      resumen.putIfAbsent(
        flujo.idLocalidad,
        () => {
          flujo.formaPago: ResumenFlujo(
            formaPago: getPago(flujo.formaPago),
            importe: 0,
            monto: 0,
          ),
        },
      );
      ResumenFlujo? resumenFlujo =
            resumen[flujo.idLocalidad]![flujo.formaPago];
        resumenFlujo ??= ResumenFlujo(
          formaPago: getPago(flujo.formaPago),
          importe: 0,
          monto: 0,
        );
      if (flujo.tipo == "IN") {
        resumenFlujo.importe += flujo.importe;
        resumenFlujo.monto += flujo.monto!;
      } else if (flujo.tipo == "OUT") {
        resumenFlujo.importe -= flujo.importe;
        resumenFlujo.monto -= flujo.monto!;
      }
      resumen[flujo.idLocalidad]![flujo.formaPago] = resumenFlujo;
    }
    _resumenFlujos = resumen;
  }

  // Map<int, num> resumenPorMetodoPago(DateTime dia) {
  //   final resumen = <int, num>{};
  //   for (final flujo in _flujos.where((f) => _esMismoDia(f.fecha, dia))) {
  //     resumen[flujo.formaPago] = (resumen[flujo.formaPago] ?? 0) + flujo.importe;
  //   }
  //   return resumen;
  // }

  // bool _esMismoDia(DateTime a, DateTime b) {
  //   return a.year == b.year && a.month == b.month && a.day == b.day;
  // }

  bool _esMismoDiaOPosterior(DateTime fechaFlujo, DateTime fechaComparacion) {
    final fechaFlujoNormalizada = DateTime(
      fechaFlujo.year,
      fechaFlujo.month,
      fechaFlujo.day,
    );
    final fechaComparacionNormalizada = DateTime(
      fechaComparacion.year,
      fechaComparacion.month,
      fechaComparacion.day,
    );
    return fechaFlujoNormalizada.isAfter(fechaComparacionNormalizada) ||
        fechaFlujoNormalizada.isAtSameMomentAs(fechaComparacionNormalizada);
  }

  bool _esMismoDiaOAnterior(DateTime fechaFlujo, DateTime fechaComparacion) {
    final fechaFlujoNormalizada = DateTime(
      fechaFlujo.year,
      fechaFlujo.month,
      fechaFlujo.day,
    );
    final fechaComparacionNormalizada = DateTime(
      fechaComparacion.year,
      fechaComparacion.month,
      fechaComparacion.day,
    );
    return fechaFlujoNormalizada.isBefore(fechaComparacionNormalizada) ||
        fechaFlujoNormalizada.isAtSameMomentAs(fechaComparacionNormalizada);
  }

  Future<void> setRangoFechas(DateTimeRange nuevoRango) async {
    rangoFechas = nuevoRango;
    await getFlujos();
    notifyListeners();
  }
}
