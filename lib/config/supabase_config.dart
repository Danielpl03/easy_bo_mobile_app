import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _configKeyPrefsKey = 'supabase_config_key';

  /// Lista de claves válidas que pueden ser usadas por los usuarios
  /// Agregar nuevas empresas aquí
  static const List<String> validConfigKeys = [
    'mlsoluciones',
    'la_calzada',
    // Agregar más claves aquí cuando sea necesario
    // Ejemplo: 'empresa_x', 'empresa_y', etc.
  ];
  static const Map<String, String> storages = {
    'mlsoluciones': 'mlsoluciones',
    'la_calzada': 'la_calzada',
  };

  static String? _configKey;
  static SupabaseClient? _authenticatedClient;

  /// Establece la clave de configuración de Supabase
  ///
  /// [key] es la clave que identifica qué configuración usar.
  /// Por ejemplo: 'default', 'la_calzada', 'empresa_x', etc.
  ///
  /// Si [key] es null o 'default', se usarán las variables sin prefijo:
  /// SUPABASE_URL, SUPABASE_ANON_KEY, etc.
  ///
  /// Si [key] es 'la_calzada', se usarán:
  /// SUPABASE_LA_CALZADA_URL, SUPABASE_LA_CALZADA_ANON_KEY, etc.
  ///
  /// Si [key] es 'empresa_x', se usarán:
  /// SUPABASE_EMPRESA_X_URL, SUPABASE_EMPRESA_X_ANON_KEY, etc.
  static Future<void> setConfigKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      _configKey = null;
      await prefs.remove(_configKeyPrefsKey);
    } else {
      final normalizedKey = key.toLowerCase().trim().replaceAll(' ', '_');
      // Validar que la clave sea válida antes de guardarla
      if (!isValidConfigKey(normalizedKey)) {
        throw ArgumentError('La clave "$key" no es válida.}');
      }
      _configKey = normalizedKey;
      await prefs.setString(_configKeyPrefsKey, _configKey!);
    }
  }

  /// Obtiene la clave de configuración actual de Supabase
  static Future<String?> getConfigKey() async {
    if (_configKey != null) {
      return _configKey;
    }

    final prefs = await SharedPreferences.getInstance();
    _configKey = prefs.getString(_configKeyPrefsKey);
    return _configKey;
  }

  /// Valida si una clave de configuración es válida
  ///
  /// [key] es la clave a validar
  /// Retorna true si la clave está en la lista de claves válidas
  static bool isValidConfigKey(String? key) {
    if (key == null || key.isEmpty) {
      return false;
    }
    // Normalizar la clave (lowercase) para comparar
    final normalizedKey = key.toLowerCase().trim().replaceAll(' ', '_');
    return validConfigKeys.contains(normalizedKey);
  }

  /// Obtiene todas las claves válidas disponibles
  static List<String> getAvailableConfigKeys() {
    return List.unmodifiable(validConfigKeys);
  }

  /// Verifica si hay una clave de configuración guardada
  static Future<bool> hasConfigKey() async {
    final key = await getConfigKey();
    return key != null && key.isNotEmpty;
  }

  /// Normaliza la clave para construir el nombre de la variable de entorno
  /// Convierte a mayúsculas y reemplaza espacios/guiones por guiones bajos
  static String _normalizeKey(String key) {
    return key.toUpperCase().replaceAll(RegExp(r'[\s-]'), '_');
  }

  /// Construye el nombre de la variable de entorno basándose en la clave de configuración
  static String _getEnvVarName(String baseName) {
    final configKey = _configKey;
    if (configKey == null || configKey.isEmpty) {
      return baseName;
    }
    final normalizedKey = _normalizeKey(configKey);
    return '${normalizedKey}_$baseName';
  }

  static String get supabaseUrl {
    final envVarName = _getEnvVarName('SUPABASE_URL');
    return dotenv.env[envVarName] ?? '';
  }

  static String get supabaseAnonKey {
    final envVarName = _getEnvVarName('SUPABASE_ANON_KEY');
    return dotenv.env[envVarName] ?? '';
  }

  static String get imagesSupabase {
    final envVarName = _getEnvVarName('SUPABASE_STORAGE_URL');
    return dotenv.env[envVarName] ?? '';
  }

  static String get serviceRoleKey {
    final envVarName = _getEnvVarName('SUPABASE_SERVICE_ROLE_KEY');
    return dotenv.env[envVarName] ?? '';
  }

  static Future<void> initialize({String? configKey}) async {
    // Load environment variables
    await dotenv.load();

    // Si se proporciona una clave, establecerla
    if (configKey != null) {
      await setConfigKey(configKey);
    } else {
      // Si no se proporciona, intentar cargar la guardada
      await getConfigKey();
    }

    // Validate that all required environment variables are present
    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        serviceRoleKey.isEmpty) {
      final currentKey = _configKey ?? 'default';
      throw Exception(
        'Missing required Supabase environment variables for config key: "$currentKey". '
        'Please check your .env file. Expected variables: '
        '${_getEnvVarName("SUPABASE_URL")}, '
        '${_getEnvVarName("SUPABASE_ANON_KEY")}, '
        '${_getEnvVarName("SUPABASE_SERVICE_ROLE_KEY")}',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    // Initialize authenticated client for storage operations
    _authenticatedClient = SupabaseClient(supabaseUrl, serviceRoleKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseStorageClient get storageClient => client.storage;

  // Authenticated storage client using service role key for upload/delete operations
  static SupabaseStorageClient get authenticatedStorageClient {
    if (_authenticatedClient == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() first.',
      );
    }
    return _authenticatedClient!.storage;
  }
}
