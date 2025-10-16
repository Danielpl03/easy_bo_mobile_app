import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:easy_bo_mobile_app/models/documento.dart';
import 'package:easy_bo_mobile_app/models/movimiento.dart';
import 'package:easy_bo_mobile_app/models/documentos_con_flujos.dart'; // Importar el nuevo modelo

class JsonImportService {
  /// Permite al usuario seleccionar un archivo JSON y lo lee como String
  Future<String?> pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return await file.readAsString();
    }
    return null;
  }

  /// Parsea el JSON a una lista de documentos y movimientos
  Future<List<Documento>> parseDocumentosFromJson(String jsonString) async {
    final List<dynamic> data = json.decode(jsonString);
    List<Documento> documentos = [];
    for (final docJson in data) {
      final doc = Documento.fromJson(docJson);
      if (docJson['movimientos'] != null) {
        doc.movimientos = (docJson['movimientos'] as List)
            .map((m) => Movimiento.fromJson(m))
            .toList();
      }
      documentos.add(doc);
    }
    return documentos;
  }

  /// Parsea el JSON a una respuesta de ventas (VentasResponse)
  Future<List<DocumentosConFlujos>> parseDocumentosConFlujosFromJson(String jsonString) async {
    final List<dynamic> data = json.decode(jsonString);
      return data.map( (d) => DocumentosConFlujos.fromJson(d)).toList();
  }
} 