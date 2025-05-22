// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detalle_pedido.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DetallePedidoAdapter extends TypeAdapter<DetallePedido> {
  @override
  final int typeId = 10;

  @override
  DetallePedido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetallePedido(
      idPedido: fields[0] as int,
      idProducto: fields[1] as int,
      cantidad: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DetallePedido obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.idPedido)
      ..writeByte(1)
      ..write(obj.idProducto)
      ..writeByte(2)
      ..write(obj.cantidad);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetallePedidoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
