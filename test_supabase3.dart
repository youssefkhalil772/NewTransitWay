import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://jajoznoeoewigkpbuzzx.supabase.co',
    'sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE'
  );

  // You can execute a generic query to see the tables if RPC or REST allows it, but normally you cannot directly query information_schema from the anon client.
  // Instead let's just try typical names.
  final names = ['route', 'bus_routes', 'zones', 'route_stations'];
  
  for(var name in names) {
    try {
      final res = await client.from(name).select('*').limit(1);
      print("TABLE $name EXISTS: $res");
    } catch (e) {
      // ignore
    }
  }
}
