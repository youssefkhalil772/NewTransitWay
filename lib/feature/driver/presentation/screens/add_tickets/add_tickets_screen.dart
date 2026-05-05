import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transite_way/core/networking/supabase_init.dart';
import 'package:transite_way/core/utils/sound_manager.dart';
import 'package:transite_way/core/widgets/custom_ticket_card.dart';
import 'package:transite_way/feature/driver/data/driver_data_manager.dart';
import 'package:transite_way/feature/driver/presentation/screens/widgets/skeleton_loader.dart';
import 'package:transite_way/feature/home/data/models/route_model.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Main Screen
// ═══════════════════════════════════════════════════════════════════════════════
class AddTicketsScreen extends StatefulWidget {
  final bool isTab;
  const AddTicketsScreen({super.key, this.isTab = false});

  @override
  State<AddTicketsScreen> createState() => _AddTicketsScreenState();
}

class _AddTicketsScreenState extends State<AddTicketsScreen> {
  static const _green = Color(0xff39C449);
  static const _lightGreen = Color(0xffE8F7EA);
  static const _borderGreen = Color(0xffB8E7BE);
  static const _darkText = Color(0xff1A2E1C);
  static const _mutedText = Color(0xff6B7C6E);

  List<Map<String, dynamic>> _tickets = [];
  bool _isLoadingTickets = true;
  String? _busId;
  String? _driverId;
  String? _busNumber;
  StreamSubscription? _ticketSubscription;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetryDelay = 8;

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _driverId = Supabase.instance.client.auth.currentUser?.id;
    _busId = prefs.getString('busId');
    _busNumber = prefs.getString('busNumber') ?? '---';

    // Ensure driver static data is pre-fetched (Zero Latency cache)
    await DriverDataManager().prefetchData();

    if ((_busId == null || _busId!.isEmpty) && _driverId != null) {
      try {
        final busData = await SupabaseConfig.client
            .from('buses')
            .select('id, bus_number')
            .eq('driver_id', _driverId!)
            .maybeSingle();
        if (busData != null) {
          _busId = busData['id'].toString();
          _busNumber = busData['bus_number']?.toString() ?? '---';
          await prefs.setString('busId', _busId!);
          await prefs.setString('busNumber', _busNumber!);
        }
      } catch (_) {}
    }

