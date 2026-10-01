// file: edge_function_sql_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class EdgeFunctionSqlService {
  final String edgeFunctionUrl;
  final String apiKey;
  final int maxQueriesPerFile = 350; // Máximo de consultas por archivo
  bool _isProcessing = false; // Flag para evitar procesamiento múltiple

  EdgeFunctionSqlService({required this.edgeFunctionUrl, required this.apiKey});

  /// Divide el contenido SQL en partes más pequeñas
  List<SqlFilePart> _splitSqlFile(String sqlContent) {
    final List<SqlFilePart> parts = [];

    if (sqlContent.trim().isEmpty) return parts;

    // Buscar todas las sentencias SQL terminadas con punto y coma
    final List<String> statements = [];
    final lines = sqlContent.split('\n');
    StringBuffer currentStatement = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      currentStatement.writeln(line);

      // Buscar punto y coma que no esté dentro de comillas o comentarios
      if (_hasValidSemicolon(currentStatement.toString())) {
        final stmt = currentStatement.toString().trim();
        if (stmt.isNotEmpty) {
          statements.add(stmt);
        }
        currentStatement.clear();
      }
    }

    // Añadir la última sentencia si no terminó con punto y coma
    final lastStatement = currentStatement.toString().trim();
    if (lastStatement.isNotEmpty) {
      statements.add(lastStatement);
    }

    // Dividir en partes
    for (int i = 0; i < statements.length; i += maxQueriesPerFile) {
      final end = min(i + maxQueriesPerFile, statements.length);
      final partStatements = statements.sublist(i, end);
      final partContent = partStatements.join('\n\n');

      parts.add(
        SqlFilePart(
          id: parts.length + 1,
          content: partContent,
          statementCount: partStatements.length,
          startIndex: i,
          endIndex: end - 1,
          originalStatements: partStatements,
        ),
      );
    }

    return parts;
  }

  /// Verifica si una cadena tiene un punto y coma válido (no dentro de comillas/comentarios)
  bool _hasValidSemicolon(String sql) {
    final chars = sql.split('');
    bool inSingleQuote = false;
    bool inDoubleQuote = false;
    bool inLineComment = false;
    bool inBlockComment = false;

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final nextChar = i + 1 < chars.length ? chars[i + 1] : '';

      // Manejar comentarios
      if (!inSingleQuote && !inDoubleQuote && !inBlockComment) {
        if (char == '-' && nextChar == '-') {
          inLineComment = true;
          continue;
        }
        if (char == '/' && nextChar == '*') {
          inBlockComment = true;
          i++;
          continue;
        }
      }

      // Manejar fin de comentarios
      if (inBlockComment && char == '*' && nextChar == '/') {
        inBlockComment = false;
        i++;
        continue;
      }

      // Saltar si estamos en comentario
      if (inLineComment || inBlockComment) {
        if (char == '\n') inLineComment = false;
        continue;
      }

      // Manejar comillas
      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }
      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      // Si encontramos punto y coma fuera de comillas/comentarios
      if (char == ';' && !inSingleQuote && !inDoubleQuote) {
        return true;
      }
    }

    return false;
  }

  /// Envía un archivo SQL a la Edge Function, dividiéndolo si es necesario
  Future<EdgeFunctionResult> uploadSqlFile({
    required PlatformFile file,
    Function(EdgeFunctionProgress)? onProgress,
  }) async {
    // Prevenir múltiples procesamientos simultáneos
    // if (_isProcessing) {
    //   return null;
    // }

    _isProcessing = true;
    final startTime = DateTime.now();
    final List<PartResult> partResults = [];

    try {
      print(
        '[EdgeFunctionSqlService] Iniciando envío del archivo: ${file.name}',
      );

      // Validar archivo
      if (file.bytes == null || file.bytes!.isEmpty) {
        throw Exception('El archivo está vacío');
      }

      // Leer y dividir el contenido SQL
      final sqlContent = utf8.decode(file.bytes!);
      final parts = _splitSqlFile(sqlContent);

      if (parts.isEmpty) {
        throw Exception(
          'No se encontraron sentencias SQL válidas en el archivo',
        );
      }

      print(
        '[EdgeFunctionSqlService] Archivo dividido en ${parts.length} partes',
      );

      // Enviar cada parte secuencialmente
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];

        if (onProgress != null) {
          onProgress(
            EdgeFunctionProgress(
              partNumber: i + 1,
              totalParts: parts.length,
              fileName: file.name,
              bytesSent: 0,
              totalBytes: 0,
              status: 'Enviando parte ${i + 1} de ${parts.length}',
            ),
          );
        }

        print(
          '[EdgeFunctionSqlService] Enviando parte ${part.id} (sentencias ${part.startIndex}-${part.endIndex})',
        );

        // Enviar esta parte usando HTTP
        final partResult = await _sendPartToEdgeFunction(
          part,
          i + 1,
          parts.length,
        );

        partResults.add(partResult);

        // // Pequeña pausa entre partes
        // if (i < parts.length - 1) {
        //   await Future.delayed(const Duration(seconds: 10));
        // }
      }

      // Consolidar resultados
      return _consolidateResults(partResults, file, startTime, DateTime.now());
    } catch (e, stackTrace) {
      print('[EdgeFunctionSqlService] Error general: $e');
      print('[EdgeFunctionSqlService] Stack trace: $stackTrace');

      // Si hay resultados parciales, consolidarlos
      if (partResults.isNotEmpty) {
        return _consolidateResults(
          partResults,
          file,
          startTime,
          DateTime.now(),
          partialError: e.toString(),
        );
      }

      return EdgeFunctionResult(
        success: false,
        statusCode: 0,
        message: 'Error general: $e',
        duration: DateTime.now().difference(startTime),
        fileInfo: FileInfo(
          name: file.name,
          size: file.size,
          uploadTime: DateTime.now(),
        ),
        details: null,
        sqlStatistics: null,
        partResults: [],
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Envía una sola parte a la Edge Function
  Future<PartResult> _sendPartToEdgeFunction(
    SqlFilePart part,
    int currentPart,
    int totalParts,
  ) async {
    final partStartTime = DateTime.now();

    try {
      print('[EdgeFunctionSqlService] Enviando parte $currentPart/$totalParts');

      // Crear solicitud HTTP
      final request = http.MultipartRequest('POST', Uri.parse(edgeFunctionUrl));

      // Configurar timeout
      request.followRedirects = true;
      request.maxRedirects = 3;

      // Agregar archivo
      request.files.add(
        http.MultipartFile.fromBytes(
          'sqlfile',
          utf8.encode(part.content),
          filename: 'part_${currentPart}_of_$totalParts.sql',
        ),
      );

      // Agregar headers y campos
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.headers['Content-Type'] = 'multipart/form-data';
      request.headers['X-Part-Number'] = currentPart.toString();
      request.headers['X-Total-Parts'] = totalParts.toString();

      request.fields['apiKey'] = apiKey;
      request.fields['filename'] = 'part_${currentPart}_of_$totalParts.sql';
      request.fields['partNumber'] = currentPart.toString();
      request.fields['totalParts'] = totalParts.toString();

      // Enviar con timeout
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final partEndTime = DateTime.now();

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseBody);
          final summary = data['summary'] ?? {};
          final results = List<Map<String, dynamic>>.from(
            data['results'] ?? [],
          );

          final totalStatements = summary['total_statements'] ?? 0;
          final successful = summary['successful_statements'] ?? 0;
          final failed = summary['failed_statements'] ?? 0;
          final totalRowsAffected = summary['total_rows_affected'] ?? 0;

          return PartResult(
            partNumber: currentPart,
            totalParts: totalParts,
            success: failed == 0,
            statusCode: response.statusCode,
            message:
                'Parte $currentPart: ${failed == 0 ? 'Éxito' : 'Parcialmente exitoso'}',
            output: responseBody,
            details: data,
            duration: partEndTime.difference(partStartTime),
            statementCount: part.statementCount,
            totalStatements: totalStatements,
            successfulStatements: successful,
            failedStatements: failed,
            totalRowsAffected: totalRowsAffected,
            error: null,
          );
        } catch (e) {
          return PartResult(
            partNumber: currentPart,
            totalParts: totalParts,
            success: false,
            statusCode: response.statusCode,
            message: 'Parte $currentPart: Error al parsear respuesta JSON',
            output: responseBody,
            details: null,
            duration: partEndTime.difference(partStartTime),
            statementCount: part.statementCount,
            totalStatements: 0,
            successfulStatements: 0,
            failedStatements: 0,
            totalRowsAffected: 0,
            error: 'JSON Parse Error: $e',
          );
        }
      } else {
        return PartResult(
          partNumber: currentPart,
          totalParts: totalParts,
          success: false,
          statusCode: response.statusCode,
          message: 'Parte $currentPart: Error HTTP ${response.statusCode}',
          output: responseBody,
          details: null,
          duration: partEndTime.difference(partStartTime),
          statementCount: part.statementCount,
          totalStatements: 0,
          successfulStatements: 0,
          failedStatements: 0,
          totalRowsAffected: 0,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return PartResult(
        partNumber: currentPart,
        totalParts: totalParts,
        success: false,
        statusCode: 0,
        message: 'Parte $currentPart: Error de conexión',
        output: null,
        details: null,
        duration: DateTime.now().difference(partStartTime),
        statementCount: part.statementCount,
        totalStatements: 0,
        successfulStatements: 0,
        failedStatements: 0,
        totalRowsAffected: 0,
        error: e.toString(),
      );
    }
  }

  /// Consolida los resultados de todas las partes
  EdgeFunctionResult _consolidateResults(
    List<PartResult> partResults,
    PlatformFile originalFile,
    DateTime startTime,
    DateTime endTime, {
    String? partialError,
  }) {
    final totalParts = partResults.length;
    final successfulParts = partResults.where((r) => r.success).length;
    final failedParts = partResults.where((r) => !r.success).length;

    // Calcular estadísticas totales
    int totalStatements = 0;
    int successfulStatements = 0;
    int failedStatements = 0;
    int totalRowsAffected = 0;
    int totalQueries = 0;

    final classifiedErrors = <String, List<Map<String, dynamic>>>{};
    final allErrors = <Map<String, dynamic>>[];

    for (final part in partResults) {
      totalStatements += part.totalStatements;
      successfulStatements += part.successfulStatements;
      failedStatements += part.failedStatements;
      totalRowsAffected += part.totalRowsAffected;
      totalQueries += part.statementCount;

      // Consolidar errores
      if (part.details != null) {
        final results = List<Map<String, dynamic>>.from(
          part.details!['results'] ?? [],
        );
        final errors = results.where((r) => r['status'] == 'error').toList();
        allErrors.addAll(errors);
      }
    }

    // Clasificar errores
    for (final error in allErrors) {
      final errorMsg = (error['error'] as String? ?? '').toLowerCase();
      String category = 'otros';

      if (errorMsg.contains('foreign key') || errorMsg.contains('constraint')) {
        category = 'claves_foraneas';
      } else if (errorMsg.contains('syntax') || errorMsg.contains('parsing')) {
        category = 'sintaxis';
      } else if (errorMsg.contains('duplicate') ||
          errorMsg.contains('unique')) {
        category = 'duplicados';
      } else if (errorMsg.contains('date') || errorMsg.contains('time')) {
        category = 'fechas';
      } else if (errorMsg.contains('type') || errorMsg.contains('cast')) {
        category = 'tipos_datos';
      } else if (errorMsg.contains('null') || errorMsg.contains('not-null')) {
        category = 'nulos';
      }

      classifiedErrors.putIfAbsent(category, () => []);
      classifiedErrors[category]!.add(error);
    }

    // Construir mensaje
    StringBuffer messageBuffer = StringBuffer();
    messageBuffer.writeln('📊 RESUMEN DE EJECUCIÓN');
    messageBuffer.writeln('📁 Archivo: ${originalFile.name}');
    messageBuffer.writeln(
      '🔢 Partes: $totalParts (✅$successfulParts, ❌$failedParts)',
    );
    messageBuffer.writeln('');

    messageBuffer.writeln('📈 ESTADÍSTICAS SQL');
    messageBuffer.writeln('• Sentencias: $totalStatements');
    messageBuffer.writeln('• Exitosas: $successfulStatements');
    messageBuffer.writeln('• Fallidas: $failedStatements');
    messageBuffer.writeln('• Filas afectadas: $totalRowsAffected');
    messageBuffer.writeln('');

    // Mostrar errores si los hay
    if (failedStatements > 0) {
      messageBuffer.writeln('❌ ERRORES DETECTADOS');
      for (final category in classifiedErrors.keys) {
        final errors = classifiedErrors[category]!;
        messageBuffer.writeln(
          '${_getCategoryEmoji(category)} ${_getCategoryName(category)}: ${errors.length}',
        );
      }
    }

    // Determinar éxito general
    final overallSuccess = failedParts == 0 && failedStatements == 0;

    return EdgeFunctionResult(
      success: overallSuccess,
      statusCode: overallSuccess ? 200 : 500,
      message: messageBuffer.toString(),
      output: null,
      duration: endTime.difference(startTime),
      fileInfo: FileInfo(
        name: originalFile.name,
        size: originalFile.size,
        uploadTime: endTime,
      ),
      details: {
        'partResults': partResults.map((r) => r.toMap()).toList(),
        'summary': {
          'total_parts': totalParts,
          'successful_parts': successfulParts,
          'failed_parts': failedParts,
          'total_statements': totalStatements,
          'successful_statements': successfulStatements,
          'failed_statements': failedStatements,
          'total_rows_affected': totalRowsAffected,
          'total_queries': totalQueries,
        },
      },
      sqlStatistics: SqlStatistics(
        totalStatements: totalStatements,
        successfulStatements: successfulStatements,
        failedStatements: failedStatements,
        totalRowsAffected: totalRowsAffected,
        classifiedErrors: classifiedErrors,
      ),
      partResults: partResults,
    );
  }

  // ... resto de las clases (SqlFilePart, PartResult, etc.) igual que antes ...
}

