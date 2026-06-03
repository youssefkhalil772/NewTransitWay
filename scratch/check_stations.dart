import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  Future<void> checkTable(String table) async {
    print('--- Checking $table ---');
    final uri = Uri.parse('$supabaseUrl/$table?limit=5');
    final response = await HttpClient().getUrl(uri)
      ..headers.add('apikey', supabaseKey)
      ..headers.add('Authorization', 'Bearer $supabaseKey');

    final httpResponse = await response.close();
    final body = await httpResponse.transform(utf8.decoder).join();
    
    if (httpResponse.statusCode == 200) {
      print(body);
    } else {
      print('Failed to fetch $table: ${httpResponse.statusCode} - $body');
    }
  }

  await checkTable('stations');
}
