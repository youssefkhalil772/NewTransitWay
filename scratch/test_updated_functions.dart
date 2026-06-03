import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Project credentials
  const projectRef = 'vrgcsoeepbwnedzjwiqb';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://$projectRef.supabase.co';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  print('=== TEST GENERATE-QR ===');
  // Using an existing driver ID
  final req = await http.post(
    Uri.parse('$baseUrl/functions/v1/generate-qr'),
    headers: headers,
    body: jsonEncode({"driverId": "c9ed49d6-f064-4810-8242-a81215e8cb60"}),
  );
  print('Generate QR Status: ${req.statusCode}');
  print('Generate QR Response: ${req.body}');

  print('\n=== TEST SCAN-PAY ===');
  // Using an existing user ID and a fake token to see the error message
  final req2 = await http.post(
    Uri.parse('$baseUrl/functions/v1/scan-pay'),
    headers: headers,
    body: jsonEncode({"userId": "51a46893-3702-41c8-90e2-0ed79eb93a29", "qrToken": "FAKE_TOKEN"}),
  );
  print('Scan Pay Status: ${req2.statusCode}');
  print('Scan Pay Response: ${req2.body}');
}
