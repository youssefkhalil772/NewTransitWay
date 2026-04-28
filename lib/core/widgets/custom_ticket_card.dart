import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resources/color_manager.dart';

class CustomTicketCard extends StatelessWidget {
  final String busNumber, price, time, date;
  final String? route;
  final String? status;

  const CustomTicketCard({
    super.key,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
    this.route,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد لون الحالة
    Color statusColor = Colors.grey;
    final String normalizedStatus = status?.toLowerCase() ?? '';
    
    if (normalizedStatus == 'sold' || normalizedStatus == 'valid') {
      statusColor = ColorManager.green; // تغيير لـ Green الغامق
    } else if (normalizedStatus == 'expired') {
      statusColor = Colors.redAccent;
    }

    return Container(
      height: 185.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: normalizedStatus == 'expired' 
              ? Colors.redAccent.withOpacity(0.3) 
              : ColorManager.green.withOpacity(0.5), 
          width: 1
        ),
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
          // ── الجزء الأيمن (هيئة النقل العام) ────────────────────────
          Container(
            width: 60.w,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Center(
                      child: Text(
                        'هيئة النقل العام بالقاهرة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: DottedVerticalLinePainter(),
                ),
              ],
            ),
          ),
          
          // ── الجزء الأيسر (بيانات التذكرة) ──────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(15.w, 15.h, 20.w, 15.h),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Bus:', busNumber),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Price:', '$price EGP'),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Time:', time),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Date:', date),
                      if (route != null) ...[
                        SizedBox(height: 6.h),
                        _buildRouteRow('Route:', route!),
                      ],
                    ],
                  ),
                  
                  // Brand Logo Top Right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Transit", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text("Way", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: ColorManager.green)),
                        SizedBox(width: 2.w),
                        Icon(Icons.location_on, color: ColorManager.green, size: 16.sp),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  if (status != null)
                    Positioned(
                      top: 25.h,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(color: statusColor, width: 0.5),
                        ),
                        child: Text(
                          status!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Right Circle Logo
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: normalizedStatus == 'expired' ? Colors.redAccent.withOpacity(0.2) : Colors.amber.withOpacity(0.3), 
                          width: 1
                        ),
                      ),
                      child: ClipOval(
                        child: Opacity(
                          opacity: normalizedStatus == 'expired' ? 0.5 : 1.0,
                          child: Image.asset(
                            'assets/logo/2.png', 
                            fit: BoxFit.contain, 
                            errorBuilder: (c, e, s) => Icon(Icons.qr_code, color: Colors.amber, size: 30.sp)
                          ),
                        ),
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black)),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: 65.w), // حماية منطقة اللوجو
            child: Text(
              value,
              maxLines: 2,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87, height: 1.1),
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }
}

class DottedVerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ColorManager.green.withOpacity(0.3)..strokeWidth = 1..style = PaintingStyle.stroke;
    const dashHeight = 5.0, dashSpace = 5.0;
    double startY = 0.0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}
