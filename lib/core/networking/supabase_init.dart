import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://jajoznoeoewigkpbuzzx.supabase.co';
  static const String supabaseKey = 'sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
