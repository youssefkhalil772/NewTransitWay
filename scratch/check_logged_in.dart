import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  print('Trying to select from route_qrs...');
  try {
    final res = await supabase.from('route_qrs').select('*').limit(1);
    print('Select result: $res');
  } catch (e) {
    print('Select failed: $e');
  }
}
