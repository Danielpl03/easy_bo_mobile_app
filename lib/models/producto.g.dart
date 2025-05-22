// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductoAdapter extends TypeAdapter<Producto> {
  @override
  final int typeId = 4;

  @override
  Producto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Producto(
      idProducto: fields[0] as int,
      descripcion: fields[1] as String,
      codigo: fields[2] as String?,
      idDepartamento: fields[3] as int,
      ipv: fields[4] as bool,
      idCategoria: fields[5] as int?,
      activo: fields[6] as bool,
      barcode: fields[7] as String?,
      costo: fields[8] as double?,
      combo: fields[9] as bool,
      web: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Producto obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.idProducto)
      ..writeByte(1)
      ..write(obj.descripcion)
      ..writeByte(2)
      ..write(obj.codigo)
      ..writeByte(3)
      ..write(obj.idDepartamento)
      ..writeByte(4)
      ..write(obj.ipv)
      ..writeByte(5)
      ..write(obj.idCategoria)
      ..writeByte(6)
      ..write(obj.activo)
      ..writeByte(7)
      ..write(obj.barcode)
      ..writeByte(8)
      ..write(obj.costo)
      ..writeByte(9)
      ..write(obj.combo)
      ..writeByte(10)
      ..write(obj.web);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
