import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Accept': 'application/json',
  };

  print('--- Tickets ---');
  final tickets = await http.get(Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/tickets?select=route_id,bus_id,price&limit=2'), headers: headers);
  print(tickets.body);

  print('\n--- Routes ---');
  final routes = await http.get(Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/routes?select=id,name,start_point,line_number&limit=2'), headers: headers);
  print(routes.body);
  
  print('\n--- Buses ---');
  final buses = await http.get(Uri.parse('https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/buses?select=id,bus_number&limit=2'), headers: headers);
  print(buses.body);
}
