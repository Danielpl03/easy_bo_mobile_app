// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movimiento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MovimientoAdapter extends TypeAdapter<Movimiento> {
  @override
  final int typeId = 8;

  @override
  Movimiento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Movimiento(
      idMovimiento: fields[0] as int,
      idProducto: fields[1] as int,
      cantidad: fields[2] as int,
      precioProducto: fields[3] as num,
      idDescuento: fields[4] as int?,
      idPago: fields[5] as int?,
      importe: fields[6] as num?,
      saldoProducto: fields[7] as int?,
      espejo: fields[8] as bool,
      idDocumento: fields[9] as String,
      descuento: fields[10] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, Movimiento obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.idMovimiento)
      ..writeByte(1)
      ..write(obj.idProducto)
      ..writeByte(2)
      ..write(obj.cantidad)
      ..writeByte(3)
      ..write(obj.precioProducto)
      ..writeByte(4)
      ..write(obj.idDescuento)
      ..writeByte(5)
      ..write(obj.idPago)
      ..writeByte(6)
      ..write(obj.importe)
      ..writeByte(7)
      ..write(obj.saldoProducto)
      ..writeByte(8)
      ..write(obj.espejo)
      ..writeByte(9)
      ..write(obj.idDocumento)
      ..writeByte(10)
      ..write(obj.descuento);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovimientoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
