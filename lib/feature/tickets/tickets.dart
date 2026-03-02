import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// تأكدي من صحة مسار الـ import للويدجيت الموحدة في مشروعك
import '../home/presentation/widgets/custom_points_badge.dart';

class MyTicketsScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const MyTicketsScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1F1),
      appBar: _buildAppBar(context),
      body: _buildTicketsList(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
        onPressed: () {
          // الربط مع الهوم لضمان عدم الرجوع لصفحة فارغة
          if (onBackToHome != null) {
            onBackToHome!();
          } else {
            Navigator.maybePop(context);
          }
        },
      ),
      title: Text(
        'My Tickets',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: const Center(
            child: CustomPointsBadge(points: "9833"),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketsList() {
    final List<Map<String, String>> tickets = [
      {'bus': '359', 'price': '35', 'time': '9:00 pm', 'date': '25-2-2026'},
      {'bus': '009', 'price': '35', 'time': '1:30 pm', 'date': '2-2-2026'},
      {'bus': '117', 'price': '15', 'time': '7:00 am', 'date': '21-1-2026'},
      {'bus': 'Q9', 'price': '35', 'time': '12:00 pm', 'date': '22-2-2026'},
    ];

    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: tickets.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        return TicketCard(
          busNumber: tickets[index]['bus']!,
          price: tickets[index]['price']!,
          time: tickets[index]['time']!,
          date: tickets[index]['date']!,
        );
      },
    );
  }
}

class TicketCard extends StatelessWidget {
  final String busNumber, price, time, date;

  const TicketCard({
    super.key,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF054F3A).withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSideLabel(),
            _buildTicketDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideLabel() {
    return SizedBox(
      width: 48.w,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: DottedVerticalLinePainter()),
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'هيئة النقل العام',
                    style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'بالقاهرة',
                    style: TextStyle(color: Colors.black, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12.w, 14.h, 16.w, 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Bus:', busNumber),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Price:', '$price EGP'),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Time:', time),
                  SizedBox(height: 8.h),
                  _buildInfoRow('Date:', date),
                ],
              ),
            ),
            _buildLogos(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogos() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Image.asset('assets/logo/1.png', width: 60.w, height: 40.h, fit: BoxFit.contain),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.amber.withOpacity(0.2), width: 1),
          ),
          child: Image.asset('assets/logo/2.png', width: 45.w, height: 45.h, fit: BoxFit.contain),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }
}

class DottedVerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF054F3A).withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashHeight = 6.0;
    const dashSpace = 6.0;
    double startY = 0.0;
    final xPosition = size.width - 2.w;

    while (startY < size.height) {
      canvas.drawLine(Offset(xPosition, startY), Offset(xPosition, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}