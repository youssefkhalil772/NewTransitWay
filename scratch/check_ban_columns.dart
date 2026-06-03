import 'dart:convert';
import 'package:supabase/supabase.dart';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Fetching users and drivers to see their ban status...');
  
  try {
    final drivers = await client.from('drivers').select().limit(1);
    if (drivers.isNotEmpty) {
      print('Driver columns: \${drivers.first.keys.toList()}');
      print('First driver: \${jsonEncode(drivers.first)}');
    }
    
    final users = await client.from('users').select().limit(1);
    if (users.isNotEmpty) {
      print('User columns: \${users.first.keys.toList()}');
      print('First user: \${jsonEncode(users.first)}');
    }
  } catch (e) {
    print('Error: \$e');
  }
}
