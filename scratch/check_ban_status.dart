import 'package:http/http.dart' as http;
import 'dart:convert';

const supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

Future<List<Map<String, dynamic>>> query(String table) async {
  final res = await http.get(Uri.parse('$supabaseUrl/rest/v1/$table?select=*'), headers: {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
  });
  return List<Map<String, dynamic>>.from(jsonDecode(res.body));
}

void main() async {
  print('=== Checking users with ban_reason ===');
  final users = await query('users');
  for (final u in users) {
    print('User: ${u['email']}');
    print('  is_banned: ${u['is_banned']} (${u['is_banned'].runtimeType})');
    print('  ban_reason: ${u['ban_reason']}');
    print('');
  }
}
