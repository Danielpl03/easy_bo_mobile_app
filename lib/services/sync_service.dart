import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Envía un archivo .sql a la Edge Function.
/// [functionUrl] debe ser la URL HTTPS de la Edge Function: e.g. https://<project>.functions.supabase.co/sql-file-executor
Future<http.Response> uploadSqlFile({
  required Uri functionUrl,
  required File sqlFile,
  Map<String, String>?
  headers, // opcional: añadir Authorization si tienes control de acceso
}) async {
  final request = http.MultipartRequest('POST', functionUrl);

  // Adjuntar cabeceras adicionales si las necesitas
  if (headers != null) {
    request.headers.addAll(headers);
  }

  // Agregar el archivo como campo 'sqlfile'
  final multipartFile = http.MultipartFile.fromBytes(
    'sqlfile',
    await sqlFile.readAsBytes(),
    filename: path.basename(sqlFile.path),
  );

  request.files.add(multipartFile);

  // Enviar y esperar respuesta
  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  return response;
}
