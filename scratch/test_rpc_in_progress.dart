import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  print('--- Updating trip status to in_progress ---');
  final uri = Uri.parse('$supabaseUrl/trips?bus_id=eq.ddade035-3496-4cce-9047-06acc223b854');
  
  final updateRequest = await HttpClient().patchUrl(uri)
    ..headers.add('apikey', supabaseKey)
    ..headers.add('Authorization', 'Bearer $supabaseKey')
    ..headers.contentType = ContentType.json;

  updateRequest.write(jsonEncode({"status": "in_progress"}));
  
  final updateResponse = await updateRequest.close();
  print('Update Status: ${updateResponse.statusCode}');

  print('--- Testing get_nearest_bus RPC again ---');
  final rpcUri = Uri.parse('$supabaseUrl/rpc/get_nearest_bus');
  
  final request = await HttpClient().postUrl(rpcUri)
    ..headers.add('apikey', supabaseKey)
    ..headers.add('Authorization', 'Bearer $supabaseKey')
    ..headers.contentType = ContentType.json;

  request.write(jsonEncode({"start_station_id": "75b9639b-2ef7-47fd-af3d-494293e1dce5"}));
  
  final httpResponse = await request.close();
  final body = await httpResponse.transform(utf8.decoder).join();
  
  print('RPC Status: ${httpResponse.statusCode}');
  print('RPC Response: $body');
}
