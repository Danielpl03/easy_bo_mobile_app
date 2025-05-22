// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pedido.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PedidoAdapter extends TypeAdapter<Pedido> {
  @override
  final int typeId = 9;

  @override
  Pedido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pedido(
      idPedido: fields[0] as int,
      fecha: fields[1] as DateTime,
      idTienda: fields[2] as int,
      estado: fields[3] as String,
      observaciones: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Pedido obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.idPedido)
      ..writeByte(1)
      ..write(obj.fecha)
      ..writeByte(2)
      ..write(obj.idTienda)
      ..writeByte(3)
      ..write(obj.estado)
      ..writeByte(4)
      ..write(obj.observaciones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PedidoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
