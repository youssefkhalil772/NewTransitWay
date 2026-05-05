import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:transite_way/feature/home/data/user_data_manager.dart';
import '../../core/networking/api_constants.dart';
import '../../core/networking/supabase_init.dart';
import '../../core/widgets/custom_ticket_card.dart';
import '../home/presentation/widgets/custom_app_bar.dart';
import '../home/data/home_repository.dart';
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

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _allTickets = [];
  bool _isLoading = true;
  late TabController _tabController;
  StreamSubscription? _ticketsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeRealtime();
  }

  @override
  void didUpdateWidget(covariant MyTicketsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTrigger != oldWidget.refreshTrigger) {
      _initializeRealtime();
    }
  }

  @override
  void dispose() {
    _ticketsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeRealtime() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final String? id = widget.userId?.toString() ?? prefs.getString('userId');

    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Prefetch routes/stations for local mapping
    await UserDataManager().prefetchData();

    _ticketsSubscription?.cancel();
    _ticketsSubscription = SupabaseConfig.client
        .from(ApiConstants.ticketsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', id)
        .order('created_at', ascending: false)
        .listen(
          (data) async {
            final enriched = await _enrichTicketsLocally(data);
            if (mounted) {
              setState(() {
                _allTickets = enriched;
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            debugPrint("🛑 Tickets Stream Error: $e");
            if (mounted) setState(() => _isLoading = false);
          },
        );
  }

  Future<List<dynamic>> _enrichTicketsLocally(
    List<Map<String, dynamic>> rawTickets,
  ) async {
    final routes = await UserDataManager().getRoutes();
    final buses = await HomeRepository().getBuses();

    return rawTickets.map((t) {
      final ticket = Map<String, dynamic>.from(t);
      final routeId = ticket['route_id'] as int?;
      final busId = ticket['bus_id'];

      if (routeId != null) {
        try {
          final matchedRoute = routes.firstWhere((r) => r.id == routeId);
          ticket['routes'] = {
            'name': matchedRoute.name,
            'price': matchedRoute.price,
          };
        } catch (_) {
          ticket['routes'] = null;
        }
      }

      if (busId != null) {
        try {
          final matchedBus =
              buses.firstWhere((b) => b['id'].toString() == busId.toString());
          ticket['buses'] = {
            'bus_number': matchedBus['bus_number'],
          };
        } catch (_) {
          ticket['buses'] = null;
        }
      }
      return ticket;
    }).toList();
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
      final priceStr =
          (item['routes'] as Map?)?['price']?.toString() ??
          item['price']?.toString() ??
          '0';
      return sum + (double.tryParse(priceStr) ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

          _buildSummarySection(),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Container(
              height: 50.h,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
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
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? _buildSkeletonList()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTicketList(
                          _activeTickets,
                          "No active tickets",
                          Icons.confirmation_number_outlined,
                          key: const ValueKey('active'),
                        ),
                        _buildTicketList(
                          _historyTickets,
                          "No history found",
                          Icons.history_rounded,
                          key: const ValueKey('history'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      child: Row(
        children: [
          _isLoading
              ? Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80.h,
                    borderRadius: 16.r,
                  ),
                )
              : _buildSummaryCard(
                  label: "Active tickets",
                  value: "${_activeTickets.length}",
                  unit: "tickets",
                ),
          SizedBox(width: 16.w),
          _isLoading
              ? Expanded(
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 80.h,
                    borderRadius: 16.r,
                  ),
                )
              : _buildSummaryCard(
                  label: "Total spent",
                  value: _totalSpent.toStringAsFixed(0),
                  unit: "EGP",
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String unit,
  }) {
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

  Widget _buildSkeletonList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 16.h),
      itemBuilder: (_, __) => SkeletonLoader(
        width: double.infinity,
        height: 100.h,
        borderRadius: 16.r,
      ),
    );
  }

  Widget _buildTicketList(
    List<dynamic> tickets,
    String emptyMsg,
    IconData emptyIcon, {
    required Key key,
  }) {
    return tickets.isEmpty
        ? SingleChildScrollView(
            key: key,
            physics: const ClampingScrollPhysics(),
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
            key: key,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 20.h),
            itemCount: tickets.length,
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) {
              final ticket = tickets[index];

              final routeName =
                  (ticket['routes'] as Map?)?['name']?.toString() ??
                  ticket['route'] ??
                  "---";
              final busNum =
                  (ticket['buses'] as Map?)?['bus_number']?.toString() ??
                  ticket['busNumber']?.toString() ??
                  "---";
              final price =
                  (ticket['routes'] as Map?)?['price']?.toString() ??
                  ticket['price']?.toString() ??
                  "0";

              final rawStatus =
                  ticket['status']?.toString().toLowerCase() ?? 'active';
              final displayStatus = rawStatus == 'active'
                  ? 'Sold'
                  : ticket['status'];

              final code = ticket['ticket_code']?.toString() ?? '';
              final ticketType = code.startsWith('MANUAL-')
                  ? 'Manual Ticket'
                  : 'QR Ticket';

              DateTime? createdAt;
              try {
                createdAt = DateTime.parse(ticket['created_at']);
              } catch (_) {}
              final timeStr = createdAt != null
                  ? DateFormat('hh:mm a').format(createdAt.toLocal())
                  : "--:--";
              final dateStr = createdAt != null
                  ? DateFormat('dd/MM/yyyy').format(createdAt.toLocal())
                  : "--/--";

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
          );
  }
}