/// Representa una parte del archivo SQL dividido
class SqlFilePart {
  final int id;
  final String content;
  final int statementCount;
  final int startIndex;
  final int endIndex;
  final List<String> originalStatements;

  SqlFilePart({
    required this.id,
    required this.content,
    required this.statementCount,
    required this.startIndex,
    required this.endIndex,
    required this.originalStatements,
  });
}

/// Resultado de una sola parte
class PartResult {
  final int partNumber;
  final int totalParts;
  final bool success;
  final int statusCode;
  final String message;
  final String? output;
  final dynamic details;
  final Duration duration;
  final int statementCount;
  final int totalStatements;
  final int successfulStatements;
  final int failedStatements;
  final int totalRowsAffected;
  final String? error;

  PartResult({
    required this.partNumber,
    required this.totalParts,
    required this.success,
    required this.statusCode,
    required this.message,
    required this.output,
    required this.details,
    required this.duration,
    required this.statementCount,
    required this.totalStatements,
    required this.successfulStatements,
    required this.failedStatements,
    required this.totalRowsAffected,
    required this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'partNumber': partNumber,
      'totalParts': totalParts,
      'success': success,
      'statusCode': statusCode,
      'message': message,
      'durationMs': duration.inMilliseconds,
      'statementCount': statementCount,
      'totalStatements': totalStatements,
      'successfulStatements': successfulStatements,
      'failedStatements': failedStatements,
      'totalRowsAffected': totalRowsAffected,
      'error': error,
    };
  }

