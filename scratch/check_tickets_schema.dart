import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Try to get tickets table structure via PostgREST
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  
  // Get a sample row or structure from tickets (even if empty, will get columns from OPTIONS)
  final response = await http.get(
    Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/tickets?limit=1'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Accept': 'application/json',
    },
  );
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}');
  print('Headers: ${response.headers}');
  
  // Try inserting a test ticket with price to see if that fixes it
  print('\n--- Trying to discover tickets schema via OPTIONS ---');
  final optRes = await http.get(
    Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/?apikey=$anonKey'),
    headers: {
      'apikey': anonKey,
    },
  );
  if (optRes.statusCode == 200) {
    final data = jsonDecode(optRes.body);
    final defs = data['definitions'];
    if (defs is Map && defs.containsKey('tickets')) {
      print('tickets schema: ${jsonEncode(defs['tickets'])}');
    }
  }
}
