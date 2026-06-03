import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Use Supabase Management API to list deployed edge functions
  // The project ref is 'vrgcsoeepbwnedzjwiqb' (from the Supabase URL)
  // We need the management API token - but we don't have it.
  // Instead, let's try invoking each function with an empty body and see what status we get:
  // 404 = not deployed, anything else = exists

  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/functions/v1';

  final functions = [
    'generate-qr',
    'scan-pay',
    'Manual-Tickets',
    'create-manual-tickets',
    'paymob-pay',
    'report-complaint',
  ];

  print('Checking which edge functions are deployed:\n');
  for (final fn in functions) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$fn'),
        headers: {
          'Authorization': 'Bearer $anonKey',
          'Content-Type': 'application/json',
        },
        body: '{}',
      );
      final status = response.statusCode;
      if (status == 404) {
        print('❌ $fn → NOT DEPLOYED (404)');
      } else {
        print('✅ $fn → DEPLOYED (status: $status)');
      }
    } catch (e) {
      print('⚠️ $fn → ERROR: $e');
    }
  }
}
