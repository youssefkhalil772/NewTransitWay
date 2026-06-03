import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Accept': 'application/json',
  };

  print('--- Checking buses ---');
  final res = await http.get(Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/buses?limit=1'), headers: headers);
  print(res.body);
  
  print('--- Checking drivers ---');
  final res2 = await http.get(Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/drivers?limit=1'), headers: headers);
  print(res2.body);
}
