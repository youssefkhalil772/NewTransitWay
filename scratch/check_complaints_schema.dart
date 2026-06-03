import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const projectRef = 'vrgcsoeepbwnedzjwiqb';
  const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDQyMDA2NywiZXhwIjoyMDk1OTk2MDY3fQ.Zl4k7Bq3eFhPqNXYh6Z4N1N4eLzN7f4eN4f4N4f4N4';
  final baseUrl = 'https://$projectRef.supabase.co';

  final headers = {
    'apikey': serviceKey,
    'Authorization': 'Bearer $serviceKey',
    'Accept': 'application/openapi+json',
  };

  print('=== FETCHING OPENAPI SCHEMA ===');
  final res = await http.get(
    Uri.parse('$baseUrl/rest/v1/'),
    headers: headers,
  );
  if (res.statusCode == 200) {
    final spec = jsonDecode(res.body);
    final definitions = spec['definitions'];
    if (definitions != null && definitions['complaints'] != null) {
      print('Complaints definition:');
      print(jsonEncode(definitions['complaints']));
    } else {
      print('Complaints definition not found. Available keys: ${definitions?.keys.toList()}');
    }
  } else {
    print('Failed with status: ${res.statusCode}');
    print(res.body);
  }
}
