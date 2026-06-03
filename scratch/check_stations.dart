import 'dart:convert';
import 'dart:io';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  const url = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/stations?limit=5';
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('apikey', anonKey);
    request.headers.set('Authorization', 'Bearer $anonKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('STATUS: ${response.statusCode}');
    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      if (json is List && json.isNotEmpty) {
        print('STATIONS KEYS: ${json[0].keys.toList()}');
        print('FIRST STATION: ${json[0]}');
      } else {
        print('Empty response or not a list: $responseBody');
      }
    } else {
      print('Failed: $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
