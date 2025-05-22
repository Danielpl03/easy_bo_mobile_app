import 'package:easy_bo_mobile_app/models/detalle_pedido.dart';
import 'package:easy_bo_mobile_app/models/mensaje.dart' show Mensaje, TipoMensaje;
import 'package:easy_bo_mobile_app/models/pedido.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:easy_bo_mobile_app/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class PedidosProvider extends ChangeNotifier {
  final LocalStorageService _localStorage = LocalStorageService();
  List<Pedido> _pedidos = [];
  Pedido? _pedidoActual;

  List<Pedido> get pedidos => _pedidos;
  Pedido? get pedidoActual => _pedidoActual;

  bool puedeModificarPedido(Pedido pedido) {
    final ahora = DateTime.now();
    final horaActual = ahora.hour;
    final esMismoDia = DateUtils.isSameDay(pedido.fecha, ahora);
    
    // Si es el mismo día y antes de las 14:00, se puede modificar
    return esMismoDia && horaActual < 14;
  }

  bool puedeModificarObservaciones(Pedido pedido) {
    return true;
  }

  void setPedidoActual(Pedido? nuevoPedido) {
    if (nuevoPedido != null && !puedeModificarPedido(nuevoPedido)) {
      _message = Mensaje(
        mensaje: 'Los pedidos solo pueden modificarse antes de las 2:00 PM',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }
    _pedidoActual = nuevoPedido;
    actualizarEstado();
  }

  Mensaje? _message;
  Mensaje? get message => _message;

  void clearMensaje() {
    _message = Mensaje();
    actualizarEstado();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void actualizarEstado() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> cargarPedidos() async {
    final todosPedidos = await _localStorage.getPedidos();

    for( var dp in todosPedidos){
      dp.detalles = await _localStorage.getListDetallesPedido(dp.idPedido);
    }

    _pedidos = todosPedidos;
    actualizarEstado();
  }

  bool crearNuevoPedido(int idTienda) {
    _message = Mensaje();
    final horaActual = DateTime.now().hour;

    final fecha = horaActual < 14 ? DateTime.now() : DateTime.now().add(const Duration(days: 1));
    

    if (_pedidos.any(
      (p) => p.idTienda == idTienda && DateUtils.isSameDay(p.fecha, fecha),
    )) {
      _pedidoActual = _pedidos.firstWhere((p) => p.idTienda == idTienda && DateUtils.isSameDay(p.fecha, fecha));
      _message = Mensaje(mensaje: 'Ya existe un pedido para ${fecha.day == DateTime.now().day ? 'hoy' : DateFormat('dd/MM/yyyy').format(fecha)}', tipoMensaje: TipoMensaje.error);
      actualizarEstado();
      return false;
    }

    _pedidoActual = Pedido(
      idPedido: _pedidos.length + 1,
      fecha: fecha,
      idTienda: idTienda,
      estado: 'PENDIENTE',
      detalles: [],
    );
    _message = null;  
    actualizarEstado();
    return true;
  }

  Future<void> guardarPedido() async {
    if (_pedidoActual == null) return;

    // Verificar si se puede modificar el pedido
    if (!puedeModificarPedido(_pedidoActual!)) {
      _message = Mensaje(
        mensaje: 'Los pedidos solo pueden modificarse antes de las 2:00 PM',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }

    // Actualizar existente o crear nuevo
    final index = _pedidos.indexWhere(
      (p) => p.idPedido == _pedidoActual!.idPedido,
    );

    if (index >= 0) {
      _pedidos[index] = _pedidoActual!;
    } else {
      _pedidos.add(_pedidoActual!);
    }

    await _localStorage.savePedidoCompleto(_pedidoActual!);
    // _pedidoActual = null;
    actualizarEstado();
  }

  Future<void> actualizarObservaciones(String observaciones) async {
    if (_pedidoActual == null) return;

    // Verificar si se pueden modificar las observaciones
    if (!puedeModificarObservaciones(_pedidoActual!)) {
      _message = Mensaje(
        mensaje: 'Las observaciones solo pueden modificarse el mismo día del pedido',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }

    final pedidoActualizado = _pedidoActual!.copyWith(
      observaciones: observaciones,
      estado: 'MODIFICADO'
    );

    final index = _pedidos.indexWhere(
      (p) => p.idPedido == pedidoActualizado.idPedido,
    );

    if (index >= 0) {
      _pedidos[index] = pedidoActualizado;
    }

    await _localStorage.savePedidoCompleto(pedidoActualizado);
    _pedidoActual = pedidoActualizado;
    actualizarEstado();
  }

  void agregarDetallePedido(DetallePedido detalle, bool save) {
    if (_pedidoActual == null) return;

    // Verificar si se puede modificar el pedido
    if (!puedeModificarPedido(_pedidoActual!)) {
      _message = Mensaje(
        mensaje: 'Los pedidos solo pueden modificarse antes de las 2:00 PM',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }

    final index = _pedidoActual!.detalles.indexWhere(
      (d) => d.idProducto == detalle.idProducto,
    );

    if (index >= 0) {
      _pedidoActual!.detalles[index] = detalle;
    } else {
      _pedidoActual!.detalles.add(detalle);
    }

    if (save) {
     _localStorage.savePedidoCompleto(_pedidoActual!);
    }
    actualizarEstado();
  }

  void eliminarDetallePedido(DetallePedido detalle) {
    if (_pedidoActual == null) return;

    // Verificar si se puede modificar el pedido
    if (!puedeModificarPedido(_pedidoActual!)) {
      _message = Mensaje(
        mensaje: 'Los pedidos solo pueden modificarse antes de las 2:00 PM',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }

    _pedidoActual!.detalles.removeWhere((d) => d.idProducto == detalle.idProducto);
    actualizarEstado();
  }

  Future<void> cargarPedidoParaEdicion(int idPedido) async {
    final pedido = _pedidos.firstWhere((p) => p.idPedido == idPedido);
    
    // Verificar si se puede modificar el pedido
    if (!puedeModificarPedido(pedido)) {
      _message = Mensaje(
        mensaje: 'Los pedidos solo pueden modificarse antes de las 2:00 PM',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      return;
    }

    _pedidoActual = pedido;
    actualizarEstado();
  }

  Future<void> eliminarPedido(Pedido pedido) async {
    try {
      // Verificar si se puede eliminar el pedido (solo debe ser del día actual)
      if (!puedeModificarObservaciones(pedido)) {
        _message = Mensaje(
          mensaje: 'Los pedidos solo pueden eliminarse el mismo día',
          tipoMensaje: TipoMensaje.error
        );
        actualizarEstado();
        return;
      }

      // Eliminar el pedido de la lista local
      _pedidos.removeWhere((p) => p.idPedido == pedido.idPedido);
      
      // Eliminar el pedido y sus detalles del almacenamiento local
      await _localStorage.eliminarPedido(pedido);
      
      actualizarEstado();
    } catch (e) {
      _message = Mensaje(
        mensaje: 'Error al eliminar el pedido: $e',
        tipoMensaje: TipoMensaje.error
      );
      actualizarEstado();
      rethrow;
    }
  }
}
