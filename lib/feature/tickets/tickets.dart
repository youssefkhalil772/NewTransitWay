import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/networking/api_constants.dart';
import '../../core/networking/supabase_init.dart';
import '../../core/widgets/custom_ticket_card.dart';
import '../home/presentation/widgets/custom_app_bar.dart';
import '../../core/resources/color_manager.dart';

class MyTicketsScreen extends StatefulWidget {
  final String? userId;
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
    final String? id = widget.userId?.toString() ?? prefs.getString('userId');
    
    if (id == null || id.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Step 1: Fetch raw tickets (no FK joins available)
      final rawTickets = await SupabaseConfig.client
          .from(ApiConstants.ticketsTable)
          .select('*')
          .eq('user_id', id)
          .order('created_at', ascending: false);

      if (rawTickets.isEmpty) {
        if (mounted) setState(() { _allTickets = []; _isLoading = false; });
        return;
      }

      // Step 2: Collect unique route_ids and bus_ids
      final routeIds = rawTickets.map((t) => t['route_id']).whereType<int>().toSet().toList();
      final busIds = rawTickets.map((t) => t['bus_id']).where((id) => id != null).map((id) => id.toString()).toSet().toList();

      Map<int, Map<String, dynamic>> routeMap = {};
      Map<String, Map<String, dynamic>> busMap = {};

      if (routeIds.isNotEmpty) {
        final routesRes = await SupabaseConfig.client
            .from('routes')
            .select('id, name, price')
            .inFilter('id', routeIds);
        for (final r in routesRes) {
          routeMap[r['id'] as int] = Map<String, dynamic>.from(r);
        }
      }

      if (busIds.isNotEmpty) {
        final busesRes = await SupabaseConfig.client
            .from('buses')
            .select('id, bus_number')
            .inFilter('id', busIds);
        for (final b in busesRes) {
          busMap[b['id'].toString()] = Map<String, dynamic>.from(b);
        }
      }

      // Step 3: Merge relational data into tickets
      final enriched = rawTickets.map((t) {
        final ticket = Map<String, dynamic>.from(t);
        final routeId = ticket['route_id'] as int?;
        final busId = ticket['bus_id']?.toString();
        ticket['routes'] = routeId != null ? routeMap[routeId] : null;
        ticket['buses'] = busId != null ? busMap[busId] : null;
        return ticket;
      }).toList();

      if (mounted) {
        setState(() {
          _allTickets = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🛑 Fetch Tickets Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _activeTickets => _allTickets.where((t) {
    final status = t['status']?.toString().toLowerCase() ?? '';
    return status == 'active' || status == 'valid' || status == 'sold';
  }).toList();

  List<dynamic> get _historyTickets => _allTickets.where((t) {
    final status = t['status']?.toString().toLowerCase() ?? '';
    return status == 'expired' || status == 'used';
  }).toList();

  double get _totalSpent {
    return _allTickets.fold(0.0, (sum, item) {
      final priceStr = (item['routes'] as Map?)?['price']?.toString() ?? item['price']?.toString() ?? '0';
      return sum + (double.tryParse(priceStr) ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
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
                color: const Color(0xFFF8F9FA), // Light gray TabBar background for visibility on white
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
                
                final routeName = (ticket['routes'] as Map?)?['name']?.toString() ?? ticket['route'] ?? "---";
                final busNum = (ticket['buses'] as Map?)?['bus_number']?.toString() ?? ticket['bus']?.toString() ?? ticket['busNumber']?.toString() ?? "---";
                final price = (ticket['routes'] as Map?)?['price']?.toString() ?? ticket['price']?.toString() ?? "0";
                
                // Map DB status to display label
                final rawStatus = ticket['status']?.toString().toLowerCase() ?? 'active';
                final displayStatus = rawStatus == 'active' ? 'Sold' : ticket['status'];

                // Detect ticket type
                final code = ticket['ticket_code']?.toString() ?? '';
                final ticketType = code.startsWith('MANUAL-') ? 'Manual Ticket' : 'QR Ticket';
                
                DateTime? createdAt;
                try { createdAt = DateTime.parse(ticket['created_at']); } catch (_) {}
                final timeStr = createdAt != null ? DateFormat('hh:mm a').format(createdAt.toLocal()) : (ticket['time'] ?? "--:--");
                final dateStr = createdAt != null ? DateFormat('dd/MM/yyyy').format(createdAt.toLocal()) : (ticket['date'] ?? "--/--");

                return CustomTicketCard(
                  busNumber: busNum,
                  price: price,
                  time: timeStr,
                  date: dateStr,
                  route: routeName,
                  status: displayStatus,
                  ticketType: ticketType,
                );
              },
            ),
    );
  }
}
