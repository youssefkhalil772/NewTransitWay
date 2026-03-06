import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_points_badge.dart';

class TrackingView extends StatelessWidget {
  const TrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. الهيدر العلوي
          _buildHeader(context),

          Expanded(
            child: Stack(
              children: [
                // 2. خريطة التتبع (صورة الباص والمسار)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 0.60.sh, // تغطية مساحة أكبر للخريطة
                  child: Image.asset(
                    'assets/images/tracking_view.png', // تأكد من اسم الصورة في الـ assets
                    fit: BoxFit.cover,
                  ),
                ),

                // 3. كارد تفاصيل الرحلة المباشرة (Bottom Card)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 30.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40.r),
                        topRight: Radius.circular(40.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الوقت والمسافة المتبقية
                        Text(
                          "15 mins  1.3 km",
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 25.h),

                        // رقم الباص
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Bus Number",
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87
                              ),
                            ),
                            Text(
                              "359",
                              style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1B6A4C) // نفس لون الثيم
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25.h),

                        // محطات البداية والنهاية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLocationItem("From", "El Shorouk City"),
                            Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: Text(
                                  "-",
                                  style: TextStyle(fontSize: 24.sp, color: Colors.black26)
                              ),
                            ),
                            _buildLocationItem("To", "Fifth Settlement"),
                          ],
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ميثود بناء الهيدر
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        child: Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black)
            ),
            Text("Transit", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
            Text("Way", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B6A4C))),
            SizedBox(width: 4.w),
            Icon(Icons.location_on, color: const Color(0xFF1B6A4C), size: 22.sp),
            const Spacer(),
            const CustomPointsBadge(),
          ],
        ),
      ),
    );
  }

  // ميثود بناء تفاصيل الموقع
  Widget _buildLocationItem(String label, String city) {
    return Column(
      crossAxisAlignment: label == "From" ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.black54,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          city,
          style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87
          ),
        ),
      ],
    );
  }
}