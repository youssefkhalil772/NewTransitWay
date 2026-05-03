import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
      final response = await _apiService.getAll(ApiConstants.stationsTable);
      debugPrint("البيانات اللي رجعت من سوبابيز: $response");
      return response.map((json) => StationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("🛑 Error fetching stations: $e");
      rethrow;
    }
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await _apiService.getAll(ApiConstants.routesTable);
      return response.map((json) => RouteModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint("🛑 Error fetching routes: $e");
      rethrow;
    }
  }

  /// رسم المسار: تم تحسينه لمنع الدوائر (Looping) حول المحطات
  Future<RouteData> getRouteBetweenStations(List<LatLng> waypoints, {double? heading}) async {
    if (waypoints.length < 2) return RouteData(points: waypoints);

    final String coords = waypoints.map((p) => "${p.longitude},${p.latitude}").join(';');
    
    // استخدام geometries=polyline لتقليل حجم البيانات وسرعة الرسم
    String url = "${ApiConstants.osrmBaseUrl}$coords?geometries=geojson&overview=full&continue_straight=true";

    List<String> radiusList = [];
    List<String> bearingList = [];
    
    for (int i = 0; i < waypoints.length; i++) {
      // زيادة الـ Radius للباص والمحطات لمنع الـ Looping (الدوران)
      radiusList.add(i == 0 ? "100" : "500"); 
      
      if (i == 0 && heading != null && heading > 0) {
        bearingList.add("${heading.round()},45"); // زيادة زاوية السماح لـ 45 درجة
      } else {
        bearingList.add(""); 
      }
    }
    
    url += "&radiuses=${radiusList.join(";")}";
    if (heading != null) url += "&bearings=${bearingList.join(";")}";

    try {
      // OSRM is a third-party service, keep using HTTP
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List<dynamic> coordinates = route['geometry']['coordinates'];
          final List<LatLng> points = coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
          
          return RouteData(
            points: points,
            distanceInMeters: (route['distance'] as num).toDouble(),
            durationInSeconds: (route['duration'] as num).toDouble(),
          );
        }
      }
      return RouteData(points: waypoints);
    } catch (e) {
      debugPrint("⚠️ Routing API Error: $e");
      return RouteData(points: waypoints);
    }
  }

  Future<dynamic> getNearestBus(String startStationId) async {
    return await _apiService.rpc('get_nearest_bus', params: {
      "start_station_id": int.tryParse(startStationId) ?? startStationId,
    });
  }

  Future<List<dynamic>> getBuses() async {
    return await _apiService.getAll(ApiConstants.busesTable);
  }
}
