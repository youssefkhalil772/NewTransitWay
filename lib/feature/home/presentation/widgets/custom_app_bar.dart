import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'custom_points_badge.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showPoints;
  final bool showBackButton;
  final bool isDriver;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.showPoints = true,
    this.showBackButton = false,
    this.isDriver = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: 20.w,
        right: 20.w,
        bottom: 10.h,
      ),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          
          Expanded(child: isDriver ? _buildDriverLogo() : _buildPassengerLogo()),
          
          if (showPoints && !isDriver) 
            const CustomPointsBadge(),
        ],
      ),
    );
  }

  Widget _buildPassengerLogo() {
    const Color darkGreen = Color(0xFF1B4D3E);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Transit", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black)),
        Text("Way", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: darkGreen)),
        SizedBox(width: 4.w),
        Icon(Icons.location_on, color: darkGreen, size: 22.sp),
      ],
    );
  }

  Widget _buildDriverLogo() {
    const Color lightGreen = Color(0xFF39C449);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Transit", style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.black)),
            Text("Way", style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: lightGreen)),
            SizedBox(width: 4.w),
            Icon(Icons.location_on, color: lightGreen, size: 20.sp),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 45.w), // تحريك كلمة Driver لتكون تحت Way تقريباً
          child: Text(
            "Driver",
            style: TextStyle(
              fontSize: 18.sp, 
              fontWeight: FontWeight.bold, 
              color: Colors.black,
              height: 0.8, // تقليل المسافة الرأسية بين السطرين
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isDriver ? 90.h : 70.h);
}
