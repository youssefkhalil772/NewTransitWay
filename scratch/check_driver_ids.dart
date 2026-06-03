import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  // Check drivers table - what columns it has
  print('=== DRIVERS FULL DATA ===');
  final driversRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/drivers?select=*&limit=3'),
    headers: headers,
  );
  final drivers = jsonDecode(driversRes.body) as List;
  if (drivers.isNotEmpty) {
    print('Columns: ${(drivers.first as Map).keys.toList()}');
    for (final d in drivers) {
      print('  ${jsonEncode(d)}');
    }
  }

  // Check users table for drivers
  print('\n=== USERS WITH DRIVER ROLE ===');
  final usersRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/users?role=eq.driver&select=id,name,email,role'),
    headers: headers,
  );
  final users = jsonDecode(usersRes.body) as List;
  for (final u in users) {
    print('  ${jsonEncode(u)}');
  }
}
