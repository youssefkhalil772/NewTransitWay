import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';

class UserDataManager {
  static final UserDataManager _instance = UserDataManager._internal();
  factory UserDataManager() => _instance;
  UserDataManager._internal();

  final _supabase = SupabaseConfig.client;

  List<StationModel>? _cachedStations;
  List<RouteModel>? _cachedRoutes;
  Map<String, String>? _routeNamesByUuid;
  Map<String, String>? _busNumberById;

  StreamSubscription<List<Map<String, dynamic>>>? _stationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _routesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _busesSub;

  final _stationsController = StreamController<List<StationModel>>.broadcast();
  final _routesController = StreamController<List<RouteModel>>.broadcast();

  Stream<List<StationModel>> get stationsStream => _stationsController.stream;

  Stream<List<RouteModel>> get routesStream => _routesController.stream;

  void startRealtime() {
    _startStationsStream();
    _startRoutesStream();
    _startBusesStream();
  }

  void _startStationsStream() {
    _stationsSub?.cancel();
    _stationsSub = _supabase.from('stations').stream(primaryKey: ['id']).listen(
      (data) {
        try {
          final parsed = (data).map((s) => StationModel.fromJson(s)).toList();
          parsed.sort((a, b) {
            int zoneCompare = a.zone.compareTo(b.zone);
            if (zoneCompare != 0) return zoneCompare;
            return a.orderIndex.compareTo(b.orderIndex);
          });
          _cachedStations = parsed;
          if (!_stationsController.isClosed) {
            _stationsController.add(parsed);
          }
        } catch (e) {
          debugPrint('ðŸ›‘ UserDataManager stations stream parse error: $e');
        }
      },
      onError: (e) =>
          debugPrint('ðŸ›‘ UserDataManager stations stream error: $e'),
    );
  }

  void _startRoutesStream() {
    _routesSub?.cancel();
    _routesSub = _supabase.from('routes').stream(primaryKey: ['id']).listen(
      (data) {
        try {
          _routeNamesByUuid = {};
          final parsed = (data).map((json) {
            final name =
                json['name']?.toString() ??
                json['start_point']?.toString() ??
                json['line_number'].toString();
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
          _cachedRoutes = parsed;
          if (!_routesController.isClosed) {
            _routesController.add(parsed);
          }
        } catch (e) {
          debugPrint('ðŸ›‘ UserDataManager routes stream parse error: $e');
        }
      },
      onError: (e) =>
          debugPrint('ðŸ›‘ UserDataManager routes stream error: $e'),
    );
  }

  void _startBusesStream() {
    _busesSub?.cancel();
    _busesSub = _supabase.from('buses').stream(primaryKey: ['id']).listen(
      (data) {
        try {
          _busNumberById = {};
          for (final b in data) {
            if (b['id'] != null && b['bus_number'] != null) {
              _busNumberById![b['id'].toString()] = b['bus_number'].toString();
            }
          }
        } catch (e) {
          debugPrint('ðŸ›‘ UserDataManager buses stream parse error: $e');
        }
      },
      onError: (e) => debugPrint('ðŸ›‘ UserDataManager buses stream error: $e'),
    );
  }

  void stopRealtime() {
    _stationsSub?.cancel();
    _stationsSub = null;
    _routesSub?.cancel();
    _routesSub = null;
    _busesSub?.cancel();
    _busesSub = null;
  }

  Future<void> prefetchData() async {
    await Future.wait([getStations(), getRoutes(), getBuses()]);
  }

  Future<List<StationModel>> getStations({bool forceRefresh = false}) async {
    if (_cachedStations != null && !forceRefresh) return _cachedStations!;
    try {
      final response = await _supabase
          .from('stations')
          .select('*')
          .order('zone', ascending: true)
          .order('order_index', ascending: true);
      _cachedStations = (response as List)
          .map((s) => StationModel.fromJson(s))
          .toList();
      _cachedStations!.sort((a, b) {
        int zoneCompare = a.zone.compareTo(b.zone);
        if (zoneCompare != 0) return zoneCompare;
        return a.orderIndex.compareTo(b.orderIndex);
      });
      return _cachedStations!;
    } catch (e) {
      return _cachedStations ?? [];
    }
  }

  Future<List<RouteModel>> getRoutes({bool forceRefresh = false}) async {
    if (_cachedRoutes != null && !forceRefresh) return _cachedRoutes!;
    try {
      final response = await _supabase.from('routes').select('*');
      _routeNamesByUuid = {};
      _cachedRoutes = (response as List).map((json) {
        final name =
            json['name']?.toString() ??
            json['start_point']?.toString() ??
            json['line_number'].toString();
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
      return _cachedRoutes!;
    } catch (e) {
      return _cachedRoutes ?? [];
    }
  }

  Future<Map<String, String>> getBuses({bool forceRefresh = false}) async {
    if (_busNumberById != null && !forceRefresh) return _busNumberById!;
    try {
      final response = await _supabase.from('buses').select('id, bus_number');
      _busNumberById = {};
      for (final b in response as List) {
        if (b['id'] != null && b['bus_number'] != null) {
          _busNumberById![b['id'].toString()] = b['bus_number'].toString();
        }
      }
      return _busNumberById!;
    } catch (e) {
      return _busNumberById ?? {};
    }
  }

  Future<String?> getRouteNameByUuid(String uuid) async {
    if (_routeNamesByUuid == null) await getRoutes(forceRefresh: true);
    return _routeNamesByUuid?[uuid];
  }

  Future<String?> getBusNumberById(String busId) async {
    if (_busNumberById == null) await getBuses(forceRefresh: true);
    return _busNumberById?[busId];
  }

  void clearCache() {
    _cachedStations = null;
    _cachedRoutes = null;
    _routeNamesByUuid = null;
    _busNumberById = null;
  }
}
