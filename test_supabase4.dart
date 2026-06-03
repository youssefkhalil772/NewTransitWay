import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final url = Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/?apikey=sb_publishable_JrtzuMXTW2IODfSWrcnasA_Ogpk09U6');
  
  try {
    final response = await http.get(url, headers: {
      'apikey': 'sb_publishable_JrtzuMXTW2IODfSWrcnasA_Ogpk09U6',
      'Authorization': 'Bearer sb_publishable_JrtzuMXTW2IODfSWrcnasA_Ogpk09U6',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final paths = data['paths'] as Map<String, dynamic>;
      final tables = paths.keys.where((k) => k.startsWith('/') && k.length > 1).map((k) => k.substring(1)).toList();
      print("ALL TABLES: $tables");
    } else {
      print("ERROR: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("HTTP ERROR: $e");
  }
}
