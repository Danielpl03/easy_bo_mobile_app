import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/supabase_config.dart';
import '../models/producto.dart';
import '../models/producto_imagen.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseConfig.client,
  );
  final LocalStorageService _localStorageService = LocalStorageService();

  String _extractExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last.toLowerCase();
  }

  String _storageKey(ProductoImagen imagen) => imagen.storageKey;

  String getProductImageUrl(Producto producto, {ProductoImagen? imagen}) {
    final img = imagen ?? producto.imagenPrincipal;
    if (img == null) return '';
    return img.url(SupabaseConfig.imagesSupabase);
  }

  Widget getProductImage(
    Producto producto, {
    ProductoImagen? imagen,
    double? width,
    double? height,
  }) {
    final imageUrl = getProductImageUrl(producto, imagen: imagen);
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.contain,
      placeholder:
          (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
    );
  }

  Widget getEmpresaImage(Color color, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: '${SupabaseConfig.imagesSupabase}iconoEmpresa.jpg',
      imageBuilder:
          (context, imageProvider) =>
              CircleAvatar(backgroundImage: imageProvider, radius: 60),
      width: 90,
      height: 90,
      fit: BoxFit.contain,
      placeholder:
          (context, url) => CircleAvatar(
            radius: 60,
            backgroundColor: color,
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: color,
            child: const Icon(
              Icons.apps_rounded,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
    );
  }

  // Generar firma para la autenticación de ImageKit
  String generateSignature(String token, String expire) {
    final data = '$token$expire';
    final bytes = utf8.encode(data);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Mostrar diálogo para elegir fuente de imagen
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> precacheProductImage(
    BuildContext context,
    Producto producto,
  ) async {
    final imageUrl = getProductImageUrl(producto);
    try {
      await precacheImage(
        CachedNetworkImageProvider(imageUrl),
        context,
      ).onError((e, _) => false);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Limpiar la caché de una imagen específica
  Future<void> clearImageCache(String url) async {
    try {
      await CachedNetworkImage.evictFromCache(url);
    } catch (e) {
      // Error silencioso al limpiar caché
    }
  }

  // Limpiar toda la caché de imágenes
  Future<void> clearAllImageCache() async {
    try {
      // Limpiar toda la caché de CachedNetworkImage
      await CachedNetworkImage.evictFromCache('');
      // También limpiar la caché de Flutter
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      // Error silencioso al limpiar caché
    }
  }

  // Subir una imagen para un producto a Supabase Storage
  String _formatFileName(String text) {
    return text
        .replaceAll(RegExp(r'[<>:"/\\|?*¨ñÑ&ÁÉÍÓÚÜ]'), '_')
        .replaceAll(' ', '_')
        .toUpperCase();
  }

  Future<String?> uploadProductImage(
    Producto producto,
    BuildContext context, {
    bool comoPrincipal = false,
  }) async {
    try {
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionó ninguna opción'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      // Solicitar permisos según la plataforma y fuente
      if (Platform.isAndroid) {
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            throw Exception('Se requieren permisos para acceder a la cámara');
          }
        } else {
          final storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            throw Exception(
              'Se requieren permisos para acceder al almacenamiento',
            );
          }
        }
      } else if (Platform.isIOS) {
        if (source == ImageSource.camera) {
          final cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            throw Exception('Se requieren permisos para acceder a la cámara');
          }
        } else {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            throw Exception('Se requieren permisos para acceder a la galería');
          }
        }
      }

      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se seleccionó ninguna imagen'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      // Mostrar mensaje de carga
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subiendo imagen...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }

      final congigKey = await SupabaseConfig.getConfigKey();
      final storage = SupabaseConfig.storages[congigKey];

      if (storage == null) {
        throw Exception('Error al obtener el Storage');
      }

      final file = File(image.path);
      final ext = _extractExtension(image.path);
      final esPrimeraImagen = producto.imagenes.isEmpty;
      final marcarPrincipal = esPrimeraImagen || comoPrincipal;

      final nombre = producto.fullDescripction();

      final nuevaImagen = await _supabaseService.insertProductoImagen(
        idProducto: producto.idProducto,
        nombre: nombre,
        ext: ext,
        principal: marcarPrincipal,
      );

      final nombreArchivo = _storageKey(nuevaImagen);
      await SupabaseConfig.authenticatedStorageClient
          .from(storage)
          .upload(nombreArchivo, file);

      if (marcarPrincipal) {
        for (var i = 0; i < producto.imagenes.length; i++) {
          producto.imagenes[i] =
              producto.imagenes[i].copyWith(principal: false);
        }
      }
      producto.imagenes.add(nuevaImagen);
      await _localStorageService.saveProductosImagenes([
        nuevaImagen,
        ...producto.imagenes.where(
          (i) => i.idRelacion != nuevaImagen.idRelacion,
        ),
      ], removeOthers: false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagen subida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return getProductImageUrl(producto);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }

  Future<void> deleteProductImage(
    Producto producto,
    ProductoImagen imagen,
  ) async {
    try {
      final congigKey = await SupabaseConfig.getConfigKey();
      final storage = SupabaseConfig.storages[congigKey];

      if (storage == null) {
        throw Exception('Error al obtener el Storage');
      }

      await clearImageCache(imagen.url(SupabaseConfig.imagesSupabase));
      await SupabaseConfig.authenticatedStorageClient.from(storage).remove([
        imagen.nombreArchivo,
      ]);
      await _supabaseService.deleteProductoImagen(imagen.idRelacion);
      await _localStorageService.deleteProductoImagenLocal(imagen.idRelacion);

      final eraPrincipal = imagen.principal;
      producto.imagenes.removeWhere((i) => i.idRelacion == imagen.idRelacion);

      if (eraPrincipal && producto.imagenes.isNotEmpty) {
        await setImagenPrincipal(producto, producto.imagenes.first);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setImagenPrincipal(
    Producto producto,
    ProductoImagen imagen,
  ) async {
    await _supabaseService.setImagenPrincipal(
      producto.idProducto,
      imagen.idRelacion,
    );

    final actualizadas = <ProductoImagen>[];
    for (final img in producto.imagenes) {
      final actualizada = img.copyWith(
        principal: img.idRelacion == imagen.idRelacion,
      );
      actualizadas.add(actualizada);
    }
    producto.imagenes
      ..clear()
      ..addAll(actualizadas);

    await _localStorageService.saveProductosImagenes(
      actualizadas,
      removeOthers: false,
    );
  }

  // Descargar la imagen de un producto
  Future<void> downloadProductImage(
    Producto producto,
    BuildContext context, {
    ProductoImagen? imagen,
  }) async {
    try {
      final img = imagen ?? producto.imagenPrincipal;
      if (img == null) {
        throw Exception('El producto no tiene imagen registrada');
      }

      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception(
          'Se requieren permisos de almacenamiento para descargar la imagen.',
        );
      }

      final imageUrl = getProductImageUrl(producto, imagen: img);
      final fileName = img.nombreArchivo;

      // Obtener el directorio de descargas
      final directory = Directory('/storage/emulated/0/Download/EasyBo');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filePath = '${directory.path}/$fileName';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Descargando imagen...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _dio.download(imageUrl, filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagen descargada en $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }

  // Subir múltiples imágenes al bucket de Supabase
  // image_service.dart - Reemplazar el método uploadMultipleImages con este

  // Subir múltiples imágenes al bucket de Supabase
  Future<MultipleUploadResult> uploadMultipleImages(
    List<XFile> images,
    BuildContext context,
  ) async {
    final startTime = DateTime.now();
    final List<ImageUploadResult> results = [];
    int successCount = 0;
    int failCount = 0;

    try {
      final congigKey = await SupabaseConfig.getConfigKey();
      final storage = SupabaseConfig.storages[congigKey];

      if (storage == null) {
        throw Exception('Error al obtener el Storage');
      }

      // Mostrar mensaje inicial
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iniciando subida de imágenes...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      for (int i = 0; i < images.length; i++) {
        final image = images[i];

        try {
          // Obtener nombre original y limpiarlo
          String originalName = image.name;

          // Separar nombre y extensión
          final parts = originalName.split('.');
          String fileName;
          if (parts.length > 1) {
            final nameWithoutExt = parts.sublist(0, parts.length - 1).join('.');
            final formattedName = _formatFileName(nameWithoutExt.toUpperCase());
            fileName = formattedName;
          } else {
            fileName = _formatFileName(originalName.toUpperCase());
          }

          // Asegurar que el nombre no esté vacío
          if (fileName.isEmpty) {
            fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          }

          // Preparar el archivo
          final file = File(image.path);

          // Verificar que el archivo existe
          if (!await file.exists()) {
            throw Exception('El archivo no existe');
          }

          // Verificar tamaño del archivo (máximo 10MB)
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('El archivo es demasiado grande (>10MB)');
          }

          // Eliminar imagen existente si existe
          try {
            await SupabaseConfig.authenticatedStorageClient
                .from(storage)
                .remove([fileName]);
          } catch (_) {
            // Ignorar si no existe
          }

          // Subir la imagen con manejo de excepciones específico
          await SupabaseConfig.authenticatedStorageClient
              .from(storage)
              .upload(fileName, file);

          // Obtener la URL pública
          final imageUrl = '${SupabaseConfig.imagesSupabase}$fileName';

          results.add(
            ImageUploadResult(
              fileName: fileName,
              originalName: image.name,
              url: imageUrl,
              success: true,
              size: fileSize,
            ),
          );
          successCount++;
        } catch (e) {
          results.add(
            ImageUploadResult(
              fileName: image.name,
              originalName: image.name,
              url: null,
              success: false,
              error: e.toString(),
              size: await image.length(),
            ),
          );
          failCount++;

          // Mostrar error individual
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error en ${image.name}: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      return MultipleUploadResult(
        totalImages: images.length,
        successfulUploads: successCount,
        failedUploads: failCount,
        results: results,
        totalDuration: duration,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Clases auxiliares simplificadas
class ImageUploadResult {
  final String fileName;
  final String originalName;
  final String? url;
  final bool success;
  final String? error;
  final int size;

  ImageUploadResult({
    required this.fileName,
    required this.originalName,
    this.url,
    required this.success,
    this.error,
    required this.size,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class MultipleUploadResult {
  final int totalImages;
  final int successfulUploads;
  final int failedUploads;
  final List<ImageUploadResult> results;
  final Duration totalDuration;

  MultipleUploadResult({
    required this.totalImages,
    required this.successfulUploads,
    required this.failedUploads,
    required this.results,
    required this.totalDuration,
  });

  String get durationFormatted {
    final seconds = totalDuration.inSeconds;
    if (seconds < 60) return '$seconds segundos';
    final minutes = totalDuration.inMinutes;
    final remainingSeconds = seconds % 60;
    return '$minutes minutos $remainingSeconds segundos';
  }
}
