import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> prefetchData() async {
    await Future.wait([
      getStations(),
      getRoutes(),
    ]);
  }

  Future<List<StationModel>> getStations({bool forceRefresh = false}) async {
    if (_cachedStations != null && !forceRefresh) return _cachedStations!;

    try {
      final response = await _supabase.from('stations').select('*');
      _cachedStations = (response as List).map((s) => StationModel.fromJson(s)).toList();
      return _cachedStations!;
    } catch (e) {
      return _cachedStations ?? [];
    }
  }

  Future<List<RouteModel>> getRoutes({bool forceRefresh = false}) async {
    if (_cachedRoutes != null && !forceRefresh) return _cachedRoutes!;

    try {
      final response = await _supabase.from('routes').select('*');
      _cachedRoutes = (response as List).map((r) => RouteModel.fromJson(r)).toList();
      return _cachedRoutes!;
    } catch (e) {
      return _cachedRoutes ?? [];
    }
  }

  void clearCache() {
    _cachedStations = null;
    _cachedRoutes = null;
  }
}
