import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:flutter/material.dart';

Widget estadoCargaV(DocumentosProvider provider) {
  return AnimatedSwitcher(
    duration: Duration(milliseconds: 300),
    child:
        provider.cargando
            ? LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )
            : SizedBox(height: 2),
  );
}

Widget estadoCargaP(ProductosProvider provider) {
  return AnimatedSwitcher(
    duration: Duration(milliseconds: 300),
    child:
        provider.cargando
            ? LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )
            : SizedBox(height: 2),
  );
}
