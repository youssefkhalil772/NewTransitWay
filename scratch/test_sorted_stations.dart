import 'dart:convert';
import 'dart:io';
import '../lib/feature/home/data/models/station_model.dart';

void main() async {
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';
  // Query with ordering
  const url = 'https://vrgcsoeepbwnedzjwiqb.supabase.co/rest/v1/stations?order=zone.asc,order_index.asc';
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('apikey', anonKey);
    request.headers.set('Authorization', 'Bearer $anonKey');
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('STATUS: ${response.statusCode}');
    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody) as List;
      print('TOTAL STATIONS FETCHED: ${json.length}');
      
      final stations = json.map((s) => StationModel.fromJson(s)).toList();
      
      // Sort them in Dart exactly like in UserDataManager/DriverDataManager
      stations.sort((a, b) {
        int zoneCompare = a.zone.compareTo(b.zone);
        if (zoneCompare != 0) return zoneCompare;
        return a.orderIndex.compareTo(b.orderIndex);
      });
      
      print('--- FIRST 25 STATIONS ---');
      for (int i = 0; i < stations.length && i < 25; i++) {
        final s = stations[i];
        print('Station ${i+1}: Name="${s.name}", Zone="${s.zone}", OrderIndex=${s.orderIndex}');
      }
      
      // Assert/check sorting
      bool correct = true;
      for (int i = 0; i < stations.length - 1; i++) {
        final a = stations[i];
        final b = stations[i + 1];
        final zoneCompare = a.zone.compareTo(b.zone);
        if (zoneCompare == 0) {
          if (a.orderIndex > b.orderIndex) {
            print('❌ ERROR: ${a.name} (orderIndex: ${a.orderIndex}) comes before ${b.name} (orderIndex: ${b.orderIndex}) in zone ${a.zone}');
            correct = false;
          }
        } else if (zoneCompare > 0) {
          print('❌ ERROR: Zone sorting failed: ${a.zone} vs ${b.zone}');
          correct = false;
        }
      }
      
      if (correct) {
        print('✅ SUCCESS: All stations are correctly grouped by zone and sorted by order_index!');
      }
    } else {
      print('Failed: $responseBody');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
