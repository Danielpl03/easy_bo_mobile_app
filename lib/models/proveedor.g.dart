// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proveedor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProveedorAdapter extends TypeAdapter<Proveedor> {
  @override
  final int typeId = 16;

  @override
  Proveedor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Proveedor(
      idProveedor: fields[0] as int,
      nombre: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Proveedor obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.idProveedor)
      ..writeByte(1)
      ..write(obj.nombre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProveedorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