    _setupRealtime();
  }

  void _setupRealtime() {
    if (_busId == null || _busId!.isEmpty) {
      if (mounted) setState(() => _isLoadingTickets = false);
      return;
    }

    _ticketSubscription?.cancel();
    _ticketSubscription = SupabaseConfig.client
        .from('tickets')
        .stream(primaryKey: ['id'])
        .eq('bus_id', int.tryParse(_busId!) ?? _busId!)
        .listen(
      (data) async {
        _retryCount = 0;
        
        if (data.length > _tickets.length && _tickets.isNotEmpty) {
          SoundManager.playNotification();
        }
        
        final enriched = await _enrichTicketsLocally(data);
        if (mounted) setState(() { _tickets = enriched; _isLoadingTickets = false; });
      },
      onError: (error) {
        _scheduleRealtimeRetry();
      },
    );
  }

  void _scheduleRealtimeRetry() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _retryCount++;
    final delaySec = (_retryCount * 2).clamp(2, _maxRetryDelay);
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      if (mounted) _setupRealtime();
    });
  }

  Future<List<Map<String, dynamic>>> _enrichTicketsLocally(List<Map<String, dynamic>> rawTickets) async {
    final routes = await DriverDataManager().getRoutes();
    
    // Sort descending by created_at
    final sortedTickets = List<Map<String, dynamic>>.from(rawTickets)..sort((a, b) {
      final tA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(2000);
      final tB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(2000);
      return tB.compareTo(tA);
    });

    return sortedTickets.map((t) {
      final ticket = Map<String, dynamic>.from(t);
      final routeId = ticket['route_id'] as int?;
      
      RouteModel? matchedRoute;
      if (routeId != null) {
        try { matchedRoute = routes.firstWhere((r) => r.id == routeId); } catch (_) {}
      }
      
      ticket['routes'] = matchedRoute != null ? {'name': matchedRoute.name, 'price': matchedRoute.price} : null;
      ticket['buses'] = {'bus_number': _busNumber}; // Bus is constant for this stream!
      return ticket;
    }).toList();
  }

  Future<void> _manualRefresh() async {
    if (!mounted) return;
    setState(() => _isLoadingTickets = true);
    await DriverDataManager().prefetchData();
    _setupRealtime();
  }


  void _showIssueSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => _IssueTicketsSheet(
        onSuccess: () {
          Navigator.pop(ctx);
          // Realtime stream handles the update, but we can call _manualRefresh just in case
          _manualRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody();
    if (widget.isTab) return body;
    return Scaffold(backgroundColor: Colors.white, body: body);
  }

  Widget _buildBody() {
    final activeCount = _tickets.where((t) => t['status'] == 'active').length;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showIssueSheet,
        backgroundColor: _green,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Issue Tickets',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tickets',
                            style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: _darkText)),
                        Text('All tickets issued for your bus',
                            style: TextStyle(fontSize: 12.sp, color: _mutedText)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: _manualRefresh,
                      icon: const Icon(Icons.refresh_rounded, color: _green)),
                ],
              ),
            ),
            // Summary Cards
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
              child: Row(
                children: [
                  _SummaryCard(
                      label: 'Total Tickets',
                      value: '${_tickets.length}',
                      icon: Icons.confirmation_number_outlined,
                      color: _green,
                      bg: _lightGreen,
                      border: _borderGreen),
                  SizedBox(width: 12.w),
                  _SummaryCard(
                      label: 'Active Tickets',
                      value: '$activeCount',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xff2563EB),
                      bg: const Color(0xffEFF6FF),
                      border: const Color(0xffBFDBFE)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xffE5E7EB)),
            // List
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoadingTickets
                    ? ListView.separated(
                        physics: const ClampingScrollPhysics(),
                        key: const ValueKey('loading'),
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                        itemCount: 5,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (_, __) => SkeletonLoader(
                            width: double.infinity,
                            height: 100.h,
                            borderRadius: 16.r),
                      )
                    : _tickets.isEmpty
                        ? _buildEmpty(key: const ValueKey('empty'))
                        : RefreshIndicator(
                            key: const ValueKey('list'),
                            onRefresh: _manualRefresh,
                            color: _green,
                            child: ListView.separated(
                              physics: const ClampingScrollPhysics(),
                              padding:
                                  EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
                              itemCount: _tickets.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 12.h),
                              itemBuilder: (_, i) {
                                final t = _tickets[i];
                                final routeName = (t['routes'] as Map?)?['name']
                                        ?.toString() ??
                                    '---';
                                final price = ((t['routes'] as Map?)?['price']
                                            as num?)
                                        ?.toStringAsFixed(0) ??
                                    '0';
                                final busNumber = (t['buses'] as Map?)?['bus_number']
                                        ?.toString() ??
                                    '---';
                                final rawStatus =
                                    t['status']?.toString() ?? 'active';
                                final status =
                                    rawStatus.toLowerCase() == 'active'
                                        ? 'Sold'
                                        : rawStatus;

                                final code = t['ticket_code']?.toString() ?? '';
                                final ticketType = code.startsWith('MANUAL-')
                                    ? 'Manual Ticket'
                                    : 'QR Ticket';

                                DateTime? createdAt;
                                try {
                                  createdAt = DateTime.parse(t['created_at']);
                                } catch (_) {}
                                final timeStr = createdAt != null
                                    ? DateFormat('hh:mm a')
                                        .format(createdAt.toLocal())
                                    : '--:--';
                                final dateStr = createdAt != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(createdAt.toLocal())
                                    : '--/--';
                                return CustomTicketCard(
                                  key: ValueKey(t['id']),
                                  busNumber: busNumber,
                                  price: price,
                                  time: timeStr,
                                  date: dateStr,
                                  route: routeName,
                                  status: status,
                                  ticketType: ticketType,
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty({Key? key}) => Center(
    key: key,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined, size: 56.sp, color: _borderGreen),
        SizedBox(height: 14.h),
        Text('No tickets yet', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: _darkText)),
        SizedBox(height: 6.h),
        Text('Tap "Issue Tickets" to add manual tickets', style: TextStyle(fontSize: 12.sp, color: _mutedText)),
      ],
    ),
  );
}



// ═══════════════════════════════════════════════════════════════════════════════
// Summary Card Widget
// ═══════════════════════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg, border;

  const _SummaryCard({
    required this.label, required this.value,
    required this.icon, required this.color,
    required this.bg, required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: border)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22.sp),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: TextStyle(fontSize: 10.sp, color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Issue Tickets Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════
class _IssueTicketsSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _IssueTicketsSheet({required this.onSuccess});

  @override
  State<_IssueTicketsSheet> createState() => _IssueTicketsSheetState();
}

