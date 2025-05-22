// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localidad.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalidadAdapter extends TypeAdapter<Localidad> {
  @override
  final int typeId = 1;

  @override
  Localidad read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Localidad(
      idLocalidad: fields[0] as int,
      localidad: fields[1] as String,
      idTienda: fields[2] as int,
      tipo: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Localidad obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.idLocalidad)
      ..writeByte(1)
      ..write(obj.localidad)
      ..writeByte(2)
      ..write(obj.idTienda)
      ..writeByte(3)
      ..write(obj.tipo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalidadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
