// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UsuarioAdapter extends TypeAdapter<Usuario> {
  @override
  final int typeId = 13;

  @override
  Usuario read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Usuario(
      idUsuario: fields[0] as int,
      nombre: fields[1] as String,
      password: fields[2] as String,
      rol: fields[3] as String,
      email: fields[4] as String?,
      ultimoAcceso: fields[5] as DateTime?,
      activo: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Usuario obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.idUsuario)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.rol)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.ultimoAcceso)
      ..writeByte(6)
      ..write(obj.activo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
