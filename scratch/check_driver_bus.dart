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

  // Check all drivers and their bus assignments
  print('=== DRIVERS ===');
  final driversRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/drivers?select=id,full_name,busId'),
    headers: headers,
  );
  final drivers = jsonDecode(driversRes.body) as List;
  for (final d in drivers) {
    print('  Driver: ${d['full_name']} | id: ${d['id']} | busId: ${d['busId']}');
  }

  // Check all buses
  print('\n=== BUSES ===');
  final busesRes = await http.get(
    Uri.parse('$baseUrl/rest/v1/buses?select=id,bus_number,driver_id'),
    headers: headers,
  );
  final buses = jsonDecode(busesRes.body) as List;
  for (final b in buses) {
    print('  Bus: ${b['bus_number']} | id: ${b['id']} | driver_id: ${b['driver_id']}');
  }

  // Test generate-qr with the real driver ID
  print('\n=== TEST generate-qr ===');
  for (final d in drivers) {
    if (d['busId'] != null) {
      final r = await http.post(
        Uri.parse('$baseUrl/functions/v1/generate-qr'),
        headers: headers,
        body: jsonEncode({'driverId': d['id']}),
      );
      print('Driver ${d['full_name']}: ${r.statusCode} → ${r.body}');
    } else {
      print('Driver ${d['full_name']}: NO BUS ASSIGNED (busId is null)');
    }
  }
}
