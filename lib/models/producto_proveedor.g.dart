// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'producto_proveedor.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductoProveedorAdapter extends TypeAdapter<ProductoProveedor> {
  @override
  final int typeId = 18;

  @override
  ProductoProveedor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductoProveedor(
      idRelacion: fields[0] as int,
      idProducto: fields[1] as int,
      idProveedor: fields[2] as int,
      ultimoCosto: fields[3] as num,
    );
  }

  @override
  void write(BinaryWriter writer, ProductoProveedor obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.idRelacion)
      ..writeByte(1)
      ..write(obj.idProducto)
      ..writeByte(2)
      ..write(obj.idProveedor)
      ..writeByte(3)
      ..write(obj.ultimoCosto);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductoProveedorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
