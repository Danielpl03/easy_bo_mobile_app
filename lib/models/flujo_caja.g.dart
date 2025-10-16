// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flujo_caja.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlujoCajaAdapter extends TypeAdapter<FlujoCaja> {
  @override
  final int typeId = 12;

  @override
  FlujoCaja read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FlujoCaja(
      idFlujo: fields[0] as int,
      tipo: fields[1] as String,
      motivo: fields[2] as String,
      importe: fields[3] as num,
      fecha: fields[4] as DateTime,
      formaPago: fields[5] as int,
      idDocumento: fields[6] as String?,
      monto: fields[7] as num?,
      idLocalidad: fields[8] as int,
      idSistema: fields[9] as int,
      idUsuario: fields[11] as int?,
      localidad: fields[10] as Localidad?,
    );
  }

  @override
  void write(BinaryWriter writer, FlujoCaja obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.idFlujo)
      ..writeByte(1)
      ..write(obj.tipo)
      ..writeByte(2)
      ..write(obj.motivo)
      ..writeByte(3)
      ..write(obj.importe)
      ..writeByte(4)
      ..write(obj.fecha)
      ..writeByte(5)
      ..write(obj.formaPago)
      ..writeByte(6)
      ..write(obj.idDocumento)
      ..writeByte(7)
      ..write(obj.monto)
      ..writeByte(8)
      ..write(obj.idLocalidad)
      ..writeByte(9)
      ..write(obj.idSistema)
      ..writeByte(10)
      ..write(obj.localidad)
      ..writeByte(11)
      ..write(obj.idUsuario);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlujoCajaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
