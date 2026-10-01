import 'package:easy_bo_mobile_app/presentation/providers/productos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';

class DetalleDocumentoScreen extends StatelessWidget {
  final Documento documento;

  const DetalleDocumentoScreen({super.key, required this.documento});

  @override
  Widget build(BuildContext context) {
    final tiendasProvider = context.read<TiendasProvider>();

    // Obtener nombres de localidades
    String localidadNombre = 'N/A';
    String localidadDestinoNombre = 'N/A';

    if (documento.idLocalidad != null) {
      final localidad = tiendasProvider.localidades.firstWhere(
        (l) => l.idLocalidad == documento.idLocalidad,
        orElse:
            () => Localidad(
              idLocalidad: 0,
              localidad: 'Desconocida',
              idTienda: 0,
              tipo: '',
              ipv: false,
            ),
      );
      localidadNombre = localidad.localidad;
    }

    if (documento.idLocalidadDestino != null) {
      final localidadDestino = tiendasProvider.localidades.firstWhere(
        (l) => l.idLocalidad == documento.idLocalidadDestino,
        orElse:
            () => Localidad(
              idLocalidad: 0,
              localidad: 'Desconocida',
              idTienda: 0,
              tipo: '',
              ipv: false,
            ),
      );
      localidadDestinoNombre = localidadDestino.localidad;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Documento - ${documento.idDocumento}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del documento
            _buildInfoCard(documento, localidadNombre, localidadDestinoNombre),

            const SizedBox(height: 24),

            // Movimientos
            _buildMovimientosCard(context, documento),

            const SizedBox(height: 16),

            // Información adicional
            _buildInfoAdicionalCard(documento),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    Documento doc,
    String localidadNombre,
    String localidadDestinoNombre,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doc.tipo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (doc.cancelado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'CANCELADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Información básica
            _buildInfoRow('ID Documento:', doc.idDocumento),
            _buildInfoRow('Consecutivo:', doc.consec.toString()),
            _buildInfoRow('Fecha:', _formatearFechaCompleta(doc.fecha)),
            _buildInfoRow('Razón:', doc.razon),

            if (doc.comentario != null && doc.comentario!.isNotEmpty)
              _buildInfoRow('Comentario:', doc.comentario!),

            const SizedBox(height: 12),

            // Localidades
            _buildInfoRow('Localidad Origen:', localidadNombre),
            if (doc.idLocalidadDestino != null)
              _buildInfoRow('Localidad Destino:', localidadDestinoNombre),

            const SizedBox(height: 12),

            // Información financiera
            if (doc.importe != null)
              _buildInfoRowWithIcon(
                Icons.attach_money,
                'Importe:',
                '\$${doc.importe!.toStringAsFixed(2)}',
                Colors.green,
              ),

            if (doc.descuento != null && doc.descuento! > 0)
              _buildInfoRowWithIcon(
                Icons.discount,
                'Descuento:',
                '\$${doc.descuento!.toStringAsFixed(2)}',
                Colors.orange,
              ),

            if (doc.costo != null)
              _buildInfoRowWithIcon(
                Icons.money_off,
                'Costo:',
                '\$${doc.costo!.toStringAsFixed(2)}',
                Colors.red,
              ),

            if (doc.tipo == 'VENTA')
              _buildInfoRowWithIcon(
                Icons.swap_horiz,
                'Ganancia:',
                '\$${((doc.importe ?? 0) - (doc.costo ?? 0)).toStringAsFixed(2)}',
                Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientosCard(BuildContext context, Documento doc) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Movimientos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Total: ${doc.movimientos.length} productos',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            if (doc.movimientos.isEmpty)
              const Center(
                child: Text(
                  'No hay movimientos registrados',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...doc.movimientos.where((m) => !m.espejo).map((movimiento) {
                return _buildMovimientoItem(context, movimiento);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientoItem(BuildContext context, Movimiento movimiento) {
    var producto = movimiento.producto;
    producto ??= context.watch<ProductosProvider>().getProducto(
      movimiento.idProducto,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (producto != null)
            Text(
              producto.fullDescripction(uppercase: true),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          else
            Text(
              'Producto ID: ${movimiento.idProducto}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cantidad: ${movimiento.cantidad}'),
                    if (movimiento.precioProducto != null)
                      Text(
                        'Precio: \$${movimiento.precioProducto!.toStringAsFixed(2)}',
                      ),
                  ],
                ),
              ),

              if (movimiento.importe != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '\$${movimiento.importe!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          if (movimiento.descuento != null && movimiento.descuento! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Descuento: \$${movimiento.descuento!.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.orange),
              ),
            ),

          if (movimiento.saldoProducto != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Saldo restante: ${movimiento.saldoProducto}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),

          if (movimiento.espejo)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple),
              ),
              child: const Text(
                'MOVIMIENTO ESPEJO',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoAdicionalCard(Documento doc) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Adicional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _buildInfoRow('ID Sistema:', doc.idSistema.toString()),
            _buildInfoRow('ID Usuario:', doc.idUsuario.toString()),
            _buildInfoRow('Cancelado:', doc.cancelado ? 'Sí' : 'No'),

            const SizedBox(height: 8),

            Text(
              'Documentos relacionados:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 4),

            SelectableText(
              doc.idDocumento,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithIcon(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFechaCompleta(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year;
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