  String get durationFormatted {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
}

// ... (el resto de las clases FileInfo, EdgeFunctionResult, etc. igual que antes) ...

class SqlStatistics {
  final int totalStatements;
  final int successfulStatements;
  final int failedStatements;
  final int totalRowsAffected;
  final Map<String, List<Map<String, dynamic>>> classifiedErrors;

  SqlStatistics({
    required this.totalStatements,
    required this.successfulStatements,
    required this.failedStatements,
    required this.totalRowsAffected,
    required this.classifiedErrors,
  });
}

/// Información del archivo
class FileInfo {
  final String name;
  final int size;
  final DateTime uploadTime;

  FileInfo({required this.name, required this.size, required this.uploadTime});

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Resultado de la ejecución en la Edge Function
class EdgeFunctionResult {
  final bool success;
  final int statusCode;
  final String message;
  final String? output;
  final Duration duration;
  final FileInfo fileInfo;
  final SqlStatistics? sqlStatistics;
  final dynamic details;
  final List<PartResult> partResults; // Nuevo campo para resultados por partes

  EdgeFunctionResult({
    required this.success,
    required this.statusCode,
    required this.message,
    this.output,
    required this.duration,
    required this.fileInfo,
    required this.details,
    required this.sqlStatistics,
    required this.partResults,
  });

