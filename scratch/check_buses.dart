import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  print('=== BUSES DATA ===');
  final busesRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/buses?select=*'),
    headers: headers,
  );
  stdout.write(busesRes.body);
}
