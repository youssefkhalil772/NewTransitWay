import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  print('--- Fetching all routes ---');
  final uri = Uri.parse('$supabaseUrl/routes');
  
  final response = await HttpClient().getUrl(uri)
    ..headers.add('apikey', supabaseKey)
    ..headers.add('Authorization', 'Bearer $supabaseKey');

  final httpResponse = await response.close();
  final body = await httpResponse.transform(utf8.decoder).join();
  
  print('Status: ${httpResponse.statusCode}');
  print('Response: $body');
}
