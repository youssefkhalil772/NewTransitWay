import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/core/widgets/custom_ticket_card.dart';
import 'package:transite_way/feature/home/data/home_repository.dart';

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

  const TicketHistoryItem({
    required this.route,
    required this.busNumber,
    required this.price,
    required this.time,
    required this.date,
    required this.dateTime,
    required this.status,
    required this.rawStatus,
  });

  factory TicketHistoryItem.fromMap(Map<String, dynamic> map) {
    final String s = map['status']?.toString().toLowerCase() ?? '';
    TicketStatus status = TicketStatus.other;
    
    if (s == 'sold' || s == 'valid' || s == 'active') {
      status = TicketStatus.sold;
    } else if (s == 'expired' || s == 'used') {
      status = TicketStatus.expired;
    }

    DateTime dt;
    try {
      final String datePart = map['date'] ?? DateFormat("dd-MM-yyyy").format(DateTime.now());
      final String timePart = map['time'] ?? "12:00 AM";
      dt = DateFormat("dd-MM-yyyy hh:mm a").parse("$datePart $timePart");
    } catch (_) {
      dt = DateTime.now();
    }

    return TicketHistoryItem(
      route: map['route'] ?? "Unknown Route",
      busNumber: map['busNumber']?.toString() ?? map['bus']?.toString() ?? "---",
      price: (map['price'] ?? "0").toString(),
      time: map['time'] ?? "--:--",
      date: map['date'] ?? "--/--",
      dateTime: dt,
      status: status,
      rawStatus: map['status'] ?? "Unknown",
    );
  }
}

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  final HomeRepository _homeRepository = HomeRepository();

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

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait([_fetchHistory(), _fetchSystemRoutes()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchSystemRoutes() async {
    try {
      final routes = await _homeRepository.getRoutes();
      if (mounted) {
        setState(() {
          _systemRoutes = routes.map((r) => r.name).toSet().toList()..sort();
        });
      }
    } catch (e) {
      debugPrint("Error fetching system routes: $e");
    }
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getInt('driverId');
    if (driverId == null) return;

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.driverTickets(driverId)}"),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _allTickets = data.map((t) => TicketHistoryItem.fromMap(t)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : Column(
              children: [
                _buildSummaryRow(),
                _buildStatusChips(),
                _buildDropdownFilters(),
                const Divider(height: 1, thickness: 0.5, color: Color(0xffE5E7EB)),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAllData,
                    color: _green,
                    child: filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => SizedBox(height: 20.h),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return CustomTicketCard(
                                busNumber: item.busNumber,
                                price: item.price,
                                time: item.time,
                                date: item.date,
                                route: item.route,
                                status: item.rawStatus,
                              );
                            },
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
        physics: const AlwaysScrollableScrollPhysics(),
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
