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
import 'package:transite_way/feature/driver/data/driver_data_manager.dart';
import 'package:transite_way/core/widgets/swipe_to_confirm.dart';

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
    final Color routeColor = activeStations.isNotEmpty
        ? RouteModel.getColorFromName(activeStations.first.zone)
        : const Color(0xFF39C449);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomTopBar(routeColor),
            Expanded(
              flex: 55,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation ?? const LatLng(30.0444, 31.2357),
                      initialZoom: 16.5,
                      onMapReady: () {
                        _isMapReady = true;
                        // Immediately center on bus if we have location
                        if (_currentLocation != null) {
                          _mapController.move(_currentLocation!, 16.5);
                        }
                      },
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),

                    ),
                    children: [
                      // Premium dark map tiles
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        retinaMode: RetinaMode.isHighDensity(context),
                      ),
                      // Route polyline with glow effect
                      if (_polylinePoints.isNotEmpty) ...[
                        // Glow layer
                        PolylineLayer(polylines: [
                          Polyline(
                            points: _polylinePoints,
                            color: routeColor.withValues(alpha: 0.25),
                            strokeWidth: 14.0,
                          ),
                        ]),
                        // Main route line
                        PolylineLayer(polylines: [
                          Polyline(
                            points: _polylinePoints,
                            color: _isFetchingRoute
                                ? routeColor.withValues(alpha: 0.5)
                                : routeColor,
                            strokeWidth: 5.0,
                            borderStrokeWidth: 1.5,
                            borderColor: Colors.white.withValues(alpha: 0.3),
                          ),
                        ]),
                      ],
                      // Station markers
                      MarkerLayer(markers: [
                        ...activeStations.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          if (idx < _nextStationIndex) {
                            return const Marker(
                                point: LatLng(0, 0), child: SizedBox());
                          }
                          final bool isNext = idx == _nextStationIndex;
                          return Marker(
                            point: entry.value.position,
                            width: isNext ? 36 : 24,
                            height: isNext ? 36 : 24,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isNext ? routeColor : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isNext ? Colors.white : routeColor,
                                  width: isNext ? 2.5 : 1.5,
                                ),
                                boxShadow: isNext
                                    ? [
                                        BoxShadow(
                                          color: routeColor.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                Icons.circle,
                                color: isNext ? Colors.white : routeColor,
                                size: isNext ? 12 : 8,
                              ),
                            ),
                          );
                        }),
                        // Bus marker
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 56,
                            height: 56,
                            child: Transform.rotate(
                              angle: _currentHeading * (3.14159265 / 180),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: routeColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: routeColor.withValues(alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                      ]),
                    ],
                  ),
                  // Speed + next stop overlay
                  _buildLiveStatusOverlay(routeColor),
                  // Re-centering FAB
                  Positioned(
                    bottom: 130.h,
                    right: 15.w,
                    child: GestureDetector(
                      onTap: () {
                        if (_currentLocation != null && _isMapReady) {
                          _mapController.move(_currentLocation!, 16.5);
                        }
                      },
                      child: Container(
                        width: 42.w,
                        height: 42.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          color: routeColor,
                          size: 20.sp,
                        ),
                      ),
                    ),
                  ),
                  // Rerouting indicator
                  if (_isFetchingRoute)
                    Positioned(
                      top: 12.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12.w,
                                height: 12.h,
                                child: CircularProgressIndicator(
                                  color: routeColor,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "Updating route...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
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
            // Bottom panel
            Expanded(
              flex: 45,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28.r),
                    topRight: Radius.circular(28.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 36.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    _buildRouteProgressHeader(routeColor),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: activeStations.length,
                        itemBuilder: (context, index) =>
                            _buildTimelineItem(index, routeColor),
                      ),
                    ),
                    _buildEndTripButton(routeColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTopBar(Color routeColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          _LiveDot(color: routeColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "TransitWay · Driver",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "Trip Active",
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: routeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Speed display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: routeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              "${_currentSpeed.toStringAsFixed(0)} km/h",
              style: TextStyle(
                color: routeColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // SOS button
          GestureDetector(
            onTap: _sendSosManually,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFCC0000),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_rounded,
                      color: Colors.white, size: 13.sp),
                  SizedBox(width: 3.w),
                  Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.sp,
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

  Widget _buildLiveStatusOverlay(Color routeColor) {
    return Positioned(
      bottom: 12.h,
      right: 15.w,
      left: 15.w,
      child: Row(
        children: [
          // Speed card
          Container(
            width: 80.w,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
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
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    color: routeColor,
                  ),
                ),
                Text(
                  "KM/H",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Next stop card
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
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
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: routeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.near_me_rounded,
                      color: routeColor,
                      size: 18.sp,
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
                          style: TextStyle(
                              fontSize: 9.sp, color: Colors.grey),
                        ),
                        Text(
                          _currentNextStationName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _etaToNextStation,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: routeColor,
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

  Widget _buildRouteProgressHeader(Color routeColor) {
    final int total = activeStations.length;
    final int reached = _nextStationIndex.clamp(0, total);
    final double progress = total > 0 ? reached / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Route Progress",
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: routeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "$reached / $total stops",
                style: TextStyle(
                  fontSize: 11.sp,
                  color: routeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(routeColor),
            minHeight: 5.h,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(int index, Color routeColor) {
    final bool isReached = index < _nextStationIndex;
    final bool isNext = index == _nextStationIndex;
    final bool isLast = index == activeStations.length - 1;

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 36.w,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 16.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: isReached ? routeColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isReached
                          ? routeColor
                          : isNext
                              ? Colors.orange
                              : Colors.grey[300]!,
                      width: isNext ? 2.5 : 1.5,
                    ),
                    boxShadow: isNext
                        ? [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                  child: isReached
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 9)
                      : isNext
                          ? Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: isReached
                          ? routeColor
                          : Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeStations[index].name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          isNext ? FontWeight.bold : FontWeight.w500,
                      color: isReached
                          ? Colors.grey[350]
                          : isNext
                              ? Colors.black
                              : Colors.grey[500],
                      decoration:
                          isReached ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isNext)
                    Text(
                      "Approaching · $_etaToNextStation",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
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

  Widget _buildEndTripButton(Color routeColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: SwipeToConfirm(
        text: "SWIPE TO END TRIP",
        baseColor: Colors.redAccent,
        isLoading: _isEndingTrip,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          final String? busId = prefs.getString('busId');
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
                SnackBar(
                    content: Text("Failed to end trip: $e"),
                    backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) setState(() => _isEndingTrip = false);
          }
        },
      ),
    );
  }

  Widget buildLoadingView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(30.0444, 31.2357),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
            ],
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Color(0xFF39C449),
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "Getting GPS signal...",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
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

  Widget buildNoTripView() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bus_alert, size: 52.sp, color: Colors.orange),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Active Trip',
              style: TextStyle(
                  fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.w),
              child: Text(
                'Go to Home and tap "Start Trip" to begin tracking your route.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: widget.onGoHome,
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: const Text('Go to Home',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39C449),
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live animated dot widget ─────────────────────────────────────────────────
class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 6)
          ],
        ),
      ),
    );
  }
}