class _IssueTicketsSheetState extends State<_IssueTicketsSheet> {
  static const _green = Color(0xff39C449);
  static const _lightGreen = Color(0xffE8F7EA);
  static const _borderGreen = Color(0xffB8E7BE);

  int _ticketCount = 1;
  bool _isLoading = false;
  Map<String, dynamic>? _successData;

  static const Map<String, String> _arabicErrors = {
    'No active trip for this bus': 'مفيش رحلة نشطة دلوقتي، ابدأ رحلة أولاً',
    'No bus assigned to driver': 'مفيش باص متعين ليك',
    'Invalid ticket price': 'السعر أو الخط غير صالح',
    'driverId and numberOfTickets are required': 'بيانات ناقصة، حاول تاني',
  };

  String _translateError(String? error) {
    if (error == null) return 'حصل خطأ غير متوقع';
    for (final entry in _arabicErrors.entries) {
      if (error.contains(entry.key)) return entry.value;
    }
    return error;
  }

  Future<void> _issueTickets() async {
    final int count = _ticketCount;
    if (count <= 0) return;
    final driverId = Supabase.instance.client.auth.currentUser?.id;
    if (driverId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'Manual-Tickets',
        body: {'driverId': driverId, 'numberOfTickets': count},
      );
      final data = response.data;
      if (data is Map && data['error'] != null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_translateError(data['error'].toString())),
            backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      if (mounted) {
        setState(() {
          _successData = data is Map ? Map<String, dynamic>.from(data) : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_translateError(e.toString())),
          backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _lightGreen,
          shape: BoxShape.circle,
          border: Border.all(color: _borderGreen, width: 2),
        ),
        child: Icon(icon, color: _green, size: 28.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _successData != null ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xffD1D5DB), borderRadius: BorderRadius.circular(2.r)))),
          SizedBox(height: 20.h),
          Row(children: [
            Container(padding: EdgeInsets.all(10.w), decoration: const BoxDecoration(color: _lightGreen, shape: BoxShape.circle), child: const Icon(Icons.confirmation_number, color: _green, size: 24)),
            SizedBox(width: 12.w),
            Text('Issue Manual Tickets', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xff1A2E1C))),
          ]),
          SizedBox(height: 6.h),
          Text('Enter the number of tickets, the price will be determined from the active route.', style: TextStyle(fontSize: 12.sp, color: const Color(0xff6B7C6E))),
          SizedBox(height: 32.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterButton(Icons.remove, () {
                if (_ticketCount > 1) {
                  setState(() => _ticketCount--);
                }
              }),
              SizedBox(width: 40.w),
              Text(
                '$_ticketCount', 
                style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold, color: _green)
              ),
              SizedBox(width: 40.w),
              _buildCounterButton(Icons.add, () {
                setState(() => _ticketCount++);
              }),
            ],
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _issueTickets,
              icon: _isLoading
                  ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(_isLoading ? 'Issuing...' : 'Issue Tickets', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: _green.withOpacity(0.5),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final data = _successData!;
    final int count = data['numberOfTickets'] ?? 0;
    final double price = (data['pricePerTicket'] as num?)?.toDouble() ?? 0;
    final double total = count * price;
    final String route = data['routeName'] ?? '---';

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: const Color(0xffD1D5DB), borderRadius: BorderRadius.circular(2.r)))),
          SizedBox(height: 24.h),
          Container(padding: EdgeInsets.all(18.w), decoration: const BoxDecoration(color: _lightGreen, shape: BoxShape.circle), child: const Icon(Icons.check_circle_rounded, color: _green, size: 52)),
          SizedBox(height: 16.h),
          Text('Tickets Issued Successfully!', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xff1A2E1C))),
          SizedBox(height: 4.h),
          Text(route, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: const Color(0xff6B7C6E)), overflow: TextOverflow.ellipsis),
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _borderGreen)),
            child: Column(children: [
              _summaryRow('Tickets Count', '$count tickets', Icons.confirmation_number_outlined),
              Divider(height: 20.h, color: _borderGreen),
              _summaryRow('Ticket Price', '${price.toStringAsFixed(0)} EGP', Icons.payments_outlined),
              Divider(height: 20.h, color: _borderGreen),
              _summaryRow('Total', '${total.toStringAsFixed(0)} EGP', Icons.calculate_outlined, bold: true),
            ]),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onSuccess,
              style: ElevatedButton.styleFrom(backgroundColor: _green, padding: EdgeInsets.symmetric(vertical: 16.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)), elevation: 0),
              child: Text('Done ✓', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon, {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, color: _green, size: 18.sp),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black54)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: bold ? _green : Colors.black87)),
      ],
    );
  }
}
