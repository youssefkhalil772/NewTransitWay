import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:transite_way/core/resources/assest_manager.dart';

class ProfileScreenDriver extends StatelessWidget {
  const ProfileScreenDriver({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(width: 4.w),
                  Icon(Icons.location_on, color: Colors.green, size: 20.sp),
                  Text(
                    ' Driver',
                    style: TextStyle(fontSize: 18.sp, color: Colors.black54),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h), // مسافة أكبر تحت الهيدر

            // Profile Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w), // تحريك الكلام يمين شوية
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor: Colors.orange.shade100,
                    backgroundImage: AssetImage(ImageAssets.boy), // حطي صورة السيد علي هنا
                  ),
                  SizedBox(width: 25.w), // مسافة أكبر بين الصورة والاسم
                  Text(
                    'Sayed Ali',
                    style: TextStyle(
                      fontSize: 22.sp, // تكبير الخط شوية
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 50.h), // مسافة قبل بداية القائمة

            // Menu Items
            _buildMenuItem(
              icon: Icons.ads_click,
              text: 'Activity Status',
              iconColor: Colors.green,
            ),
            _buildMenuItem(
              icon: Icons.confirmation_number_outlined,
              text: 'Add Tickets',
              iconColor: Colors.green,
            ),
            _buildMenuItem(
              icon: Icons.logout,
              text: 'Log Out',
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // Widget مخصص لكل عنصر في القائمة عشان نتحكم في المسافات والخطوط
  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required Color iconColor,
    Color textColor = Colors.black,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h), // زيادة الـ Padding عشان يبعد عن الحافة
          leading: Icon(icon, color: iconColor, size: 28.sp), // تكبير الأيقونة شوية
          title: Text(
            text,
            style: TextStyle(
              fontSize: 18.sp, // تكبير الخط
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          onTap: () {},
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.w),
          child: Divider(
            thickness: 2, // تخانة الخط زي ما طلبتي
            color: Colors.grey, // لون الخط الفاصل
          ),
        ),
        SizedBox(height: 10.h), // مسافة إضافية بين كل عنصر والتاني
      ],
    );
  }
}
