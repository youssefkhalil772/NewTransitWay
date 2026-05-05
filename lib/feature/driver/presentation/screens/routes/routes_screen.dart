import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/feature/tracking/data/tracking_service.dart';
import 'package:transite_way/feature/home/data/models/station_model.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import 'package:transite_way/feature/home/data/home_repository.dart';
import 'package:transite_way/feature/driver/services/crash_detector.dart';
import 'package:transite_way/feature/driver/services/sos_service.dart';
import 'package:transite_way/feature/driver/presentation/widgets/sos_overlay.dart';

part 'routes_screen_state.dart';

class RoutesScreen extends StatefulWidget {
  final VoidCallback onEndTrip;
  final VoidCallback onGoHome;
  final bool isTab;
  final List<StationModel> stations;
  final int refreshTrigger;

  const RoutesScreen({
    super.key,
    required this.onEndTrip,
    required this.onGoHome,
    this.isTab = false,
    required this.stations,
    this.refreshTrigger = 0,
  });

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

// ─── UI ───────────────────────────────────────────────────────────────────────
extension _RoutesScreenUI on _RoutesScreenState {
  Widget buildMainScreen() {
    final Color routeColor = widget.stations.isNotEmpty
        ? RouteModel.getColorFromName(widget.stations.first.zone)
        : const Color(0xFF39C449);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomTopBar(),
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation!,
                      initialZoom: 16,
                      onMapReady: () => _isMapReady = true,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        retinaMode: RetinaMode.isHighDensity(context),
                      ),
                      if (_polylinePoints.isNotEmpty)
                        PolylineLayer(polylines: [
                          Polyline(
                            points: _polylinePoints,
                            color: _isFetchingRoute
                                ? routeColor.withValues(alpha: 0.4)
                                : routeColor,
                            strokeWidth: 6.0,
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.white,
                          ),
                        ]),
                      MarkerLayer(markers: [
                        ...widget.stations.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          if (idx < _nextStationIndex) {
                            return const Marker(
                                point: LatLng(0, 0), child: SizedBox());
                          }
                          return Marker(
                            point: entry.value.position,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: routeColor, width: 2),
                              ),
                              child: Icon(Icons.location_on,
                                  color: routeColor, size: 16),
                            ),
                          );
                        }),
                        Marker(
                          point: _currentLocation!,
                          width: 50,
                          height: 50,
                          child: Transform.rotate(
                            angle: _currentHeading * (3.14159265 / 180),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 6)
                                ],
                              ),
                              child: const Icon(Icons.directions_bus,
                                  color: Color(0xFF39C449), size: 32),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  _buildLiveStatusOverlay(),
                  if (_isFetchingRoute)
                    Positioned(
                      top: 16.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: const CircularProgressIndicator(
                                  color: Color(0xFF39C449),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Rerouting...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRouteProgressHeader(),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.stations.length,
                        itemBuilder: (context, index) =>
                            _buildTimelineItem(index),
                      ),
                    ),
                    _buildEndTripButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    "TransitWay",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  " · Driver",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // LIVE badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              "LIVE",
              style: TextStyle(
                color: const Color(0xFF39C449),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // SOS button — manual trigger (only active during trip)
          GestureDetector(
            onTap: _sendSosManually,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusOverlay() {
    return Positioned(
      bottom: 20.h,
      right: 15.w,
      left: 15.w,
      child: Row(
        children: [
          Container(
            width: 100.w,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentSpeed.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF39C449),
                  ),
                ),
                Text(
                  "KM/H",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Next stop",
                          style:
                              TextStyle(fontSize: 10.sp, color: Colors.grey),
                        ),
                        Text(
                          _currentNextStationName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _etaToNextStation,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF39C449),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteProgressHeader() {
    final int remaining = widget.stations.length - _nextStationIndex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            "Route progress",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            "$remaining remaining",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(int index) {
    final bool isReached = index < _nextStationIndex;
    final bool isNext = index == _nextStationIndex;
    final bool isLast = index == widget.stations.length - 1;

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            child: Column(
              children: [
                Container(
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: isReached
                        ? const Color(0xFF39C449)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReached
                          ? const Color(0xFF39C449)
                          : (isNext ? Colors.orange : Colors.grey[300]!),
                      width: isNext ? 3 : 2,
                    ),
                  ),
                  child: isReached
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 10)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: isReached
                          ? const Color(0xFF39C449)
                          : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    widget.stations[index].name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight:
                          isNext ? FontWeight.bold : FontWeight.w500,
                      color: isReached
                          ? Colors.grey[400]
                          : (isNext ? Colors.black : Colors.grey[400]),
                      decoration:
                          isReached ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isNext)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      "Next stop · $_etaToNextStation",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                if (!isNext) SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndTripButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: SizedBox(
        width: double.infinity,
        height: 55.h,
        child: ElevatedButton(
          onPressed: _isEndingTrip ? null : () async {
            final prefs = await SharedPreferences.getInstance();
            String? busId = prefs.getString('busId');
            if (busId == null) return;

            setState(() => _isEndingTrip = true);

            try {
              await _trackingService.endTrip(busId);
              _rerouteDebounce?.cancel();
              await prefs.setBool('isTripActive', false);
              _resetTripState();
              widget.onEndTrip();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to end trip: $e"), backgroundColor: Colors.red),
                );
              }
            } finally {
              if (mounted) {
                // ignore: invalid_use_of_protected_member
                setState(() => _isEndingTrip = false);
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39C449),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: _isEndingTrip 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'END TRIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget buildLoadingView() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF39C449)),
            SizedBox(height: 20),
            Text("Locating your position...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget buildNoTripView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bus_alert, size: 80.sp, color: Colors.orange),
            SizedBox(height: 20.h),
            const Text('No Active Trip',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: const Text(
                'Please go to Home and click "Start Trip" to begin tracking your route.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 30.h),
            ElevatedButton(
              onPressed: widget.onGoHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39C449),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Go to Home',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
