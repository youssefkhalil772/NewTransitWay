import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/widgets/custom_ticket_card.dart';
import 'package:transite_way/feature/driver/data/driver_data_manager.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';

enum TicketStatus { sold, expired, other }

class TicketHistoryItem {
  final String route;
  final String busNumber;
  final String price;
  final String time;
  final String date;
  final DateTime dateTime;
  final TicketStatus status;
  final String rawStatus;
  final String ticketType;

  const TicketHistoryItem({
    required this.route,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
    required this.dateTime,
    required this.status,
    required this.rawStatus,
    required this.ticketType,
  });
}

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  static const _green = Color(0xff39C449);
  static const _lightGreen = Color(0xffE8F7EA);
  static const _borderGreen = Color(0xffB8E7BE);
  static const _darkText = Color(0xff1A2E1C);
  static const _mutedText = Color(0xff6B7C6E);
  static const _amber = Color(0xffF59E0B);
  static const _lightAmber = Color(0xffFEF3C7);
  static const _darkAmber = Color(0xff633806);

  List<TicketHistoryItem> _allTickets = [];
  List<String> _systemRoutes = [];
  bool _isLoading = true;
  TicketStatus? _statusFilter;
  String? _routeFilter;
  String? _dateFilter;
  
  StreamSubscription? _ticketSubscription;
  String? _busId;
  String? _busNumber;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }
  
  @override
  void dispose() {
    _ticketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _busId = prefs.getString('busId');
    _busNumber = prefs.getString('busNumber') ?? '---';
    
    // Pre-fetch driver data cache
    await DriverDataManager().prefetchData();
    final routes = await DriverDataManager().getRoutes();
    if (mounted) {
      setState(() {
        _systemRoutes = routes.map((r) => r.name).toSet().toList()..sort();
      });
    }

    _setupRealtime();
  }

  void _setupRealtime() {
    if (_busId == null || _busId!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _ticketSubscription?.cancel();
    _ticketSubscription = SupabaseConfig.client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('bus_id', int.tryParse(_busId!) ?? _busId!)
        .listen(
      (data) async {
        final items = await _enrichTicketsLocally(data);
        if (mounted) {
          setState(() { 
          _allTickets = items;
          _isLoading = false; 
        });
        }
      },
      onError: (error) {
        debugPrint("History Stream error: $error");
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  Future<List<TicketHistoryItem>> _enrichTicketsLocally(List<Map<String, dynamic>> rawTickets) async {
    final routes = await DriverDataManager().getRoutes();
    
    // Sort descending by created_at
    final sortedTickets = List<Map<String, dynamic>>.from(rawTickets)..sort((a, b) {
      final tA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final tB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return tB.compareTo(tA);
    });

    return sortedTickets.map((t) {
      final routeId = t['route_id'] as int?;
      RouteModel? matchedRoute;
      if (routeId != null) {
        try { matchedRoute = routes.firstWhere((r) => r.id == routeId); } catch (_) {}
      }

      DateTime? createdAt;
      try { createdAt = DateTime.parse(t['created_at']); } catch (_) {}

      final s = t['status']?.toString().toLowerCase() ?? '';
      TicketStatus status = TicketStatus.other;
      if (s == 'active' || s == 'sold' || s == 'valid') {
        status = TicketStatus.sold;
      } else if (s == 'expired' || s == 'used') status = TicketStatus.expired;

      return TicketHistoryItem(
        route: matchedRoute?.name ?? 'Unknown Route',
        busNumber: _busNumber ?? '---',
        price: matchedRoute?.price.toStringAsFixed(0) ?? '0',
        time: createdAt != null ? DateFormat('hh:mm a').format(createdAt.toLocal()) : '--:--',
        date: createdAt != null ? DateFormat('dd-MM-yyyy').format(createdAt.toLocal()) : '--/--',
        dateTime: createdAt ?? DateTime.now(),
        status: status,
        rawStatus: s == 'active' ? 'Sold' : (t['status']?.toString() ?? 'Unknown'),
        ticketType: (t['ticket_code']?.toString().startsWith('MANUAL-') ?? false) ? 'Manual Ticket' : 'QR Ticket',
      );
    }).toList();
  }

  Future<void> _manualRefresh() async {
    if (mounted) setState(() => _isLoading = true);
    await DriverDataManager().prefetchData();
    _setupRealtime();
  }

  List<String> get _displayRoutes => _systemRoutes.isNotEmpty
      ? _systemRoutes
      : _allTickets.map((t) => t.route).toSet().toList()..sort();

  List<TicketHistoryItem> get _filtered {
    return _allTickets.where((t) {
      if (_statusFilter != null && t.status != _statusFilter) return false;
      if (_routeFilter != null && t.route != _routeFilter) return false;
      if (_dateFilter != null) {
        final now = DateTime.now();
        final diff = now.difference(t.dateTime).inDays;
        if (_dateFilter == 'Today' && diff >= 1) return false;
        if (_dateFilter == 'This week' && diff >= 7) return false;
        if (_dateFilter == 'This month' && diff >= 30) return false;
      }
      return true;
    }).toList();
  }

  int get _soldCount => _allTickets.where((t) => t.status == TicketStatus.sold).length;
  int get _expiredCount => _allTickets.where((t) => t.status == TicketStatus.expired).length;

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryRow(),
          _buildStatusChips(),
          _buildDropdownFilters(),
          const Divider(height: 1, thickness: 0.5, color: Color(0xffE5E7EB)),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      key: const ValueKey('loading'),
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                      itemCount: 5,
                      separatorBuilder: (_, __) => SizedBox(height: 20.h),
                      itemBuilder: (_, __) => SkeletonLoader(width: double.infinity, height: 100.h, borderRadius: 16.r),
                    )
                  : RefreshIndicator(
                      key: const ValueKey('list'),
                      onRefresh: _manualRefresh,
                      color: _green,
                      child: filtered.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => SizedBox(height: 20.h),
                              itemBuilder: (context, i) {
                                final item = filtered[i];
                                return CustomTicketCard(
                                  key: ValueKey('${item.route}_${item.time}_$i'),
                                  busNumber: item.busNumber,
                                  price: item.price,
                                  time: item.time,
                                  date: item.date,
                                  route: item.route,
                                  status: item.rawStatus,
                                  ticketType: item.ticketType,
                                );
                              },
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _borderGreen, width: 1.2),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: _green, size: 20),
          ),
        ),
        title: Text(
          'Ticket History',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _darkText),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xffE5E7EB)),
        ),
      );

  Widget _buildSummaryRow() => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
        child: Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Sold',
                value: '$_soldCount',
                sub: 'lifetime',
                bgColor: _lightGreen,
                borderColor: _borderGreen,
                valueColor: _darkText,
                subColor: _green,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _SummaryCard(
                label: 'Expired',
                value: '$_expiredCount',
                sub: 'lifetime',
                bgColor: _lightAmber,
                borderColor: const Color(0xfffcd34d),
                valueColor: _darkAmber,
                subColor: _amber,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatusChips() => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STATUS',
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: _mutedText, letterSpacing: 0.6),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _statusFilter == null,
                  selectedBg: const Color(0xffF0F0F0),
                  selectedBorder: const Color(0xff888888),
                  selectedText: const Color(0xff2C2C2A),
                  onTap: () => setState(() => _statusFilter = null),
                ),
                SizedBox(width: 8.w),
                _StatusChip(
                  label: 'Sold',
                  selected: _statusFilter == TicketStatus.sold,
                  selectedBg: _lightGreen,
                  selectedBorder: _green,
                  selectedText: const Color(0xff27500A),
                  onTap: () => setState(() => _statusFilter = _statusFilter == TicketStatus.sold ? null : TicketStatus.sold),
                ),
                SizedBox(width: 8.w),
                _StatusChip(
                  label: 'Expired',
                  selected: _statusFilter == TicketStatus.expired,
                  selectedBg: _lightAmber,
                  selectedBorder: _amber,
                  selectedText: _darkAmber,
                  onTap: () => setState(() => _statusFilter = _statusFilter == TicketStatus.expired ? null : TicketStatus.expired),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildDropdownFilters() => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: _DropdownFilter(
                hint: 'All Routes',
                value: _routeFilter,
                items: _displayRoutes,
                onChanged: (v) => setState(() => _routeFilter = v),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _DropdownFilter(
                hint: 'Any Date',
                value: _dateFilter,
                items: const ['Today', 'This week', 'This month'],
                onChanged: (v) => setState(() => _dateFilter = v),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => ListView(
        physics: const ClampingScrollPhysics(),
        children: [
          SizedBox(height: 100.h),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48.sp, color: _borderGreen),
                SizedBox(height: 12.h),
                Text('No tickets found', style: TextStyle(fontSize: 14.sp, color: _mutedText, fontWeight: FontWeight.bold)),
                SizedBox(height: 6.h),
                Text('Try changing filters or pull to refresh', style: TextStyle(fontSize: 12.sp, color: _mutedText)),
              ],
            ),
          ),
        ],
      );
}

class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final Color bgColor, borderColor, valueColor, subColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.bgColor,
    required this.borderColor,
    required this.valueColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp, color: const Color(0xff6B7C6E))),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: valueColor)),
          SizedBox(height: 2.h),
          Text(sub, style: TextStyle(fontSize: 10.sp, color: subColor)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedBg, selectedBorder, selectedText;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedBorder,
    required this.selectedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? selectedBorder : const Color(0xffD1D5DB),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: selected ? selectedText : const Color(0xff6B7C6E),
          ),
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xffB8E7BE), width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 11.sp, color: const Color(0xff6B7C6E))),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xff6B7C6E)),
          style: TextStyle(fontSize: 11.sp, color: const Color(0xff1A2E1C)),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(hint, style: TextStyle(fontSize: 11.sp, color: const Color(0xff6B7C6E))),
            ),
            ...items.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xff1A2E1C))),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
