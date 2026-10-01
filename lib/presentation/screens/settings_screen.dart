import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_bo_mobile_app/config/supabase_config.dart';
import 'package:easy_bo_mobile_app/services/edge_function_sql_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:easy_bo_mobile_app/presentation/providers/theme_provider.dart';
import 'package:easy_bo_mobile_app/config/app_config.dart';
import '../providers/productos_provider.dart';
import '../../services/image_service.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_bo_mobile_app/presentation/providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showPrecacheDialog(BuildContext context) async {
    final productosProvider = context.read<ProductosProvider>();
    final imageService = ImageService();
    final totalImages = productosProvider.productos.length;
    int loadedImages = 0;
    int failedImages = 0;
    bool isPrecaching = true;
    bool cancelRequested = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              Future<void> precache() async {
                for (final producto in productosProvider.productos) {
                  if (!isPrecaching || cancelRequested) break;
                  try {
                    final ok = await imageService.precacheProductImage(
                      context,
                      producto,
                    );
                    if (ok) {
                      loadedImages++;
                    } else {
                      failedImages++;
                    }
                  } catch (e) {
                    failedImages++;
                  }
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 50));
                }
                isPrecaching = false;
                setState(() {});
              }

              // Lanzar la precarga solo una vez
              if (isPrecaching && loadedImages == 0 && failedImages == 0) {
                Future.microtask(precache);
              }

              return AlertDialog(
                title: const Text('Precargando imágenes'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value:
                          totalImages > 0
                              ? (loadedImages + failedImages) / totalImages
                              : 0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Progreso: ${loadedImages + failedImages}/$totalImages',
                    ),
                    const SizedBox(height: 8),
                    Text('Éxitos: $loadedImages'),
                    const SizedBox(height: 8),
                    Text('Fallos: $failedImages'),
                    if (!isPrecaching)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          cancelRequested
                              ? 'Precarga cancelada. $loadedImages éxitos, $failedImages fallos.'
                              : 'Precarga finalizada. $loadedImages éxitos, $failedImages fallos.',
                          style: TextStyle(
                            color:
                                failedImages == 0
                                    ? Colors.green
                                    : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  if (isPrecaching)
                    TextButton(
                      onPressed: () {
                        cancelRequested = true;
                        isPrecaching = false;
                        setState(() {});
                      },
                      child: const Text('Cancelar'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isPrecaching ? 'Cerrar' : 'Aceptar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    try {
      final version = await AppConfig.appVersion;
      final buildNumber = await AppConfig.buildNumber;

      if (!context.mounted) return;

      showAboutDialog(
        context: context,
        applicationName: AppConfig.appName,
        applicationVersion: version,
        applicationIcon: const Icon(Icons.apps_rounded, size: 50),
        children: [
          Text(AppConfig.appDescription),
          const SizedBox(height: 8),
          Text('Desarrollado por ${AppConfig.developer}'),
          const SizedBox(height: 8),
          Text('Versión $version+$buildNumber'),
        ],
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al obtener la información de la aplicación'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showMultipleImageUploadDialog(BuildContext context) async {
    final imageService = ImageService();

    // Solicitar permisos para Android - Compatible con Android 13+
    if (Platform.isAndroid) {
      bool permissionGranted = false;

      // Intentar primero con permisos de fotos para Android 13+
      try {
        final photosPermission = await Permission.photos.request();
        permissionGranted = photosPermission.isGranted;
      } catch (e) {
        // Si Permission.photos no está disponible, usar método tradicional
      }

      // Si no se concedieron los permisos de fotos, intentar con storage
      if (!permissionGranted) {
        try {
          final storagePermission = await Permission.storage.request();
          permissionGranted = storagePermission.isGranted;
        } catch (e) {
          // Fallback final
        }
      }

      // Último intento - permisos de medios para Android 13+
      if (!permissionGranted) {
        try {
          final mediaPermission = await Permission.mediaLibrary.request();
          permissionGranted = mediaPermission.isGranted;
        } catch (e) {
          // No disponible en todas las versiones
        }
      }

      if (!permissionGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se requieren permisos para acceder a las imágenes',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Usar FilePicker para seleccionar múltiples imágenes
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        allowMultiple: true,
        withData: false,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar archivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (result == null || result.files.isEmpty) {
      return;
    }

    // Convertir PlatformFile a XFile
    final selectedImages = <XFile>[];
    for (final file in result.files) {
      if (file.path != null) {
        selectedImages.add(XFile(file.path!));
      }
    }

    if (selectedImages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se seleccionaron imágenes válidas'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Mostrar confirmación
    final proceed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar subida'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Subir ${selectedImages.length} imagen(es)?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primeras 3 imágenes:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...selectedImages
                          .take(3)
                          .map(
                            (image) => Text(
                              '• ${image.name}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      if (selectedImages.length > 3)
                        Text(
                          '... y ${selectedImages.length - 3} más',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Subir'),
              ),
            ],
          ),
    );

    if (proceed != true) return;

    // Variables para el diálogo de progreso
    MultipleUploadResult? uploadResult;
    bool isUploading = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              Future<void> uploadImages() async {
                try {
                  final result = await imageService.uploadMultipleImages(
                    selectedImages,
                    context,
                  );

                  setState(() {
                    uploadResult = result;
                    isUploading = false;
                  });
                } catch (e) {
                  setState(() {
                    isUploading = false;
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error fatal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }

              // Iniciar carga solo una vez
              if (isUploading && uploadResult == null) {
                Future.microtask(uploadImages);
              }

              return AlertDialog(
                title:
                    isUploading
                        ? const Text('Subiendo imágenes...')
                        : const Text('Resultado de subida'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUploading) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Procesando ${selectedImages.length} imágenes...'),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor espera',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ] else if (uploadResult != null) ...[
                        // Resultado final
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                uploadResult!.failedUploads == 0
                                    ? Colors.green.shade50
                                    : uploadResult!.successfulUploads > 0
                                    ? Colors.orange.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                uploadResult!.failedUploads == 0
                                    ? Icons.check_circle
                                    : uploadResult!.successfulUploads > 0
                                    ? Icons.warning
                                    : Icons.error,
                                color:
                                    uploadResult!.failedUploads == 0
                                        ? Colors.green
                                        : uploadResult!.successfulUploads > 0
                                        ? Colors.orange
                                        : Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                uploadResult!.failedUploads == 0
                                    ? '¡Éxito total!'
                                    : uploadResult!.successfulUploads > 0
                                    ? 'Subida parcial'
                                    : 'Subida fallida',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${uploadResult!.successfulUploads} de ${uploadResult!.totalImages} imágenes subidas',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duración: ${uploadResult!.durationFormatted}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Detalles si hay fallos
                        if (uploadResult!.failedUploads > 0) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _showUploadErrorDetails(context, uploadResult!);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text('Ver detalles de errores'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (isUploading)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Ocultar'),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                ],
              );
            },
          ),
    );
  }

  // Función para mostrar detalles de error
  void _showUploadErrorDetails(
    BuildContext context,
    MultipleUploadResult result,
  ) {
    final failedResults = result.results.where((r) => !r.success).toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Errores de subida'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total errores: ${failedResults.length}'),
                  const SizedBox(height: 16),
                  ...failedResults.map(
                    (result) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.originalName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Error: ${result.error ?? "Desconocido"}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'Tamaño: ${result.formattedSize}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Agrega esta función para mostrar el diálogo de carga a Edge Function
  Future<void> _showEdgeFunctionSqlDialog(BuildContext context) async {
    // Seleccionar archivo SQL
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sql', 'txt'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo')),
        );
      }
      return;
    }

    final file = result.files.first;

    // Mostrar confirmación antes de enviar
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar envío'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Enviar este archivo?\n'),
                  Text('📄 Archivo: ${file.name}'),
                  Text(
                    '📏 Tamaño: ${file.size} bytes (${_formatBytes(file.size)})',
                  ),
                  Text('📋 Tipo: ${file.extension?.toUpperCase() ?? 'SQL'}'),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ Advertencia:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Esta acción es irreversible.'),
                  if (file.bytes != null && file.bytes!.length < 5000)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        utf8.decode(file.bytes!),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final apiKey = SupabaseConfig.serviceRoleKey;
    if (apiKey.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró la API key')),
        );
      }
      return;
    }

    final edgeFunctionUrl =
        '${SupabaseConfig.supabaseUrl}/functions/v1/sql-file-executor';
    if (edgeFunctionUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró la URL de la Edge Function'),
          ),
        );
      }
      return;
    }

    // Crear servicio para Edge Function
    final service = EdgeFunctionSqlService(
      edgeFunctionUrl: edgeFunctionUrl,
      apiKey: apiKey,
    );

    // Mostrar diálogo de progreso
    EdgeFunctionResult? resultadoFinal;
    bool isUploading = true;
    bool cancelRequested = false;
    // Nuevo: Variable para almacenar el progreso actual
    EdgeFunctionProgress? currentProgress;
    bool uploadStarted = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              Future<void> uploadFile() async {
                try {
                  final result = await service.uploadSqlFile(
                    file: file,
                    onProgress: (progress) {
                      if (!cancelRequested && context.mounted) {
                        setState(() {
                          currentProgress = progress;
                        });
                      }
                    },
                  );

                  if (!cancelRequested && context.mounted) {
                    setState(() {
                      resultadoFinal = result;
                      isUploading = false;
                    });
                  }
                } catch (e) {
                  if (!cancelRequested && context.mounted) {
                    setState(() {
                      isUploading = false;
                      resultadoFinal = EdgeFunctionResult(
                        success: false,
                        statusCode: 0,
                        message: 'Error: $e',
                        duration: const Duration(seconds: 0),
                        fileInfo: FileInfo(
                          name: file.name,
                          size: file.size,
                          uploadTime: DateTime.now(),
                        ),
                        details: null,
                        sqlStatistics: null,
                        partResults: [],
                      );
                    });
                  }
                }
              }

              // Iniciar carga solo una vez usando WidgetsBinding
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (isUploading && resultadoFinal == null && !uploadStarted) {
                  uploadFile();
                  uploadStarted = true;
                }
              });

              return AlertDialog(
                title: Text(
                  isUploading
                      ? 'Enviando datos...'
                      : (resultadoFinal?.success == true
                          ? '✅ Completado'
                          : '❌ Error'),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUploading) ...[
                        // Mostrar progreso general y de la parte actual
                        if (currentProgress != null) ...[
                          LinearProgressIndicator(
                            value: currentProgress!.progress,
                          ),
                          const SizedBox(height: 16),
                          Text('${currentProgress!.progressText}'),
                          const SizedBox(height: 8),
                          Text(
                            'Archivo: ${currentProgress!.fileName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ] else ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 16),
                          const Text('Preparando archivo...'),
                        ],
                        const SizedBox(height: 16),
                        Text('Archivo original: ${file.name}'),
                        Text('Tamaño: ${_formatBytes(file.size)}'),
                        const SizedBox(height: 8),
                        const Text(
                          'El archivo se dividirá en partes y se enviará una por una',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        const CircularProgressIndicator(),
                      ] else if (resultadoFinal != null) ...[
                        // Resultado final
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                resultadoFinal!.success
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    resultadoFinal!.success
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color:
                                        resultadoFinal!.success
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      resultadoFinal!.success
                                          ? 'Archivo procesado exitosamente'
                                          : 'Error al procesar el archivo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            resultadoFinal!.success
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Archivo: ${resultadoFinal!.fileInfo.name}'),
                              Text(
                                'Tamaño: ${resultadoFinal!.fileInfo.formattedSize}',
                              ),
                              // Mostrar información de partes
                              if (resultadoFinal!.partResults != null &&
                                  resultadoFinal!.partResults!.isNotEmpty)
                                Text(
                                  'Partes procesadas: ${resultadoFinal!.partResults!.length}',
                                ),
                              Text(
                                'Duración: ${resultadoFinal!.durationFormatted}',
                              ),
                              const SizedBox(height: 8),
                              // Mostrar un resumen breve del mensaje
                              Text(
                                resultadoFinal!.message.split('\n').first,
                                style: const TextStyle(fontSize: 14),
                              ),
                              // Si hay más de una parte, mostrar un botón para ver detalles
                              if (resultadoFinal!.partResults != null &&
                                  resultadoFinal!.partResults!.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showPartsDetails(
                                        context,
                                        resultadoFinal!,
                                      );
                                    },
                                    child: const Text(
                                      'Ver detalles por partes',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Botón para ver detalles si hay error
                        if (!resultadoFinal!.success) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _showEdgeFunctionErrorDetails(
                                context,
                                resultadoFinal!,
                              );
                            },
                            child: const Text('Ver detalles del error'),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (isUploading)
                    TextButton(
                      onPressed: () {
                        cancelRequested = true;
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isUploading ? 'Ocultar' : 'Cerrar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Función auxiliar para mostrar detalles de las partes
  void _showPartsDetails(BuildContext context, EdgeFunctionResult result) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles por partes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total partes: ${result.partResults!.length}'),
                  const SizedBox(height: 16),
                  ...result.partResults!.map((part) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            part.success
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              part.success
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parte ${part.partNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estado: ${part.success ? '✅ Éxito' : '❌ Fallido'}',
                          ),
                          Text('Consultas: ${part.statementCount}'),
                          Text(
                            'Sentencias: ${part.successfulStatements}/${part.totalStatements} exitosas',
                          ),
                          Text('Filas afectadas: ${part.totalRowsAffected}'),
                          Text('Duración: ${part.durationFormatted}'),
                          if (part.error != null)
                            Text(
                              'Error: ${part.error}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Función auxiliar para formatear bytes
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Función para mostrar detalles de error
  void _showEdgeFunctionErrorDetails(
    BuildContext context,
    EdgeFunctionResult result,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Detalles del error'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Código de estado: ${result.statusCode}'),
                  Text('Duración: ${result.durationFormatted}'),
                  // Mostrar información de partes si hay
                  if (result.partResults != null &&
                      result.partResults!.isNotEmpty)
                    Text('Partes procesadas: ${result.partResults!.length}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Mensaje de error:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      result.message,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  if (result.output != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Salida completa:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        result.output!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: theme.primaryColor,
      ),
      body: ListView(
        children: [
          // Sección de cuenta
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              print('[SettingsScreen] Renderizando sección de cuenta...');
              if (authProvider.currentUser != null) {
                print(
                  '[SettingsScreen] Usuario: ${authProvider.currentUser!.nombreCompleto}',
                );
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Icon(Icons.person, color: theme.primaryColor),
                      ),
                      title: Text(authProvider.currentUser!.nombreCompleto),
                      subtitle: Text(
                        authProvider.currentUser!.email ?? 'Sin email',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/perfil'),
                    ),
                    const Divider(),
                  ],
                );
              }
              print('[SettingsScreen] No hay usuario autenticado');
              return const SizedBox.shrink();
            },
          ),

          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Modo Oscuro'),
            trailing: Switch(
              value: context.watch<ThemeProvider>().isDarkMode,
              onChanged: (value) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Precargar imágenes'),
            onTap: () {
              _showPrecacheDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Subir múltiples imágenes'),
            subtitle: const Text(
              'Selecciona y sube varias imágenes al almacenamiento',
            ),
            onTap: () => _showMultipleImageUploadDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Borrar caché de imágenes'),
            subtitle: const Text('Liberar espacio de almacenamiento'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Borrar caché'),
                      content: const Text(
                        '¿Estás seguro de que quieres borrar toda la caché de imágenes? '
                        'Esto liberará espacio de almacenamiento pero las imágenes se volverán a descargar cuando las necesites.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Borrar'),
                        ),
                      ],
                    ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  final imageService = ImageService();
                  await imageService.clearAllImageCache();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Caché de imágenes borrada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al borrar la caché: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
          const Divider(),

          // ListTile(
          //   leading: const Icon(Icons.upload_file),
          //   title: const Text('Importar y sincronizar JSON'),
          //   onTap: () async {
          //     print(
          //       '[SettingsScreen] Botón "Importar y sincronizar JSON" presionado.',
          //     );
          //     final jsonService = JsonImportService();
          //     final supabaseService = SupabaseService(Supabase.instance.client);
          //     try {
          //       print(
          //         '[SettingsScreen] Intentando seleccionar archivo JSON...',
          //       );
          //       final jsonString = await jsonService.pickJsonFile();
          //       if (jsonString == null) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           const SnackBar(
          //             content: Text('No se seleccionó ningún archivo'),
          //           ),
          //         );
          //         print(
          //           '[SettingsScreen] No se seleccionó ningún archivo JSON. Operación cancelada.',
          //         );
          //         return;
          //       }
          //       print(
          //         '[SettingsScreen] Archivo JSON seleccionado. Analizando documentos...',
          //       );
          //       final documentosConFlujos = await jsonService
          //           .parseDocumentosConFlujosFromJson(jsonString);

          //       print(
          //         '[SettingsScreen] Iniciando sincronización de documentos con Supabase...',
          //       );

          //       // Mostrar diálogo de progreso
          //       await _showSyncProgressDialog(
          //         context,
          //         supabaseService,
          //         documentosConFlujos,
          //       );
          //     } catch (e) {
          //       print(
          //         '[SettingsScreen] Error crítico al sincronizar el JSON de ventas: $e',
          //       );
          //       if (context.mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: Text(
          //               'Error al sincronizar el JSON de ventas: $e',
          //             ),
          //             backgroundColor: Colors.red,
          //           ),
          //         );
          //       }
          //     }
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Sincronizar datos'),
            subtitle: const Text('Sincronizar datos locales con la nube'),
            onTap: () => _showEdgeFunctionSqlDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }
}
