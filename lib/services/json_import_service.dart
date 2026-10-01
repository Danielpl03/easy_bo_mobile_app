import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  /// Parsea el JSON a una respuesta de documentos con flujos (DocumentosConFlujos)
  Future<List<DocumentosConFlujos>> parseDocumentosConFlujosFromJson(
    String jsonString,
  ) async {
    final List<dynamic> data = json.decode(jsonString);
    return data.map((d) => DocumentosConFlujos.fromJson(d)).toList();
  }
}
