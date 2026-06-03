import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'sb_publishable_JrtzuMXTW2IODfSWrcnasA_Ogpk09U6'
  );

  final res = await client.from('users').select('*').limit(1);
  if (res.isNotEmpty) {
    print("USERS COLUMNS: ${res.first.keys.toList()}");
    print("USERS SAMPLE: ${res.first}");
  }
}
