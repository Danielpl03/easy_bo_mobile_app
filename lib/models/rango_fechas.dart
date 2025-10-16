import 'package:hive/hive.dart';

part 'rango_fechas.g.dart';

@HiveType(typeId:11)
class RangoFechas {
  @HiveField(0)
  final DateTime inicio;

  @HiveField(1)
  final DateTime fin;

  RangoFechas({
    required this.inicio,
    required this.fin,
  });

  bool contiene(DateTime fecha) {
    return fecha.isAfter(inicio) && fecha.isBefore(fin);
  }

  bool seSolapa(RangoFechas otro) {
    return (inicio.isBefore(otro.fin) && fin.isAfter(otro.inicio));
  }

  RangoFechas unir(RangoFechas otro) {
    return RangoFechas(
      inicio: inicio.isBefore(otro.inicio) ? inicio : otro.inicio,
      fin: fin.isAfter(otro.fin) ? fin : otro.fin,
    );
  }
} 