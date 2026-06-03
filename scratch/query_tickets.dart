import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  print('=== TICKETS ===');
  try {
    final tickets = await client.from('tickets').select('*').limit(1);
    print(tickets);
  } catch (e) {
    print('Error querying tickets: $e');
  }
}
