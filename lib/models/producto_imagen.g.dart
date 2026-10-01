// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto_imagen.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductoImagenAdapter extends TypeAdapter<ProductoImagen> {
  @override
  final int typeId = 19;

  @override
  ProductoImagen read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductoImagen(
      idRelacion: fields[0] as int,
      idProducto: fields[1] as int,
      nombre: fields[2] as String,
      ext: fields[3] as String,
      principal: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductoImagen obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.idRelacion)
      ..writeByte(1)
      ..write(obj.idProducto)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.ext)
      ..writeByte(4)
      ..write(obj.principal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoImagenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
