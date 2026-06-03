import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';

  // Step 1: Check sos_alerts table structure
  print('=== CHECK sos_alerts TABLE ===');
  final tableRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/sos_alerts?limit=1'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
    },
  );
  print('Status: ${tableRes.statusCode}');
  print('Body: ${tableRes.body}');

  // Step 2: Try direct insert with anon key
  print('\n=== TRY DIRECT INSERT (anon) ===');
  final insertRes = await http.post(
    Uri.parse('$baseUrl/rest/v1/sos_alerts'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: jsonEncode({
      'driver_id': 'c9ed49d6-f064-4810-8242-a81215e8cb60',
      'bus_id': 'bccc6eb2-9cb2-4f93-8f81-b59a266fdeb3',
      'latitude': 30.0,
      'longitude': 31.0,
      'status': 'Pending',
    }),
  );
  print('Status: ${insertRes.statusCode}');
  print('Body: ${insertRes.body}');

  // Step 3: Try calling the Edge Function directly
  print('\n=== TRY EDGE FUNCTION sos-alert ===');
  final fnRes = await http.post(
    Uri.parse('$baseUrl/functions/v1/sos-alert'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'action': 'trigger',
      'driver_id': 'c9ed49d6-f064-4810-8242-a81215e8cb60',
      'bus_id': 'bccc6eb2-9cb2-4f93-8f81-b59a266fdeb3',
      'latitude': 30.0,
      'longitude': 31.0,
    }),
  );
  print('Status: ${fnRes.statusCode}');
  print('Body: ${fnRes.body}');
}
