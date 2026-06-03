import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'sb_publishable_JrtzuMXTW2IODfSWrcnasA_Ogpk09U6'
  );

  try {
    final buses = await client.from('buses').select('*');
    print("BUSES: $buses");
  } catch (e) {
    print("BUSES ERROR: $e");
  }
}
