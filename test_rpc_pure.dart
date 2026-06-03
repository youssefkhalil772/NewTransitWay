import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/rpc/get_user_email_by_phone');
  final key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  
  final request = await HttpClient().postUrl(url);
  request.headers.add('apikey', key);
  request.headers.add('Authorization', 'Bearer ' + key);
  request.headers.add('Content-Type', 'application/json');
  
  request.write(jsonEncode({'p_phone': '01234567890'}));
  
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + responseBody);
}
