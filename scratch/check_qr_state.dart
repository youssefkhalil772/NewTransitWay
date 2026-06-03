import 'package:http/http.dart' as http;
import 'dart:convert';

// NOTE: We need the service role key to update data
// Using anon key won't work for updates unless RLS allows it
void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  print('=== ALL ROUTE_QRS ===');
  final qrs = await http.get(
    Uri.parse('$baseUrl/rest/v1/route_qrs?select=*'),
    headers: headers,
  );
  final qrList = jsonDecode(qrs.body) as List;
  for (final q in qrList) {
    print('  ID: ${q['id']}');
    print('  token: ${q['token']}');
    print('  bus_id: ${q['bus_id']}');
    print('  is_active: ${q['is_active']}');
    print('  ---');
  }

  print('\n=== ALL TRIPS ===');
  final trips = await http.get(
    Uri.parse('$baseUrl/rest/v1/trips?select=*&order=created_at.desc&limit=5'),
    headers: headers,
  );
  final tripList = jsonDecode(trips.body) as List;
  for (final t in tripList) {
    print('  ID: ${t['id']}');
    print('  bus_id: ${t['bus_id']}');
    print('  driver_id: ${t['driver_id']}');
    print('  end_time: ${t['end_time']} (null = active)');
    print('  ---');
  }

  print('\n=== ALL BUSES ===');
  final buses = await http.get(
    Uri.parse('$baseUrl/rest/v1/buses?select=id,bus_number,driver_id'),
    headers: headers,
  );
  print(buses.body);

  print('\n=== ALL DRIVERS ===');
  final drivers = await http.get(
    Uri.parse('$baseUrl/rest/v1/drivers?select=id,full_name,busId'),
    headers: headers,
  );
  print(drivers.body);
}
