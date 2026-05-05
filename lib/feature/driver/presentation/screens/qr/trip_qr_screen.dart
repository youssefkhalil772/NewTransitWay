import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TripQrScreen extends StatefulWidget {
  final bool isTab;
  const TripQrScreen({super.key, this.isTab = false});

  @override
  State<TripQrScreen> createState() => _TripQrScreenState();
}

class _TripQrScreenState extends State<TripQrScreen> {
  static const _green = Color(0xff39C449);
  static const _lightGreen = Color(0xffE8F7EA);

  bool _isLoading = true;
  String? _errorMessage;
  String? _qrToken;
  String? _routeName;
  double? _price;
  String? _busNumber;
  StreamSubscription? _tripSubscription;

  static const Map<String, String> _arabicErrors = {
    'Driver or bus not found': 'No bus assigned to you',
    'No active trip for this bus': 'No active trip right now',
    'Route not found': 'Route details not found',
  };

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  String _translateError(String? error) {
    if (error == null) return 'An unexpected error occurred';
    for (final entry in _arabicErrors.entries) {
      if (error.contains(entry.key)) return entry.value;
    }
    return error;
  }

  Future<void> _initData() async {
    // We let VisibilityDetector handle the first generation
  }



  Future<void> _generateQr({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final driverId = Supabase.instance.client.auth.currentUser?.id;
      if (driverId == null) {
        if (mounted) setState(() { _errorMessage = 'You must log in first'; _isLoading = false; });
        return;
      }

      final response = await Supabase.instance.client.functions.invoke(
        'generate-qr',
        body: {'driverId': driverId},
      );

      final data = response.data;

      if (data is Map && data['error'] != null) {
        if (mounted) setState(() { _errorMessage = _translateError(data['error'].toString()); _isLoading = false; });
        return;
      }

      if (mounted) {
        setState(() {
          _qrToken = data['token']?.toString();
          _routeName = data['routeName']?.toString();
          _price = (data['price'] as num?)?.toDouble();
          _busNumber = data['busNumber']?.toString() ?? data['busId']?.toString();
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _translateError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const ValueKey('trip_qr_visibility'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction == 1.0) {
          // Regenerate QR every time the user comes back to this tab
          _generateQr(showLoading: false);
        }
      },
      child: widget.isTab ? _buildBody() : Scaffold(backgroundColor: Colors.white, body: _buildBody()),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading 
            ? _buildLoadingSkeleton(key: const ValueKey('loading'))
            : _errorMessage != null
                ? _buildErrorState(key: const ValueKey('error'))
                : _buildContent(key: const ValueKey('content')),
      ),
    );
  }

  Widget _buildLoadingSkeleton({Key? key}) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
      child: Column(
        children: [
          SkeletonLoader(width: 80.w, height: 80.w, borderRadius: 40.r),
          SizedBox(height: 16.h),
          SkeletonLoader(width: 150.w, height: 24.h),
          SizedBox(height: 8.h),
          SkeletonLoader(width: 200.w, height: 16.h),
          SizedBox(height: 32.h),
          SkeletonLoader(width: double.infinity, height: 80.h, borderRadius: 16.r),
          SizedBox(height: 24.h),
          SkeletonLoader(width: double.infinity, height: 350.h, borderRadius: 24.r),
        ],
      ),
    );
  }

  Widget _buildContent({Key? key}) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildRouteInfo(),
          SizedBox(height: 24.h),
          _buildQrCard(),
          SizedBox(height: 24.h),
          _buildRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: const BoxDecoration(color: _lightGreen, shape: BoxShape.circle),
          child: const Icon(Icons.qr_code_2, color: _green, size: 36),
        ),
        SizedBox(height: 12.h),
        Text('Trip QR Code',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 6.h),
        Text('Show this QR to passengers for payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffB8E7BE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.route, color: _green, size: 20),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _routeName ?? '---',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: _green, size: 20),
              SizedBox(width: 8.w),
              Text(
                'Ticket Price: ${_price?.toStringAsFixed(0) ?? '--'} EGP',
                style: TextStyle(fontSize: 13.sp, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFB8E7BE), width: 2),
        boxShadow: [
          BoxShadow(color: _green.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: _qrToken!,
            version: QrVersions.auto,
            size: 220.w,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _green),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1B4D3E)),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(30.r)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus, color: _green, size: 18),
                SizedBox(width: 8.w),
                Text('Bus #${_busNumber ?? '---'}',
                    style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 14.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateQr,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: Text('Refresh QR',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          elevation: 0,
        ),
      ),
    );
  }



  Widget _buildErrorState({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade400, size: 48.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _generateQr,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text('Try Again',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
