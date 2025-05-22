import 'dart:ui' show Color;

import 'package:flutter/material.dart' show Colors, Icons;
import 'package:flutter/widgets.dart' show IconData;

Color getColorEstado(String estado) {
  switch (estado.toUpperCase()) {
    case 'PENDIENTE':
      return Colors.orange;
    case 'ENVIADO':
      return Colors.blue;
    case 'ENTREGADO':
      return Colors.green;
    case 'CANCELADO':
      return Colors.red;
    case 'MODIFICADO':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

IconData getIconEstado(String estado) {
  switch (estado.toUpperCase()) {
    case 'PENDIENTE':
      return Icons.hourglass_empty;
    case 'ENVIADO':
      return Icons.send;
    case 'ENTREGADO':
      return Icons.check_circle;
    case 'CANCELADO':
      return Icons.cancel;
    case 'MODIFICADO':
      return Icons.edit;
    default:
      return Icons.help;
  }
}