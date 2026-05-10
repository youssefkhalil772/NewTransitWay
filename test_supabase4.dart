import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final url = Uri.parse('https://jajoznoeoewigkpbuzzx.supabase.co/rest/v1/?apikey=sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE');
  
  try {
    final response = await http.get(url, headers: {
      'apikey': 'sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE',
      'Authorization': 'Bearer sb_publishable_zNYeNGu6L5zd2pi_Eigl4g_LyCdk2uE',
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
