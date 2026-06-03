import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://vrgcsoeepbwnedzjwiqb.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyZ2Nzb2VlcGJ3bmVkemp3aXFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0MjAwNjcsImV4cCI6MjA5NTk5NjA2N30.Y8xNowU9NoE9y8IXH-9wL0S7paHcVR4kqYKif0BqiDE'
  );

  final driverId = '26c42a56-66d0-4138-b56f-a673adfc5fb0';

  print('Step 1: Get the bus assigned to this driver');
  final driverData = await supabase
      .from('drivers')
      .select('busId')
      .eq('id', driverId)
      .maybeSingle();

  print('Driver data: $driverData');
  if (driverData == null || driverData['busId'] == null) {
    print('No bus assigned to driver');
    return;
  }
  final busId = driverData['busId'];

  print('Step 2: Get active trip');
  final trip = await supabase
      .from('trips')
      .select('route_id')
      .eq('bus_id', busId)
      .isFilter('end_time', null)
      .maybeSingle();

  print('Trip data: $trip');
  if (trip == null) {
    print('No active trip for this bus');
    return;
  }

  print('Step 3: Get bus info');
  final busData = await supabase
      .from('buses')
      .select('id, bus_number, status')
      .eq('id', busId)
      .maybeSingle();

  print('Bus data: $busData');

  print('Step 4: Get route info');
  final routeData = await supabase
      .from('routes')
      .select('name, start_point, end_point, price')
      .eq('id', trip['route_id'])
      .maybeSingle();

  print('Route data: $routeData');
}
