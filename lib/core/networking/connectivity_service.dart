import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    _updateStatus(results);

    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final bool hasConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      print("ðŸ“¡ Network Status Changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}");
      _connectionController.add(_isOnline);
    }
  }

  void dispose() {
    _connectionController.close();
  }
}
