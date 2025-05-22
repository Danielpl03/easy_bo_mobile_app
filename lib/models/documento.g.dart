// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documento.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentoAdapter extends TypeAdapter<Documento> {
  @override
  final int typeId = 7;

  @override
  Documento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Documento(
      consec: fields[0] as int,
      fecha: fields[1] as DateTime,
      tipo: fields[2] as String,
      razon: fields[3] as String,
      comentario: fields[4] as String?,
      idLocalidad: fields[5] as int?,
      importe: fields[6] as num,
      descuento: fields[7] as num?,
      idSistema: fields[8] as int,
      idUsuario: fields[9] as int,
      cambio: fields[10] as num,
      idLocalidadDestino: fields[11] as int?,
      idDocumento: fields[12] as String,
      cancelado: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Documento obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.consec)
      ..writeByte(1)
      ..write(obj.fecha)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.razon)
      ..writeByte(4)
      ..write(obj.comentario)
      ..writeByte(5)
      ..write(obj.idLocalidad)
      ..writeByte(6)
      ..write(obj.importe)
      ..writeByte(7)
      ..write(obj.descuento)
      ..writeByte(8)
      ..write(obj.idSistema)
      ..writeByte(9)
      ..write(obj.idUsuario)
      ..writeByte(10)
      ..write(obj.cambio)
      ..writeByte(11)
      ..write(obj.idLocalidadDestino)
      ..writeByte(12)
      ..write(obj.idDocumento)
      ..writeByte(13)
      ..write(obj.cancelado);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
