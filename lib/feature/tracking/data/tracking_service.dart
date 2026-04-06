import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class TrackingService {
  final String apiUrl = "http://transit-way.runasp.net/api/track/update";

  final http.Client _client = http.Client();

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

  Future<void> sendToApi(int busId, double lat, double lng, double speed) async {
    try {
      final response = await _client.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "busId": busId,
          "lat": lat,
          "lng": lng,
          "speed": speed.round(),
        }),
      ).timeout(const Duration(seconds: 4));

      print("Response Status: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("Server Error Detail: ${response.body}");
      }

    } catch (e) {
      print("Network/Server Error: $e");
    }
  }

  void dispose() {
    _client.close();
  }
}