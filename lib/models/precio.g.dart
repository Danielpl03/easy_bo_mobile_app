// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'precio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrecioAdapter extends TypeAdapter<Precio> {
  @override
  final int typeId = 5;

  @override
  Precio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Precio(
      idPrecio: fields[0] as int,
      idProducto: fields[1] as int,
      idMoneda: fields[2] as int,
      precio: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Precio obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.idPrecio)
      ..writeByte(1)
      ..write(obj.idProducto)
      ..writeByte(2)
      ..write(obj.idMoneda)
      ..writeByte(3)
      ..write(obj.precio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
