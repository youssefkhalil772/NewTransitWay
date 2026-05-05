import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'custom_points_badge.dart';
import '../../../../core/networking/connectivity_service.dart';

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          
          Flexible(
            child: isDriver ? _buildDriverLogo() : _buildPassengerLogo(),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConnectivityIndicator(),
              if (showPoints && !isDriver) 
                const CustomPointsBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerLogo() {
    const Color darkGreen = Color(0xFF1B4D3E);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            "Transit", 
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "Way", 
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: darkGreen),
        ),
        Icon(Icons.location_on, color: darkGreen, size: 18.sp),
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

  Widget _buildConnectivityIndicator() {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStream,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final bool isOnline = snapshot.data ?? true;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.check_circle_outline : Icons.wifi_off_rounded, 
                color: isOnline ? Colors.green : Colors.red, 
                size: 12.sp
              ),
              SizedBox(width: 3.w),
              Text(
                isOnline ? "Online" : "Weak",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isDriver ? 90.h : 70.h);
}
