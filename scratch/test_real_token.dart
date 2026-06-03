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

  print('=== TEST SCAN-PAY WITH REAL TOKEN ===');
  // Token generated from previous step
  final token = "ACA67CC917754E638BBEFCF4E68E7359";
  final req = await http.post(
    Uri.parse('$baseUrl/functions/v1/scan-pay'),
    headers: headers,
    body: jsonEncode({"userId": "51a46893-3702-41c8-90e2-0ed79eb93a29", "qrToken": token}),
  );
  print('Scan Pay Status: ${req.statusCode}');
  print('Scan Pay Response: ${req.body}');
}
