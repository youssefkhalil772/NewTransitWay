import 'dart:async';
import 'package:supabase/supabase.dart';

void main() async {
  const String supabaseUrl = 'https://vrgcsoeepbwnedzjwiqb.supabase.co';
  const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE';

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  print('Listening to drivers table...');
  
  final subscription = client
      .from('drivers')
      .stream(primaryKey: ['id'])
      .listen((data) {
        print('Realtime event received! Data count: \${data.length}');
      });

  // Wait 2 seconds, then trigger an update
  await Future.delayed(Duration(seconds: 2));
  print('Triggering an update to test Realtime...');
  
  // Just update the first driver we find with the same busId to trigger an event without changing data
  final drivers = await client.from('drivers').select('id, busId').limit(1);
  if (drivers.isNotEmpty) {
    final driverId = drivers[0]['id'];
    final busId = drivers[0]['busId'];
    await client.from('drivers').update({'busId': busId}).eq('id', driverId);
    print('Update triggered. Waiting for realtime event...');
  }
  
  await Future.delayed(Duration(seconds: 5));
  subscription.cancel();
  print('Done.');
}
