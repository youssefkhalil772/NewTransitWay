import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/routes/routes_manager.dart';
import 'package:transite_way/core/resources/assest_manager.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة المحطات
    final List<String> stations = [
      "Al Arab",
      "Alf Maskan",
      "Al Hegaz Square",
      "El Galaa Bridge",
      "El Saa’a Square",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'TransitWay',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Icon(Icons.location_on, color: Colors.green, size: 20.sp),
                  Text(
                    ' Driver',
                    style: TextStyle(fontSize: 18.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Map Section
            SizedBox(
              height: 200.h,
              width: double.infinity,
              child: Image.asset(
                ImageAssets.map,
                fit: BoxFit.cover,
              ),
            ),

            // Stations List Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        '35 Stations',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        itemCount: stations.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 5.h),
                            title: Text(
                              stations[index],
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                            ),
                          );
                        },
                      ),
                    ),

                    // End Trip Section
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      margin: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Completed The Route ?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                          ),
                          SizedBox(height: 15.h),
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: () {
                                // الانتقال لشاشة البروفايل عند الضغط على End Trip
                                RoutesManager.navigateTo(context, RoutesManager.driverProfile);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'End Trip',
                                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                              ),
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
      ),
    );
  }
}
