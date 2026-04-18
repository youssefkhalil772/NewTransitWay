import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../core/networking/api_constants.dart';
import '../home/presentation/widgets/custom_app_bar.dart';

class MyTicketsScreen extends StatefulWidget {
  final int userId;
  final VoidCallback? onBackToHome;
  final dynamic refreshTrigger;

  const MyTicketsScreen({
    super.key, 
    this.userId = 1, 
    this.onBackToHome,
    this.refreshTrigger,
  });

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void didUpdateWidget(covariant MyTicketsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId || widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchTickets();
    }
  }

  Future<void> _fetchTickets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final url = "${ApiConstants.baseUrl}${ApiConstants.userTickets(widget.userId)}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _tickets = data is List ? data : [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "My Tickets",
        showBackButton: widget.onBackToHome != null,
        onBackPressed: widget.onBackToHome,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF054F3A)))
          : RefreshIndicator(
              onRefresh: _fetchTickets,
              color: const Color(0xFF054F3A),
              child: _tickets.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 0.7.sh,
                        child: const Center(child: Text("No tickets found")),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                      itemCount: _tickets.length,
                      separatorBuilder: (context, index) => SizedBox(height: 20.h),
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return TicketCard(
                          // التعديل هنا: سحب الحقل 'bus' من الـ API
                          busNumber: ticket['bus']?.toString() ?? ticket['busNumber']?.toString() ?? "---",
                          price: ticket['price']?.toString() ?? "0",
                          time: ticket['time'] ?? "--:--",
                          date: ticket['date'] ?? "--/--",
                          route: ticket['route'] ?? "Unknown Route",
                        );
                      },
                    ),
            ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final String busNumber, price, time, date, route;

  const TicketCard({
    super.key,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: const Color(0xFF054F3A).withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
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
                      _buildInfoRow('Price:', price),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Time:', time),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Date:', date),
                      SizedBox(height: 6.h),
                      _buildInfoRow('Route:', route),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Transit", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black)),
                        Text("Way", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1B4D3E))),
                        SizedBox(width: 2.w),
                        Icon(Icons.location_on, color: const Color(0xFF1B4D3E), size: 16.sp),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/logo/2.png', fit: BoxFit.contain),
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
}

class DottedVerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF054F3A).withOpacity(0.3)..strokeWidth = 1..style = PaintingStyle.stroke;
    const dashHeight = 5.0, dashSpace = 5.0;
    double startY = 0.0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}
