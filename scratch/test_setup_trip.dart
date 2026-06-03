import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  final busId = '11111111-1111-1111-1111-111111111111';

  print('1. Querying bus info...');
  final busData = await supabase
      .from('buses')
      .select('route_id, route_name')
      .eq('id', busId)
      .maybeSingle();

  print('Bus data: $busData');
  if (busData == null || (busData['route_id'] == null && busData['route_name'] == null)) {
    print('Bus not found or no route assigned');
    return;
  }

  final lineNum = int.tryParse(busData['route_name']?.toString() ?? '') ?? busData['route_id'];
  print('Line number: $lineNum');

  print('2. Resolving route UUID...');
  final routeData = await supabase
      .from('routes')
      .select('id')
      .eq('line_number', lineNum)
      .maybeSingle();

  print('Route data: $routeData');
  if (routeData == null) {
    print('Route not found');
    return;
  }

  final routeUuid = routeData['id'];
  print('Resolved UUID: $routeUuid');

  print('3. Inserting active trip...');
  try {
    // End existing active trips first
    await supabase
        .from('trips')
        .update({'end_time': DateTime.now().toUtc().toIso8601String()})
        .eq('bus_id', busId)
        .isFilter('end_time', null);

    final inserted = await supabase.from('trips').insert({
      'bus_id': busId,
      'route_id': routeUuid,
      'start_time': DateTime.now().toUtc().toIso8601String(),
    }).select();
    print('Successfully inserted active trip: $inserted');
  } catch (e) {
    print('Failed to insert active trip: $e');
  }
}
