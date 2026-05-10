import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://jajoznoeoewigkpbuzzx.supabase.co',
    'sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE'
  );

  try {
    final buses = await client.from('buses').select('*');
    print("BUSES: $buses");
  } catch (e) {
    print("BUSES ERROR: $e");
  }
}
