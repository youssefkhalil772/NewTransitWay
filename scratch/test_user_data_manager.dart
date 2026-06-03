import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  print('Fetching routes...');
  final response = await http.get(Uri.parse('$baseUrl/rest/v1/routes?select=*'), headers: headers);
  final routes = jsonDecode(response.body) as List;
  
  Map<String, String> routeNamesByUuid = {};
  for (final json in routes) {
    final name = json['name']?.toString() ??
        json['start_point']?.toString() ??
        json['line_number'].toString();
    if (json['id'] != null) {
      routeNamesByUuid[json['id'].toString()] = name;
    }
  }

  print('Map: $routeNamesByUuid');

  print('\nFetching tickets...');
  final ticketsResponse = await http.get(Uri.parse('$baseUrl/rest/v1/tickets?select=*&limit=3'), headers: headers);
  final tickets = jsonDecode(ticketsResponse.body) as List;

  for (final ticket in tickets) {
    final routeIdVal = ticket['route_id']?.toString();
    String routeName = '---';
    if (routeIdVal != null) {
      routeName = routeNamesByUuid[routeIdVal] ?? '---';
    }
    print('Ticket ${ticket['id']} -> Route ID: $routeIdVal -> Name: $routeName');
  }
}
