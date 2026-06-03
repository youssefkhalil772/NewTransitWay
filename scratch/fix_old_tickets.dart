import 'dart:convert';
import 'dart:io';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  final headers = {
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  };

  // 1. Fetch all tickets where driver_id is null
  final uri = Uri.parse('$supabaseUrl/tickets?driver_id=is.null');
  final request = await HttpClient().getUrl(uri);
  headers.forEach((k, v) => request.headers.add(k, v));

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  
  if (response.statusCode >= 400) {
    print('Error fetching tickets: $body');
    return;
  }
  
  List<dynamic> tickets = jsonDecode(body);
  print('Found ${tickets.length} tickets with null driver_id');

  // 2. Fetch all drivers to map bus_id -> driver_id
  final driverUri = Uri.parse('$supabaseUrl/drivers?select=id,busId');
  final driverReq = await HttpClient().getUrl(driverUri);
  headers.forEach((k, v) => driverReq.headers.add(k, v));
  final driverRes = await driverReq.close();
  final driverBody = await driverRes.transform(utf8.decoder).join();
  List<dynamic> drivers = jsonDecode(driverBody);
  
  Map<String, String> busToDriver = {};
  for (var d in drivers) {
    if (d['busId'] != null) {
      busToDriver[d['busId']] = d['id'];
    }
  }

  // 3. Update each ticket
  int updated = 0;
  for (var t in tickets) {
    String? busId = t['bus_id'];
    if (busId != null && busToDriver.containsKey(busId)) {
      String driverId = busToDriver[busId]!;
      String ticketId = t['id'];
      
      final updateUri = Uri.parse('$supabaseUrl/tickets?id=eq.$ticketId');
      final updateReq = await HttpClient().patchUrl(updateUri);
      headers.forEach((k, v) => updateReq.headers.add(k, v));
      updateReq.write(jsonEncode({'driver_id': driverId}));
      
      final updateRes = await updateReq.close();
      if (updateRes.statusCode < 400) {
        updated++;
      } else {
        final err = await updateRes.transform(utf8.decoder).join();
        print('Error updating ticket $ticketId: $err');
      }
    }
  }
  
  print('Successfully updated $updated tickets.');
}
