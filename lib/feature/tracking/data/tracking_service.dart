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
    startLocationStream(busId);
    _setupTripOnBackend(busId).catchError((e) {});
  }

  Future<void> _setupTripOnBackend(String busId) async {
    final supabase = SupabaseConfig.client;

    final busData = await supabase
        .from(ApiConstants.busesTable)
        .select('route_id, route_name')
        .eq('id', busId)
        .maybeSingle();

    if (busData == null || (busData['route_id'] == null && busData['route_name'] == null)) {
      throw Exception("Bus not found or no route assigned to this bus");
    }
    
    final routeId = int.tryParse(busData['route_name']?.toString() ?? '') ?? busData['route_id'];

    try {
      await supabase
          .from('trips')
          .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
          .eq('bus_id', busId)
          .isFilter('ended_at', null); 
    } catch (e) {}

    await supabase.from('trips').insert({
      'bus_id': busId,
      'route_id': routeId,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    });

    await supabase
        .from(ApiConstants.busesTable)
        .update({'status': 'Active'})
        .eq('id', busId);
  }

  Future<void> endTrip(String busId) async {
    try {
      final supabase = SupabaseConfig.client;

      try {
        await supabase
            .from('trips')
            .update({'ended_at': DateTime.now().toUtc().toIso8601String()})
            .eq('bus_id', busId)
            .isFilter('ended_at', null);

        await supabase
            .from('tickets')
            .update({'status': 'expired'})
            .eq('bus_id', busId)
            .eq('status', 'active');

        await supabase
            .from('route_qrs')
            .update({'is_active': false})
            .eq('bus_id', busId)
            .eq('is_active', true);
      } catch (e) {}

      await supabase
          .from(ApiConstants.busesTable)
          .update({'status': 'Inactive'})
          .eq('id', busId);

      stopTracking();
    } catch (e) {
      rethrow;
    }
  }

  void startLocationStream(String busId) {
    stopTracking();
    _lastSentPosition = null;
    _currentPosition = null;
    _lastDbWriteTime = null;
    
    _broadcastChannel = SupabaseConfig.client.channel('public-tracking');
    _broadcastChannel!.subscribe((status, [error]) {});

    late LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
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
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (position.accuracy > 35.0) return;

        if (_currentPosition?.latitude != position.latitude || 
            _currentPosition?.longitude != position.longitude) {
          
          _currentPosition = position;
          _locationController.add(position);

          double realSpeed = position.speed;
          if (realSpeed < 1.0) realSpeed = 0.0;

          _broadcastChannel?.sendBroadcastMessage(
            event: 'bus_moved',
            payload: {
              'bus_id': busId,
              'lat': position.latitude,
              'lng': position.longitude,
              'heading': position.heading,
              'speed': realSpeed,
            },
          );

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
            sendToApi(busId, position.latitude, position.longitude, realSpeed);
          }
        }

      },
      onError: (e) {},
    );
  }

  Future<void> sendToApi(String busId, double lat, double lng, double speed) async {
    await Future.wait([
      _updateBusPosition(busId, lat, lng, speed),
      _updateTrackingHistory(busId, lat, lng, speed),
    ]);
  }

  Future<void> _updateBusPosition(String busId, double lat, double lng, double speed) async {
    try {
      await SupabaseConfig.client.from(ApiConstants.busesTable).update({
        'current_lat': lat,
        'current_lng': lng,
        'status': 'Active',
      }).eq('id', busId);
    } catch (e) {}
  }

  Future<void> _updateTrackingHistory(String busId, double lat, double lng, double speed) async {
    final record = {
      'bus_id': busId,
      'lat': lat,
      'lng': lng,
      'speed': (speed * 3.6).round(),
      'created_at': DateTime.now().toUtc().toIso8601String(), 
    };

    try {
      await SupabaseConfig.client.from(ApiConstants.trackingTable).insert(record);
      _syncOfflineHistory();
    } catch (e) {
      _offlineHistoryQueue.add(record);
    }
  }

  Future<void> _syncOfflineHistory() async {
    if (_isSyncingHistory || _offlineHistoryQueue.isEmpty) return;
    _isSyncingHistory = true;

    try {
      final batch = _offlineHistoryQueue.take(50).toList();
      await SupabaseConfig.client.from(ApiConstants.trackingTable).insert(batch);
      _offlineHistoryQueue.removeRange(0, batch.length);
      
      if (_offlineHistoryQueue.isNotEmpty) {
        _isSyncingHistory = false;
        _syncOfflineHistory();
      }
    } catch (e) {
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
    }
  }

  void dispose() {
    stopTracking();
    if (!_locationController.isClosed) {
      _locationController.close();
    }
  }
}
