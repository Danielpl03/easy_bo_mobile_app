// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rango_fechas.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RangoFechasAdapter extends TypeAdapter<RangoFechas> {
  @override
  final int typeId = 11;

  @override
  RangoFechas read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RangoFechas(
      inicio: fields[0] as DateTime,
      fin: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RangoFechas obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.inicio)
      ..writeByte(1)
      ..write(obj.fin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangoFechasAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
