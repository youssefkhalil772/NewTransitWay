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

  final mockComplaint = {
    'user_id': 'cfd0e8a0-b658-49a7-ba31-c97f174fae4c',
    'subject': 'Bus Complaint (AI Processed)',
    'description': 'This is a test description from script.',
    'problem_detected': true,
    'reporter_name': 'Yousef khalil',
    'reporter_role': 'Passenger',
    'status': 'Pending',
    'original_image': 'https://vrgcsoeepbwnedzjwiqb.supabase.co/storage/v1/object/public/complaints/test.jpg',
    'processed_image': 'http://54.91.157.86:8000/outputs/test.jpg',
    'ai_predictions': [],
    'created_at': DateTime.now().toIso8601String(),
  };

  print('=== INSERTING COMPLAINT ===');
  final res = await http.post(
    Uri.parse('$baseUrl/rest/v1/complaints'),
    headers: headers,
    body: jsonEncode(mockComplaint),
  );

  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