  String get durationFormatted {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} segundos';
    }
    return '${duration.inMinutes} minutos, ${duration.inSeconds % 60} segundos';
  }
}

/// Progreso de la carga
class EdgeFunctionProgress {
  final int partNumber;
  final int totalParts;
  final String fileName;
  final int bytesSent;
  final int totalBytes;
  final String status;

  EdgeFunctionProgress({
    required this.partNumber,
    required this.totalParts,
    required this.fileName,
    required this.bytesSent,
    required this.totalBytes,
    required this.status,
  });

  double get progress => totalParts > 0 ? (partNumber - 1) / totalParts : 0.0;
  String get progressText => 'Parte $partNumber de $totalParts - $status';
}

String _getCategoryEmoji(String category) {
  switch (category) {
    case 'claves_foraneas':
      return '🔗';
    case 'sintaxis':
      return '📝';
    case 'duplicados':
      return '🔄';
    case 'fechas':
      return '📅';
    case 'tipos_datos':
      return '🔢';
    case 'nulos':
      return '🚫';
    default:
      return '❓';
  }
}

String _getCategoryName(String category) {
  switch (category) {
    case 'claves_foraneas':
      return 'Errores de claves foráneas';
    case 'sintaxis':
      return 'Errores de sintaxis SQL';
    case 'duplicados':
      return 'Registros duplicados';
    case 'fechas':
      return 'Problemas con fechas';
    case 'tipos_datos':
      return 'Tipos de datos incorrectos';
    case 'nulos':
      return 'Violaciones de NOT NULL';
    default:
      return 'Otros errores';
  }
}
