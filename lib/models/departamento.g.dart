// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'departamento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DepartamentoAdapter extends TypeAdapter<Departamento> {
  @override
  final int typeId = 15;

  @override
  Departamento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Departamento(
      idDepartamento: fields[0] as int,
      nombre: fields[1] as String,
      web: fields[2] as bool? ?? true,
      orden: fields[3] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Departamento obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.idDepartamento)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.web)
      ..writeByte(3)
      ..write(obj.orden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartamentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
