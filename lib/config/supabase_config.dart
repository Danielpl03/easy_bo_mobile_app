import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xymgsntzhkygkbutltty.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5bWdzbnR6aGt5Z2tidXRsdHR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2NjMzODQsImV4cCI6MjA0ODIzOTM4NH0.kKouuGA2AB71K0uESlpb9F2jEMQAO1sz5_y3lnt-CD0';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
} 