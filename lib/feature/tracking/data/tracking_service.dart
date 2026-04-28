import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/networking/api_constants.dart';

class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  factory TrackingService() => _instance;
  TrackingService._internal();

  final http.Client _client = http.Client();
  StreamSubscription<Position>? _positionStreamSubscription;
  
  Position? _lastSentPosition;
  Position? _currentPosition;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // بنجرب نجيب التوكن بكل المسميات المحتملة
    final String? token = prefs.getString('token') ?? 
                         prefs.getString('userToken') ?? 
                         prefs.getString('driverToken');
                         
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

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

  Future<void> startTrip(int busId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.startTrip(busId)}");
      
      debugPrint("📡 Sending Start Trip to: $url");
      debugPrint("🔑 Headers: $headers");

      // بنبعت الـ busId في الـ body كمان احتياطي لو الـ API محتاجه
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({"busId": busId}),
      );

      debugPrint("📡 Start Trip Response Code: ${response.statusCode}");
      debugPrint("📡 Start Trip Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        startLocationStream(busId);
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("🛑 Start Trip Error: $e");
      rethrow;
    }
  }

  Future<void> endTrip(int busId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse("${ApiConstants.baseUrl}${ApiConstants.endTrip(busId)}");

      debugPrint("📡 Sending End Trip to: $url");

      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({"busId": busId}),
      );

      debugPrint("📡 End Trip Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        stopTracking();
      } else {
        throw Exception("Server Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      debugPrint("🛑 End Trip Error: $e");
      rethrow;
    }
  }

  void startLocationStream(int busId) {
    stopTracking();
    _lastSentPosition = null;
    _currentPosition = null;

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
              ) >= 20) {
            
            _lastSentPosition = position;
            sendToApi(busId, position.latitude, position.longitude, position.speed);
          }
        }
      },
      onError: (e) => debugPrint("🛑 Geolocator Stream Error: $e"),
    );
  }

  Future<void> sendToApi(int busId, double lat, double lng, double speed) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.trackUpdate}"),
        headers: headers,
        body: jsonEncode({
          "busId": busId,
          "lat": lat,
          "lng": lng,
          "speed": (speed * 3.6).round(),
        }),
      ).timeout(const Duration(seconds: 4));
      
      if (response.statusCode != 200) {
        debugPrint("⚠️ Tracking Update Warning: Status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("🛑 Tracking Update API Error: $e");
    }
  }

  void stopTracking() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      debugPrint("🛑 Tracking Stopped.");
    }
  }
}
