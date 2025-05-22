// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tienda.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TiendaAdapter extends TypeAdapter<Tienda> {
  @override
  final int typeId = 0;

  @override
  Tienda read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tienda(
      idTienda: fields[0] as int,
      nombre: fields[1] as String,
      direccion: fields[2] as String?,
      coordenadas: fields[3] as String?,
      telefono: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Tienda obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.idTienda)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.coordenadas)
      ..writeByte(4)
      ..write(obj.telefono);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TiendaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
