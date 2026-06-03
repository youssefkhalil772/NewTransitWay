import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  final busId = '11111111-1111-1111-1111-111111111111';

  print('Trying to insert trip with integer route_id (1001)...');
  try {
    await client.from('trips').insert({
      'bus_id': busId,
      'route_id': 1001,
      'start_time': DateTime.now().toUtc().toIso8601String(),
    });
    print('Success with integer route_id!');
  } catch (e) {
    print('Failed with integer route_id: $e');
  }

  print('\nTrying to insert trip with UUID route_id...');
  try {
    await client.from('trips').insert({
      'bus_id': busId,
      'route_id': 'abc6a637-37af-41c4-b2ab-afe3de46c30b',
      'start_time': DateTime.now().toUtc().toIso8601String(),
    });
    print('Success with UUID route_id!');
  } catch (e) {
    print('Failed with UUID route_id: $e');
  }
}
