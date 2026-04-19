import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'custom_points_badge.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showPoints;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.title = "TransitWay",
    this.showPoints = true,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 10.w,
        right: 20.w,
        bottom: 10.h,
      ),
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
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            )
          else
            SizedBox(width: 10.w),
          
          _buildLogo(),
          
          const Spacer(),
          
          if (showPoints) const CustomPointsBadge(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Text(
          "Transit",
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          "Way",
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1B4D3E),
          ),
        ),
        SizedBox(width: 4.w),
        Icon(
          Icons.location_on,
          color: const Color(0xFF1B4D3E),
          size: 22.sp,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(75.h);
}
