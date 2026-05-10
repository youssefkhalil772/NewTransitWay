import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://jajoznoeoewigkpbuzzx.supabase.co',
    'sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE'
  );

  final res = await client.from('users').select('*').limit(1);
  if (res.isNotEmpty) {
    print("USERS COLUMNS: ${res.first.keys.toList()}");
    print("USERS SAMPLE: ${res.first}");
  }
}
