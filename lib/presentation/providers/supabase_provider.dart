import 'package:easy_bo_mobile_app/services/supabase_service.dart';
import 'package:flutter/material.dart';

class SupabaseProvider extends ChangeNotifier {
  final SupabaseService _supabaseService;

  SupabaseService get supabaseService => _supabaseService;

  SupabaseProvider(this._supabaseService);

  // SupabaseProvider() {
  //   _supabaseClient.auth.onAuthStateChange.listen((event) {
  //     if (event.event == AuthChangeEvent.signedIn) {
  //       notifyListeners();
  //     }
  //   });
  // }
}

