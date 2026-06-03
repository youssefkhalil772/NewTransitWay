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

  // Get drivers full data
  print('=== DRIVERS FULL DATA ===');
  final driversRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/drivers?select=*'),
    headers: headers,
  );
  stdout.write(driversRes.body);
  print('');

  print('\n=== USERS (all) ===');
  final usersRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/users?select=id,name,email,role&limit=10'),
    headers: headers,
  );
  stdout.write(usersRes.body);
  print('');
}
