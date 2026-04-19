import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/networking/api_constants.dart';
import '../../../core/networking/api_service.dart';
import 'models/station_model.dart';
import 'models/route_model.dart';

class RouteData {
  final List<LatLng> points;
  final double distanceInMeters;
  final double durationInSeconds;

  RouteData({required this.points, this.distanceInMeters = 0, this.durationInSeconds = 0});
}

class HomeRepository {
  final ApiService _apiService = ApiService();

  Future<List<StationModel>> getStations() async {
    try {
      final response = await _apiService.get(ApiConstants.stations);
      return (response as List).map((json) => StationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("🛑 Error fetching stations: $e");
      rethrow;
    }
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await _apiService.get(ApiConstants.routes);
      return (response as List).map((json) => RouteModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("🛑 Error fetching routes: $e");
      rethrow;
    }
  }

  /// رسم المسار: يمر بكل المحطات مع منع الدخول في الشوارع الجانبية الضيقة
  Future<RouteData> getRouteBetweenStations(List<LatLng> waypoints, {bool isLiveTracking = false}) async {
    if (waypoints.length < 2) return RouteData(points: waypoints);

    final String coords = waypoints.map((p) => "${p.longitude},${p.latitude}").join(';');
    
    // overview=full لدقة الخط، continue_straight لمنع اللفات غير المنطقية
    String url = "${ApiConstants.osrmBaseUrl}$coords?geometries=geojson&overview=full&continue_straight=true";

    // استخدام Radius كبير جداً (1000م) للمحطات لضمان بقاء المسار على الطريق الرئيسي
    // بينما نترك الباص (النقطة الأولى) بـ Radius أصغر (100م) لضمان دقة مكانه
    List<String> radiusList = [];
    for (int i = 0; i < waypoints.length; i++) {
      radiusList.add(i == 0 ? "100" : "1000");
    }
    url += "&radiuses=${radiusList.join(";")}";

    try {
      final response = await _apiService.get("", fullUrl: url);
      if (response != null && response['routes'] != null && response['routes'].isNotEmpty) {
        final route = response['routes'][0];
        final List<dynamic> coordinates = route['geometry']['coordinates'];
        final List<LatLng> points = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        
        return RouteData(
          points: points,
          distanceInMeters: (route['distance'] as num).toDouble(),
          durationInSeconds: (route['duration'] as num).toDouble(),
        );
      }
      return RouteData(points: waypoints);
    } catch (e) {
      debugPrint("⚠️ Routing API Error: $e");
      return RouteData(points: waypoints);
    }
  }

  Future<dynamic> searchTrip(int startStationId, int endStationId) async {
    return await _apiService.post(ApiConstants.userTripSearch, body: {
      "startStationId": startStationId,
      "endStationId": endStationId,
    });
  }

  Future<List<dynamic>> getBuses() async {
    return await _apiService.get(ApiConstants.adminBuses);
  }
}
