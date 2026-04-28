import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/networking/api_constants.dart';
import '../../core/widgets/custom_ticket_card.dart';
import '../home/presentation/widgets/custom_app_bar.dart';
import '../../core/resources/color_manager.dart';

class MyTicketsScreen extends StatefulWidget {
  final int? userId;
  final VoidCallback? onBackToHome;
  final dynamic refreshTrigger;

  const MyTicketsScreen({
    super.key, 
    this.userId, 
    this.onBackToHome,
    this.refreshTrigger,
  });

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _allTickets = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTickets();
  }

  @override
  void didUpdateWidget(covariant MyTicketsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _fetchTickets();
    }
  }

  Future<void> _fetchTickets() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final int? id = widget.userId ?? prefs.getInt('userId');
    
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final url = "${ApiConstants.baseUrl}${ApiConstants.userTickets(id)}";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allTickets = data is List ? data : [];
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

  List<dynamic> get _activeTickets => _allTickets.where((t) {
    final status = t['status']?.toString().toLowerCase() ?? '';
    return status == 'valid' || status == 'sold';
  }).toList();

  List<dynamic> get _historyTickets => _allTickets.where((t) {
    final status = t['status']?.toString().toLowerCase() ?? '';
    return status == 'expired' || status == 'used';
  }).toList();

  double get _totalSpent {
    return _allTickets.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['price']?.toString() ?? '0') ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // تغيير الخلفية للون الأبيض
      appBar: CustomAppBar(
        showBackButton: widget.onBackToHome != null,
        onBackPressed: widget.onBackToHome,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
            child: Text(
              "My Tickets",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          
          // ── Summary Cards ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              children: [
                _buildSummaryCard(
                  label: "Active tickets",
                  value: "${_activeTickets.length}",
                  unit: "tickets",
                ),
                SizedBox(width: 16.w),
                _buildSummaryCard(
                  label: "Total spent",
                  value: _totalSpent.toStringAsFixed(0),
                  unit: "EGP",
                ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Container(
              height: 50.h,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA), // جعل خلفية الـ TabBar رمادي فاتح عشان تظهر على الخلفية البيضاء
                borderRadius: BorderRadius.circular(15.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: ColorManager.green,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF888888),
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "Active"),
                  Tab(text: "History"),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: ColorManager.green))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTicketList(_activeTickets, "No active tickets", Icons.confirmation_number_outlined),
                      _buildTicketList(_historyTickets, "No history found", Icons.history_rounded),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String label, required String value, required String unit}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2F5E4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF888888),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  unit,
                  style: TextStyle(
                    color: const Color(0xFF888888),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(List<dynamic> tickets, String emptyMsg, IconData emptyIcon) {
    return RefreshIndicator(
      onRefresh: _fetchTickets,
      color: ColorManager.green,
      child: tickets.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.5.sh,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(emptyIcon, size: 64.sp, color: Colors.grey[300]),
                      SizedBox(height: 16.h),
                      Text(
                        emptyMsg,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 20.h),
              itemCount: tickets.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return CustomTicketCard(
                  busNumber: ticket['bus']?.toString() ?? ticket['busNumber']?.toString() ?? "---",
                  price: ticket['price']?.toString() ?? "0",
                  time: ticket['time'] ?? "--:--",
                  date: ticket['date'] ?? "--/--",
                  route: ticket['route'],
                  status: ticket['status'],
                );
              },
            ),
    );
  }
}
