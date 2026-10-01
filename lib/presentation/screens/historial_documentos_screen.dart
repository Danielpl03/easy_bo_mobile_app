import 'package:easy_bo_mobile_app/presentation/screens/detalle_documento_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/documentos_provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/tiendas_provider.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/localidad.dart';
import 'package:easy_bo_mobile_app/models/cliente.dart';
import 'package:easy_bo_mobile_app/models/proveedor.dart';

class HistorialDocumentosScreen extends StatefulWidget {
  const HistorialDocumentosScreen({super.key});

  @override
  State<HistorialDocumentosScreen> createState() =>
      _HistorialDocumentosScreenState();
}

class _HistorialDocumentosScreenState extends State<HistorialDocumentosScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  Future<void> _cargarDatosIniciales() async {
    final provider = context.read<DocumentosProvider>();
    await provider.getDocumentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Documentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<DocumentosProvider>();
              provider.getDocumentos(forceUpdate: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              final provider = context.read<DocumentosProvider>();
              provider.limpiarFiltros();
            },
            tooltip: 'Limpiar filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(context),
          const SizedBox(height: 8),
          // Lista de documentos
          Expanded(child: _buildListaDocumentos()),
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    final documentosProvider = context.watch<DocumentosProvider>();
    final tiendasProvider = context.watch<TiendasProvider>();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Filtro de fecha
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fecha: ${_formatearFecha(documentosProvider.filtros.rangoFechas?.start)} - ${_formatearFecha(documentosProvider.filtros.rangoFechas?.end)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed:
                      () => _mostrarSelectorFechas(context, documentosProvider),
                  tooltip: 'Cambiar fecha',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filtros de tipo y localidad
            Column(
              children: [
                // Filtro de tipo
                _buildFiltroTipo(documentosProvider),
                const SizedBox(height: 12),
                // Filtro de localidad
                _buildFiltroLocalidad(documentosProvider, tiendasProvider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroTipo(DocumentosProvider provider) {
    final tiposUnicos = provider.getTiposDocumentoUnicos();

    return SizedBox(
      height: 60,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: provider.filtros.tipoDocumento,
        decoration: const InputDecoration(
          labelText: 'Tipo de Documento',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todos los tipos')),
          ...tiposUnicos.map((tipo) {
            return DropdownMenuItem(
              value: tipo,
              child: Text(tipo, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (value) {
          provider.setTipoDocumento(value);
        },
      ),
    );
  }

  Widget _buildFiltroLocalidad(
    DocumentosProvider documentosProvider,
    TiendasProvider tiendasProvider,
  ) {
    final localidades = tiendasProvider.localidades;

    return SizedBox(
      height: 60,
      child: DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue:
            documentosProvider.filtros.localidadesSeleccionadas.isNotEmpty
                ? documentosProvider.filtros.localidadesSeleccionadas.first
                : null,
        decoration: const InputDecoration(
          labelText: 'Localidad',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Todas las localidades'),
          ),
          ...localidades.map((localidad) {
            return DropdownMenuItem(
              value: localidad.idLocalidad,
              child: Text(localidad.localidad, overflow: TextOverflow.ellipsis),
            );
          }),
        ],
        onChanged: (value) {
          if (value == null) {
            documentosProvider.setLocalidadesSeleccionadas([]);
          } else {
            documentosProvider.setLocalidadesSeleccionadas([value]);
          }
        },
      ),
    );
  }

  Future<void> _mostrarSelectorFechas(
    BuildContext context,
    DocumentosProvider provider,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 1, now.month, now.day);

    final DateTimeRange? newRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: now,
      initialDateRange: provider.filtros.rangoFechas,
    );

    if (newRange != null) {
      await provider.setRangoFechas(newRange);
    }
  }

  Widget _buildListaDocumentos() {
    return Consumer<DocumentosProvider>(
      builder: (context, provider, child) {
        if (provider.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Mostrando datos locales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getDocumentos(forceUpdate: true),
                  child: const Text('Reintentar conexión'),
                ),
              ],
            ),
          );
        }

        List<Documento> documentosMostrar = provider.documentosFiltrados;

        if (documentosMostrar.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay documentos para mostrar'),
                SizedBox(height: 8),
                Text(
                  'Ajusta los filtros o verifica la conexión',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.getDocumentos(forceUpdate: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: documentosMostrar.length,
            itemBuilder: (context, index) {
              final documento = documentosMostrar[index];
              return _buildDocumentoItem(context, documento);
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentoItem(BuildContext context, Documento documento) {
    final tiendasProvider = context.read<TiendasProvider>();
    final documentosProvider = context.read<DocumentosProvider>();
    String localidadNombre = 'N/A';
    String localidadDestinoNombre = 'N/A';

    // Crear futures para obtener cliente y proveedor de forma asíncrona
    final clienteFuture = documentosProvider.getClientePorId(
      documento.idCliente,
    );
    final proveedorFuture = documentosProvider.getProveedorPorId(
      documento.idProveedor,
    );

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          _mostrarDetalleDocumento(context, documento);
        },
        onLongPress: () {
          _mostrarDetalleDocumento(context, documento);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${documento.tipo} - ${documento.idDocumento}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (documento.cancelado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'CANCELADO',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Información principal
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatearFechaHora(documento.fecha),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'De: $localidadNombre',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (documento.idLocalidadDestino != null)
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Text(
                    'A: $localidadDestinoNombre',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Información de Cliente (carga asíncrona)
              FutureBuilder<Cliente?>(
                future: clienteFuture,
                builder: (context, clienteSnapshot) {
                  if (clienteSnapshot.hasData && clienteSnapshot.data != null) {
                    final cliente = clienteSnapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cliente: ${cliente.nombre}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Información de Proveedor (carga asíncrona)
              FutureBuilder<Proveedor?>(
                future: proveedorFuture,
                builder: (context, proveedorSnapshot) {
                  if (proveedorSnapshot.hasData &&
                      proveedorSnapshot.data != null) {
                    final proveedor = proveedorSnapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Proveedor: ${proveedor.nombre}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.purple,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 8),
              // Información financiera
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (documento.importe != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Importe',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${documento.importe!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  if (documento.descuento != null && documento.descuento! > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descuento',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '\$${documento.descuento!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  if (documento.movimientos.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Productos',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          documento.movimientos.length.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                ],
              ),
              // Razón y comentario
              if (documento.razon.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Razón: ${documento.razon}',
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (documento.comentario != null &&
                  documento.comentario!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Comentario: ${documento.comentario}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleDocumento(BuildContext context, Documento documento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleDocumentoScreen(documento: documento),
      ),
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  String _formatearFechaHora(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
