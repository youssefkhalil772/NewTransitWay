import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/routes/routes_manager.dart';
import '../widgets/custom_points_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: 1.sh - MediaQuery.of(context).padding.top - 80.h,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 0.45.sh,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/maps.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),

                    Positioned(
                      top: 0.4.sh,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildSearchCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLogo(),
            const CustomPointsBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Text("Transit", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
        Text("Way", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B6A4C))),
        SizedBox(width: 4.w),
        Icon(Icons.location_on, color: const Color(0xFF1B6A4C), size: 24.sp),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("From:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          _buildSearchField("Search"),
          SizedBox(height: 15.h),
          Text("To:", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          _buildSearchField("Search"),
          SizedBox(height: 25.h),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, RoutesManager.busTracking),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFF054F3A),
              minimumSize: Size(double.infinity, 55.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            ),
            child: Text("Trip & Bus", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
      ),
    );
  }
}