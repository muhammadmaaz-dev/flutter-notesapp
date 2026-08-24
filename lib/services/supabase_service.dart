import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl = 'https://nyvtcwpjhijyhowubytz.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_5D_TZ6Z4ke2Y-wbx_0lRLA_PGz0tseN';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
      _isInitialized = true;
      debugPrint("Supabase initialized successfully.");
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
}
