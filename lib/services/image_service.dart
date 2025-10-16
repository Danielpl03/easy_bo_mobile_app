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

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();

  // Función para formatear el nombre del archivo según las reglas especificadas
  String _formatFileName(String text) {
    return text
        .replaceAll(
          RegExp(r'[<>:"/\\|?*¨ñÑ&´´]'),
          '_',
        ) // Reemplazar caracteres especiales
        .replaceAll(' ', '_').toUpperCase(); // Reemplazar espacios
  }

  // Obtener la URL de la imagen de un producto desde Supabase Storage
  String getProductImageUrl(Producto producto) {
    final formattedName = _formatFileName(
      producto.fullDescripction(uppercase: true),
    );
    // Usar la URL pública de Supabase Storage
    return '${SupabaseConfig.imagesSupabase}$formattedName';
  }

  // Widget para mostrar la imagen de un producto con caché
  Widget getProductImage(Producto producto, {double? width, double? height}) {
    return CachedNetworkImage(
      imageUrl: getProductImageUrl(producto),
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
      await precacheImage(CachedNetworkImageProvider(imageUrl), context).onError((e, _) => false);
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
  Future<String?> uploadProductImage(
    Producto producto,
    BuildContext context,
  ) async {
    try {
      // Obtener la URL actual de la imagen para limpiar la caché después
      final currentImageUrl = getProductImageUrl(producto);

      // Mostrar diálogo para elegir fuente de imagen
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

      // Preparar el archivo para subir
      final file = File(image.path);
      final formattedName = _formatFileName(producto.fullDescripction());

      // Eliminar imagen existente en Supabase Storage (si existe)
      try {
        await SupabaseConfig.authenticatedStorageClient
          .from('mlsoluciones')
          .remove([formattedName]);
      } catch (_) {}

      // Subir la nueva imagen
      final response = await SupabaseConfig.authenticatedStorageClient
        .from('mlsoluciones')
        .upload(formattedName, file);

      if (response.isNotEmpty) {
        // Limpiar la caché de la imagen anterior
        await clearImageCache(currentImageUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen subida exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Retornar la URL pública
        return getProductImageUrl(producto);
      } else {
        throw Exception('Error al subir la imagen');
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

  // Eliminar la imagen de un producto en Supabase Storage
  Future<void> deleteProductImage(Producto producto) async {
    try {
      final formattedName = _formatFileName(producto.fullDescripction());
      await SupabaseConfig.authenticatedStorageClient
        .from('mlsoluciones')
        .remove([formattedName]);
    } catch (e) {
      rethrow;
    }
  }

  // Descargar la imagen de un producto
  Future<void> downloadProductImage(
    Producto producto,
    BuildContext context,
  ) async {
    try {
      // Solicitar permiso de almacenamiento
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Se requieren permisos de almacenamiento para descargar la imagen.');
      }

      final imageUrl = getProductImageUrl(producto);
      final fileName = '${_formatFileName(producto.fullDescripction())}.jpg';

      // Obtener el directorio de descargas
      final directory = Directory('/storage/emulated/0/Download');
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
}
