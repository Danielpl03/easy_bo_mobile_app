// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pago.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PagoAdapter extends TypeAdapter<Pago> {
  @override
  final int typeId = 3;

  @override
  Pago read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pago(
      idPago: fields[0] as int,
      tipoPago: fields[1] as String,
      idMoneda: fields[2] as int,
      efectivo: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Pago obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.idPago)
      ..writeByte(1)
      ..write(obj.tipoPago)
      ..writeByte(2)
      ..write(obj.idMoneda)
      ..writeByte(3)
      ..write(obj.efectivo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
