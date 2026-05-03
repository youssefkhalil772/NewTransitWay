import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/networking/api_constants.dart';
import '../../../core/networking/supabase_init.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  
  Position? _lastSentPosition;
  Position? _currentPosition;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;
    
    return true;
  }

  Future<void> startTrip(String busId) async {
    try {
      debugPrint("📡 Starting Trip for busId: $busId");
      final supabase = SupabaseConfig.client;

      // 1. Fetch the bus to get the route_id
      final busData = await supabase
          .from(ApiConstants.busesTable)
          .select('route_id')
          .eq('id', busId)
          .maybeSingle();

      if (busData == null || busData['route_id'] == null) {
        throw Exception("Bus not found or no route assigned to this bus");
      }
      final routeId = busData['route_id'];

      // 2. Mark any existing trips for this bus as completed to avoid conflicts
      try {
        await supabase
            .from('trips')
            .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
            .eq('bus_id', busId)
            .isFilter('ended_at', null); // Active trips have ended_at as null
      } catch (e) {
        debugPrint("⚠️ Failed to update old trips (ignoring): $e");
      }

      // 3. Create a new active trip
      await supabase.from('trips').insert({
        'bus_id': busId,
        'route_id': routeId,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        // ended_at is left null by default to mark it as active
      });
      debugPrint("✅ New active trip created in database");

      // 4. Update status in buses table
      await supabase
          .from(ApiConstants.busesTable)
          .update({'status': 'Active'})
          .eq('id', busId);
      debugPrint("✅ Bus status updated to Active");

      // 5. Start the location stream
      startLocationStream(busId);
    } catch (e) {
      debugPrint("🛑 Start Trip Error: $e");
      rethrow;
    }
  }

  Future<void> endTrip(String busId) async {
    try {
      debugPrint("📡 Ending Trip for busId: $busId");
      final supabase = SupabaseConfig.client;

      // 1. Mark the trip as completed
      try {
        await supabase
            .from('trips')
            .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
            .eq('bus_id', busId)
            .isFilter('ended_at', null);
        debugPrint("✅ Trip marked as completed");

        // 1.5 Expire all active tickets for this bus
        await supabase
            .from('tickets')
            .update({'status': 'expired'})
            .eq('bus_id', busId)
            .eq('status', 'active');
        debugPrint("✅ Tickets for this trip marked as expired");

        // 1.6 Deactivate QR codes for this bus
        await supabase
            .from('route_qrs')
            .update({'is_active': false})
            .eq('bus_id', busId)
            .eq('is_active', true);
        debugPrint("✅ QR codes for this trip deactivated");
      } catch (e) {
        debugPrint("⚠️ Failed to update trip/tickets status: $e");
      }

      // 2. Update status in buses table
      await supabase
          .from(ApiConstants.busesTable)
          .update({'status': 'Inactive'})
          .eq('id', busId);
      debugPrint("✅ Bus status updated to Inactive");

      // 3. Stop tracking
      stopTracking();
    } catch (e) {
      debugPrint("🛑 End Trip Error: $e");
      rethrow;
    }
  }

  void startLocationStream(String busId) {
    stopTracking();
    _lastSentPosition = null;
    _currentPosition = null;
    late LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Fastest possible updates
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Tracking your trip in progress",
          notificationTitle: "TransitWay Live",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0, // Fastest possible updates
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (_currentPosition?.latitude != position.latitude || 
            _currentPosition?.longitude != position.longitude) {
          
          _currentPosition = position;
          _locationController.add(position);

          if (_lastSentPosition == null || 
              Geolocator.distanceBetween(
                _lastSentPosition!.latitude, 
                _lastSentPosition!.longitude, 
                position.latitude, 
                position.longitude
              ) >= 1) { // Update every 1 meter for smooth tracking
            
            _lastSentPosition = position;
            sendToApi(busId, position.latitude, position.longitude, position.speed);
          }
        }
      },
      onError: (e) => debugPrint("🛑 Geolocator Stream Error: $e"),
    );
  }

  Future<void> sendToApi(String busId, double lat, double lng, double speed) async {
    // Run both writes concurrently for efficiency
    await Future.wait([
      _updateBusPosition(busId, lat, lng, speed),
      _updateTrackingHistory(busId, lat, lng, speed),
    ]);
  }

  /// Updates current_lat / current_lng directly on the buses row.
  /// This is what the passenger TrackingView polls every 2 seconds.
  Future<void> _updateBusPosition(String busId, double lat, double lng, double speed) async {
    try {
      final response = await SupabaseConfig.client.from(ApiConstants.busesTable).update({
        'current_lat': lat,
        'current_lng': lng,
        'status': 'Active', // Re-confirming active status with each update
      }).eq('id', busId).select();

      if (response.isNotEmpty) {
        debugPrint('📍 Bus Position Updated: id=$busId, coords=($lat, $lng)');
      } else {
        debugPrint('⚠️ Bus Position Update FAILED: id=$busId not found or permission denied');
      }
    } catch (e) {
      debugPrint('🛑 Bus position update error: $e');
    }
  }

  /// Upserts to the tracking table for historical / analytics records.
  Future<void> _updateTrackingHistory(String busId, double lat, double lng, double speed) async {
    try {
      await SupabaseConfig.client.from(ApiConstants.trackingTable).insert({
        'bus_id': busId,
        'lat': lat,
        'lng': lng,
        'speed': (speed * 3.6).round(),
      });
    } catch (e) {
      // Tracking table may not exist — log only, don't break the stream
      debugPrint('⚠️ Tracking history write skipped: $e');
    }
  }

  void stopTracking() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      debugPrint("🛑 Tracking Stopped.");
    }
  }

  void dispose() {
    stopTracking();
    if (!_locationController.isClosed) {
      _locationController.close();
    }
    debugPrint("🛑 TrackingService disposed.");
  }
}
