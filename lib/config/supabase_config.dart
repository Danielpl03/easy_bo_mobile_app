import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get imagesSupabase => dotenv.env['SUPABASE_STORAGE_URL'] ?? '';
  static String get serviceRoleKey => dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  static SupabaseClient? _authenticatedClient;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    
    // Initialize authenticated client for storage operations
    _authenticatedClient = SupabaseClient(
      supabaseUrl,
      serviceRoleKey,
    // Load environment variables
    await dotenv.load();
    
    // Validate that all required environment variables are present
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty || serviceRoleKey.isEmpty) {
      throw Exception('Missing required Supabase environment variables. Please check your .env file.');
    }
    
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    
    // Initialize authenticated client for storage operations
    _authenticatedClient = SupabaseClient(
      supabaseUrl,
      serviceRoleKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static SupabaseStorageClient get storageClient => client.storage;
  
  // Authenticated storage client using service role key for upload/delete operations
  static SupabaseStorageClient get authenticatedStorageClient {
    if (_authenticatedClient == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _authenticatedClient!.storage;
  }
}


  static SupabaseStorageClient get storageClient => client.storage;
  
  // Authenticated storage client using service role key for upload/delete operations
  static SupabaseStorageClient get authenticatedStorageClient {
    if (_authenticatedClient == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _authenticatedClient!.storage;
  }
}
