import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Project credentials
  const projectRef = 'vrgcsoeepbwnedzjwiqb';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  final baseUrl = 'https://$projectRef.supabase.co';

  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };

  // 1. Check all edge functions (trying to call each with empty body)
  print('=== CHECKING EDGE FUNCTIONS ===');
  final functions = ['scan-pay', 'generate-qr', 'add-manual-tickets', 'report-complaint', 'paymob-pay'];
  for (final fn in functions) {
    final r = await http.post(
      Uri.parse('$baseUrl/functions/v1/$fn'),
      headers: headers,
      body: '{}',
    );
    print('$fn → ${r.statusCode}: ${r.body.length > 100 ? r.body.substring(0, 100) : r.body}');
  }

  // 2. Check route_qrs table
  print('\n=== ROUTE_QRS TABLE ===');
  final qrs = await http.get(
    Uri.parse('$baseUrl/rest/v1/route_qrs?select=*'),
    headers: headers,
  );
  final qrData = jsonDecode(qrs.body) as List;
  print('Total QRs: ${qrData.length}');
  if (qrData.isNotEmpty) {
    print('First QR: ${jsonEncode(qrData.first)}');
  }

  // 3. Check trips table - any active ones?
  print('\n=== ACTIVE TRIPS ===');
  final trips = await http.get(
    Uri.parse('$baseUrl/rest/v1/trips?end_time=is.null&select=*'),
    headers: headers,
  );
  final tripsData = jsonDecode(trips.body) as List;
  print('Active trips: ${tripsData.length}');
  if (tripsData.isNotEmpty) {
    print('First trip: ${jsonEncode(tripsData.first)}');
  }

  // 4. Check tickets table structure (with all columns)
  print('\n=== TICKETS TABLE (recent) ===');
  final tickets = await http.get(
    Uri.parse('$baseUrl/rest/v1/tickets?select=*&order=created_at.desc&limit=3'),
    headers: headers,
  );
  final ticketsData = jsonDecode(tickets.body);
  print('Tickets: ${jsonEncode(ticketsData)}');

  // 5. Check users table (just check columns)
  print('\n=== USERS TABLE SAMPLE ===');
  final users = await http.get(
    Uri.parse('$baseUrl/rest/v1/users?select=*&limit=1'),
    headers: headers,
  );
  final usersData = jsonDecode(users.body);
  if (usersData is List && usersData.isNotEmpty) {
    print('User columns: ${(usersData.first as Map).keys.toList()}');
    print('User data: ${jsonEncode(usersData.first)}');
  } else {
    print('Users: ${jsonEncode(usersData)}');
  }
}
