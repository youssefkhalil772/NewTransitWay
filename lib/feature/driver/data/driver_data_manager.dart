import 'package:flutter/foundation.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';

class DriverDataManager {
  static final DriverDataManager _instance = DriverDataManager._internal();
  factory DriverDataManager() => _instance;
  DriverDataManager._internal();

  List<RouteModel>? _routes;
  Map<String, String>? _routeNamesByUuid;
  List<StationModel>? _stations;
  final Map<String, Map<String, dynamic>> _buses = {};

  Future<void> prefetchData({bool forceRefresh = false}) async {
    if (_routes != null && !forceRefresh) return;
    try {
      final routesRes = await SupabaseConfig.client.from('routes').select('*');
      _routeNamesByUuid = {};
      _routes = routesRes.map<RouteModel>((json) {
        final name = json['name']?.toString() ?? json['start_point']?.toString() ?? json['line_number'].toString();
        if (json['id'] != null) {
          _routeNamesByUuid![json['id'].toString()] = name;
        }
        return RouteModel.fromJson({
          'id': int.tryParse(json['line_number']?.toString() ?? '') ?? 0,
          'name': name,
          'zone': json['end_point']?.toString() ?? 'Unknown',
          'price': double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
        });
      }).toList();

      final stationsRes = await SupabaseConfig.client
          .from('stations')
          .select('*')
          .order('zone', ascending: true)
          .order('order_index', ascending: true);
      _stations = stationsRes.map<StationModel>((json) => StationModel.fromJson(json)).toList();
      _stations!.sort((a, b) {
        int zoneCompare = a.zone.compareTo(b.zone);
        if (zoneCompare != 0) return zoneCompare;
        return a.orderIndex.compareTo(b.orderIndex);
      });
    } catch (e) {
    }
  }

  Future<List<RouteModel>> getRoutes({bool forceRefresh = false}) async {
    if (_routes == null || forceRefresh) await prefetchData(forceRefresh: forceRefresh);
    return _routes ?? [];
  }

  Future<List<StationModel>> getStations({bool forceRefresh = false}) async {
    if (_stations == null || forceRefresh) await prefetchData(forceRefresh: forceRefresh);
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

  Future<String?> getRouteNameByUuid(String uuid) async {
    if (_routeNamesByUuid == null) await prefetchData(forceRefresh: true);
    return _routeNamesByUuid?[uuid];
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
    _routeNamesByUuid = null;
    _stations = null;
    _buses.clear();
  }
}
