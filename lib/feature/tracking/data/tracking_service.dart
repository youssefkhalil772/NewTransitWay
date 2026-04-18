import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/networking/api_constants.dart';

class TrackingService {
  final http.Client _client = http.Client();
  StreamSubscription<Position>? _positionStreamSubscription;

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  // دالة لبدء التتبع التلقائي (الخفيف)
  void startLocationStream(int busId) {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // يبعت داتا بس لو الباص اتحرك 5 متر، وده بيوفر نت وبطارية جداً
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        sendToApi(busId, position.latitude, position.longitude, position.speed);
      },
    );
  }

  Future<void> sendToApi(int busId, double lat, double lng, double speed) async {
    try {
      final response = await _client.post(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.trackUpdate}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "busId": busId,
          "lat": lat,
          "lng": lng,
          "speed": speed.round(),
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        print("📍 Location Sent: $lat, $lng");
      }
    } catch (e) {
      print("🛑 Tracking API Error: $e");
    }
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
  }

  void dispose() {
    stopTracking();
    _client.close();
  }
}
