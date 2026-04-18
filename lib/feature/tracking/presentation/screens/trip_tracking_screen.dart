import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/tracking_service.dart';

class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final TrackingService _service = TrackingService();
  final TextEditingController _busIdController = TextEditingController();

  StreamSubscription<Position>? _positionStream;
  DateTime? _lastSendTime; // للتحكم في معدل الإرسال (مثلاً كل ثانية)

  bool isRealTimeEnabled = false;
  bool isManualSending = false;
  double speed = 0.0;
  double lat = 0.0;
  double lng = 0.0;

  @override
  void initState() {
    super.initState();
    _startLiveSpeedometer();
  }

  void _startLiveSpeedometer() {
    // إعدادات الموقع للأندرويد لضمان استلام التحديثات بدقة
    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
    );
    
    // إعدادات الموقع للـ iOS
    final appleSettings = AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      pauseLocationUpdatesAutomatically: false,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: androidSettings, // أو استخدم appleSettings لو شغال iOS
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          double rawSpeed = pos.speed < 0 ? 0 : pos.speed * 3.6;
          speed = rawSpeed;
          lat = pos.latitude;
          lng = pos.longitude;
        });

        if (isRealTimeEnabled) {
          _sendDataLocally(pos);
        }
      }
    }, onError: (error) {
      debugPrint("GPS Stream Error: $error");
    });
  }

  void _sendDataLocally(Position pos) {
    final now = DateTime.now();
    if (_lastSendTime == null || now.difference(_lastSendTime!) >= const Duration(seconds: 1)) {
      _lastSendTime = now;
      int id = int.tryParse(_busIdController.text.trim()) ?? 0;
      if (id != 0) {
        _service.sendToApi(id, pos.latitude, pos.longitude, pos.speed * 3.6);
        debugPrint("📡 Real-Time Sync: Lat: ${pos.latitude}, Lng: ${pos.longitude}");
      }
    }
  }

  void toggleRealTime(bool value) {
    if (_busIdController.text.trim().isEmpty && value) {
      _showSnackBar("Please enter Bus ID first");
      return;
    }

    setState(() {
      isRealTimeEnabled = value;
    });

    if (isRealTimeEnabled) {
      _showSnackBar("Real-Time Tracking Active 📡");
    } else {
      _showSnackBar("Real-Time Mode Disabled");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _busIdController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("TRANSIT WAY PRO",
            style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isRealTimeEnabled ? Colors.blueAccent.withAlpha(25) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isRealTimeEnabled ? Colors.blueAccent : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("REAL-TIME SYNC",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(isRealTimeEnabled ? "Updating live from GPS" : "Manual mode active",
                          style: const TextStyle(color: Colors.blueGrey, fontSize: 11)),
                    ],
                  ),
                  Switch(
                    value: isRealTimeEnabled,
                    onChanged: toggleRealTime,
                    activeTrackColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _busIdController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                enabled: !isRealTimeEnabled,
                decoration: InputDecoration(
                  labelText: "BUS IDENTIFIER",
                  labelStyle: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                  prefixIcon: const Icon(Icons.directions_bus, color: Colors.blueAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueGrey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 250, width: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isRealTimeEnabled ? Colors.blueAccent : Colors.blueAccent.withAlpha(25), width: 2),
                  ),
                ),
                Container(
                  height: 220, width: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.blueAccent.withAlpha(25), Colors.transparent],
                    ),
                    border: Border.all(color: isRealTimeEnabled ? Colors.blueAccent : Colors.blueAccent.withAlpha(100), width: 8),
                    boxShadow: isRealTimeEnabled ? [
                      BoxShadow(color: Colors.blueAccent.withAlpha(76), blurRadius: 40, spreadRadius: 5),
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        speed.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const Text("KM/H", style: TextStyle(color: Colors.blueGrey, fontSize: 16, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoTile("LATITUDE", lat.toStringAsFixed(5)),
                _buildInfoTile("LONGITUDE", lng.toStringAsFixed(5)),
              ],
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                onPressed: (isManualSending || isRealTimeEnabled) ? null : () async {
                  if (_busIdController.text.trim().isEmpty) {
                    _showSnackBar("Please enter Bus ID");
                    return;
                  }
                  setState(() => isManualSending = true);
                  int id = int.tryParse(_busIdController.text.trim()) ?? 0;
                  await _service.sendToApi(id, lat, lng, speed);
                  _showSnackBar("Manual Sync Success ✅");
                  setState(() => isManualSending = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRealTimeEnabled ? Colors.blueGrey.shade800 : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: isManualSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isRealTimeEnabled ? "REAL-TIME SYNCING..." : "SYNC DATA NOW",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'monospace')),
      ],
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
