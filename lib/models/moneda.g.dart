// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moneda.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonedaAdapter extends TypeAdapter<Moneda> {
  @override
  final int typeId = 2;

  @override
  Moneda read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Moneda(
      idMoneda: fields[0] as int,
      nombre: fields[1] as String,
      siglas: fields[2] as String,
      porDefecto: fields[3] as bool,
      tazaCambio: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Moneda obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.idMoneda)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.siglas)
      ..writeByte(3)
      ..write(obj.porDefecto)
      ..writeByte(4)
      ..write(obj.tazaCambio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonedaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
