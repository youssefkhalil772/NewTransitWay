import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/networking/api_constants.dart';
import '../../../core/networking/supabase_init.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  RealtimeChannel? _broadcastChannel;
  
  Position? _lastSentPosition;
  Position? _currentPosition;
  DateTime? _lastDbWriteTime;
  
  final List<Map<String, dynamic>> _offlineHistoryQueue = [];
  bool _isSyncingHistory = false;

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
    debugPrint("📡 Starting Trip for busId: $busId (Fast Start)");
    
    // 1. Instantly start the location stream and broadcast
    startLocationStream(busId);
    
    // 2. Asynchronously run backend setup without blocking the UI
    _setupTripOnBackend(busId).catchError((e) {
      debugPrint("🛑 Backend Trip Setup Error: $e");
    });
  }

  Future<void> _setupTripOnBackend(String busId) async {
    final supabase = SupabaseConfig.client;

    final busData = await supabase
        .from(ApiConstants.busesTable)
        .select('route_id')
        .eq('id', busId)
        .maybeSingle();

    if (busData == null || busData['route_id'] == null) {
      throw Exception("Bus not found or no route assigned to this bus");
    }
    final routeId = busData['route_id'];

    try {
      await supabase
          .from('trips')
          .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
          .eq('bus_id', busId)
          .isFilter('ended_at', null); 
    } catch (e) {
      debugPrint("⚠️ Failed to update old trips (ignoring): $e");
    }

    await supabase.from('trips').insert({
      'bus_id': busId,
      'route_id': routeId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });
    debugPrint("✅ New active trip created in database");

    await supabase
        .from(ApiConstants.busesTable)
        .update({'status': 'Active'})
        .eq('id', busId);
    debugPrint("✅ Bus status updated to Active");
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
    _lastDbWriteTime = null;
    
    // Initialize Realtime Broadcast Channel
    _broadcastChannel = SupabaseConfig.client.channel('public-tracking');
    _broadcastChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint("📡 Broadcast Channel Connected");
      }
    });

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

          // 1. INSTANT BROADCAST (60fps realtime via Websocket)
          _broadcastChannel?.sendBroadcastMessage(
            event: 'bus_moved',
            payload: {
              'bus_id': busId,
              'lat': position.latitude,
              'lng': position.longitude,
              'heading': position.heading,
              'speed': position.speed,
            },
          );

          // 2. THROTTLED DB WRITE (Every 10 seconds or 50 meters for persistence)
          final now = DateTime.now();
          final bool timePassed = _lastDbWriteTime == null || now.difference(_lastDbWriteTime!).inSeconds >= 10;
          final bool distancePassed = _lastSentPosition == null || 
              Geolocator.distanceBetween(
                _lastSentPosition!.latitude, 
                _lastSentPosition!.longitude, 
                position.latitude, 
                position.longitude
              ) >= 50;

          if (timePassed || distancePassed) {
            _lastSentPosition = position;
            _lastDbWriteTime = now;
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
    final record = {
      'bus_id': busId,
      'lat': lat,
      'lng': lng,
      'speed': (speed * 3.6).round(),
      // Add timestamp here for offline buffering
      'created_at': DateTime.now().toUtc().toIso8601String(), 
    };

    try {
      await SupabaseConfig.client.from(ApiConstants.trackingTable).insert(record);
      // If success, try to sync any pending offline records
      _syncOfflineHistory();
    } catch (e) {
      debugPrint('⚠️ Network issue, buffering tracking history...');
      _offlineHistoryQueue.add(record);
    }
  }

  Future<void> _syncOfflineHistory() async {
    if (_isSyncingHistory || _offlineHistoryQueue.isEmpty) return;
    _isSyncingHistory = true;

    try {
      // Sync in chunks to avoid payload limits
      final batch = _offlineHistoryQueue.take(50).toList();
      await SupabaseConfig.client.from(ApiConstants.trackingTable).insert(batch);
      
      // Remove synced items
      _offlineHistoryQueue.removeRange(0, batch.length);
      debugPrint('✅ Synced ${batch.length} buffered tracking points.');
      
      // If still items left, recursively sync
      if (_offlineHistoryQueue.isNotEmpty) {
        _isSyncingHistory = false;
        _syncOfflineHistory();
      }
    } catch (e) {
      debugPrint('⚠️ Offline sync failed, will retry later.');
    } finally {
      _isSyncingHistory = false;
    }
  }

  void stopTracking() {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
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
