import 'package:flutter/foundation.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';

class DriverDataManager {
  static final DriverDataManager _instance = DriverDataManager._internal();
  factory DriverDataManager() => _instance;
  DriverDataManager._internal();

  List<RouteModel>? _routes;
  List<StationModel>? _stations;
  final Map<String, Map<String, dynamic>> _buses = {};

  Future<void> prefetchData() async {
    try {
      final routesRes = await SupabaseConfig.client.from('lines').select('*, zones(name)');
      _routes = routesRes.map<RouteModel>((json) {
        return RouteModel.fromJson({
          'id': int.tryParse(json['line_number']?.toString() ?? '') ?? 0,
          'name': json['start_point']?.toString() ?? json['line_number'].toString(),
          'zone': json['zones'] != null ? json['zones']['name'] : 'Unknown',
          'price': double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        });
      }).toList();

      final stationsRes = await SupabaseConfig.client.from('stations').select('*');
      _stations = stationsRes.map<StationModel>((json) => StationModel.fromJson(json)).toList();
    } catch (e) {
    }
  }

  Future<List<RouteModel>> getRoutes() async {
    if (_routes == null) await prefetchData();
    return _routes ?? [];
  }

  Future<List<StationModel>> getStations() async {
    if (_stations == null) await prefetchData();
    return _stations ?? [];
  }

  RouteModel? getRouteById(int id) {
    if (_routes == null) return null;
    try {
      return _routes!.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBusById(String busId) async {
    if (_buses.containsKey(busId)) return _buses[busId];
    try {
      final res = await SupabaseConfig.client.from('buses').select('*').eq('id', busId).maybeSingle();
      if (res != null) {
        _buses[busId] = res;
        return res;
      }
    } catch (e) {
    }
    return null;
  }
  
  void clearCache() {
    _routes = null;
    _stations = null;
    _buses.clear();
  }
}
