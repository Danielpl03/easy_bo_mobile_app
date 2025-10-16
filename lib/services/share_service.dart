import 'dart:io';
import 'package:easy_bo_mobile_app/models/moneda.dart';
import 'package:easy_bo_mobile_app/models/precio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/producto.dart';
import 'image_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final ImageService _imageService = ImageService();

  // Mostrar diálogo de selección de información
  Future<Map<String, bool>> _showShareOptionsDialog(
    BuildContext context,
  ) async {
    final options = {
      'Imagen': true,
      'Descripción': true,
      'Código': false,
      'Precio': true,
      'Stock Total': false,
      'Stocks por Localidad': false,
    };

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Seleccionar información para compartir'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      options.entries.map((entry) {
                        return CheckboxListTile(
                          title: Text(entry.key),
                          value: entry.value,
                          onChanged: (bool? value) {
                            setState(() {
                              options[entry.key] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, options),
                  child: const Text('Compartir'),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? options;
  }

  // Compartir producto
  Future<void> shareProduct(
    Producto producto,
    BuildContext context,
    Moneda moneda,
  ) async {
    try {
      // Mostrar diálogo de opciones
      final shareOptions = await _showShareOptionsDialog(context);
      if (!context.mounted) return;

      // Verificar si se seleccionó al menos una opción
      if (!shareOptions.values.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione al menos una opción para compartir'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar indicador de carga
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparando para compartir...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      List<XFile> files = [];
      String message = '';

      // Agregar imagen si está seleccionada
      if (shareOptions['Imagen'] == true) {
        final imageUrl = _imageService.getProductImageUrl(producto);
        
        // Intenta obtener la imagen de la caché
        File? cachedImageFile = await DefaultCacheManager().getSingleFile(imageUrl);

        if (await cachedImageFile.exists()) {
          // Usar imagen de la caché si existe
          files.add(XFile(cachedImageFile.path));
        } else {
          // Descargar imagen si no está en caché
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final file = File(
              '${tempDir.path}/producto_${producto.idProducto}.jpg',
            );
            await file.writeAsBytes(response.bodyBytes);
            files.add(XFile(file.path));
          }
        }
      }

      // Construir mensaje con la información seleccionada
      if (shareOptions['Descripción'] == true) {
        message += '*${producto.descripcion}*\n';
      }
      if (shareOptions['Código'] == true) {
        message += 'Código: ${producto.codigo ?? 'N/A'}\n';
      }
      if (shareOptions['Precio'] == true) {
        final precio =
            producto.precios.isNotEmpty
                ? producto.precios.firstWhere(
                  (p) => p.idMoneda == moneda.idMoneda,
                  orElse:
                      () => Precio(
                        idPrecio: -1,
                        idProducto: -1,
                        idMoneda: -1,
                        precio: 0,
                      ),
                )
                : Precio(idPrecio: -1, idProducto: -1, idMoneda: -1, precio: 0);
        message +=
            'Precio: \$${NumberFormat('#,##0.00', 'es_MX').format(precio.precio)}\n';
      }
      if (shareOptions['Stock Total'] == true) {
        final stockTotal = producto.stocks.fold<int>(
          0,
          (sum, stock) => sum + stock.stock,
        );
        message += 'Stock Total: $stockTotal\n';
      }
      if (shareOptions['Stocks por Localidad'] == true) {
        message += '\nStocks por Localidad:\n';
        for (var stock in producto.stocks) {
          message += '- Localidad ${stock.idLocalidad}: ${stock.stock}\n';
        }
      }

      // Compartir
      await Share.shareXFiles(
        files,
        text: message.trim(),
        subject: producto.descripcion,
      );

      // Limpiar archivos temporales
      for (var file in files) {
        await File(file.path).delete();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
