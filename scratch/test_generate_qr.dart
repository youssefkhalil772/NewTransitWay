import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  final driverId = '26c42a56-66d0-4138-b56f-a673adfc5fb0';

  print('Invoking generate-qr for driverId: $driverId...');
  try {
    final response = await client.functions.invoke(
      'generate-qr',
      body: {'driverId': driverId},
    );
    print('Response status: ${response.status}');
    print('Response data: ${response.data}');
  } catch (e) {
    print('Failed to invoke generate-qr: $e');
  }
}
