import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../core/networking/api_constants.dart';
import '../../../core/networking/api_service.dart';
import '../../../core/networking/supabase_init.dart';

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
      return response.map((json) => StationModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await SupabaseConfig.client.from('lines').select('*, zones(name)');
      return (response as List).map((json) {
        return RouteModel.fromJson({
          'id': int.tryParse(json['line_number']?.toString() ?? '') ?? 0,
          'name': json['start_point']?.toString() ?? json['line_number'].toString(),
          'zone': json['zones'] != null ? json['zones']['name'] : 'Unknown',
          'price': double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        });
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<RouteData> getRouteBetweenStations(List<LatLng> waypoints, {double? heading}) async {
    if (waypoints.length < 2) return RouteData(points: waypoints);

    final List<LatLng> effectiveWaypoints = waypoints.length > 20
        ? [waypoints.first, waypoints.last]
        : waypoints;

    final String coords = effectiveWaypoints
        .map((p) => "${p.longitude},${p.latitude}")
        .join(';');

    final String url =
        "${ApiConstants.osrmBaseUrl}$coords?geometries=geojson&overview=full&steps=false";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final code = data['code'];

        if (code != 'Ok') {
          return RouteData(points: waypoints);
        }

        final routesList = data['routes'] as List<dynamic>?;
        if (routesList == null || routesList.isEmpty) {
          return RouteData(points: waypoints);
        }

        final route = routesList[0] as Map<String, dynamic>;
        final geometry = route['geometry'];

        List<LatLng> points = [];
        if (geometry is Map<String, dynamic>) {
          final coords = geometry['coordinates'] as List<dynamic>;
          points = coords
              .map((c) => LatLng(
                    (c[1] as num).toDouble(),
                    (c[0] as num).toDouble(),
                  ))
              .toList();
        }

        if (points.isNotEmpty) {
          return RouteData(
            points: points,
            distanceInMeters: (route['distance'] as num).toDouble(),
            durationInSeconds: (route['duration'] as num).toDouble(),
          );
        }
      }

      return RouteData(points: waypoints);
    } catch (e) {
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
