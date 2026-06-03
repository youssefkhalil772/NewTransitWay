import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  print('--- Testing get_nearest_bus RPC ---');
  final uri = Uri.parse('$supabaseUrl/rpc/get_nearest_bus');
  
  final request = await HttpClient().postUrl(uri)
    ..headers.add('apikey', supabaseKey)
    ..headers.add('Authorization', 'Bearer $supabaseKey')
    ..headers.contentType = ContentType.json;

  request.write(jsonEncode({"start_station_id": "75b9639b-2ef7-47fd-af3d-494293e1dce5"}));
  
  final httpResponse = await request.close();
  final body = await httpResponse.transform(utf8.decoder).join();
  
  print('Status: ${httpResponse.statusCode}');
  print('Response: $body');
}
