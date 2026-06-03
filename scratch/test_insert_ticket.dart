import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  print('--- Attempting to insert ticket ---');
  final uri = Uri.parse('$supabaseUrl/tickets');
  
  final updateRequest = await HttpClient().postUrl(uri)
    ..headers.add('apikey', supabaseKey)
    ..headers.add('Authorization', 'Bearer $supabaseKey')
    ..headers.contentType = ContentType.json;

  updateRequest.write(jsonEncode({
    "user_id": "7afafd1d-4b13-42d0-8043-37aa9dfd9b56",
    "bus_id": "ddade035-3496-4cce-9047-06acc223b854",
    "route_id": "9d9f642d-31cd-4cb1-ae7e-daf930983bcf",
    "ticket_code": "MANUAL-TEST",
    "status": "active",
    "price": 13
  }));
  
  final updateResponse = await updateRequest.close();
  final body = await updateResponse.transform(utf8.decoder).join();
  print('Update Status: ${updateResponse.statusCode}');
  print('Response: $body');
}
