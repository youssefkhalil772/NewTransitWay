import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const projectRef = 'vrgcsoeepbwnedzjwiqb';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://$projectRef.supabase.co';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  final driverId = "c9ed49d6-f064-4810-8242-a81215e8cb60";
  final busId = "bccc6eb2-9cb2-4f93-8f81-b59a266fdeb3";
  final routeId = "abc6a637-37af-41c4-b2ab-afe3de46c30b";

  print('1. Setting up a dummy active trip...');
  await http.post(
    Uri.parse('$baseUrl/rest/v1/trips'),
    headers: headers,
    body: jsonEncode({
      "bus_id": busId,
      "route_id": routeId,
      "status": "active"
    }),
  );

  print('2. Calling generate-qr FIRST time...');
  final r1 = await http.post(
    Uri.parse('$baseUrl/functions/v1/generate-qr'),
    headers: headers,
    body: jsonEncode({"driverId": driverId}),
  );
  print('First token: ${jsonDecode(r1.body)['token']}');

  print('3. Calling generate-qr SECOND time...');
  final r2 = await http.post(
    Uri.parse('$baseUrl/functions/v1/generate-qr'),
    headers: headers,
    body: jsonEncode({"driverId": driverId}),
  );
  print('Second token: ${jsonDecode(r2.body)['token']}');

  if (jsonDecode(r1.body)['token'] == jsonDecode(r2.body)['token']) {
    print('✅ SUCCESS: Tokens are the SAME! The code IS updated.');
  } else {
    print('❌ FAILED: Tokens are DIFFERENT! The user did NOT deploy the code properly.');
  }
}
