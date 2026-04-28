import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transite_way/core/networking/api_constants.dart';
import 'package:transite_way/core/widgets/custom_ticket_card.dart';
import 'package:transite_way/feature/home/presentation/widgets/custom_app_bar.dart';

enum AddTicketStep { list, selectCount }

class AddTicketsScreen extends StatefulWidget {
  final bool isTab;
  const AddTicketsScreen({super.key, this.isTab = false});

  @override
  State<AddTicketsScreen> createState() => _AddTicketsScreenState();
}

class _AddTicketsScreenState extends State<AddTicketsScreen> {
  AddTicketStep _currentStep = AddTicketStep.list;
  int _ticketCount = 1;
  bool _isLoading = false;
  bool _isFetching = true;
  List<dynamic> _driverTicketsList = [];

  int? _driverId;
  int? _busId;
  int? _routeId;

  // --- هوية التطبيق ---
  final Color _green = const Color(0xff39C449);
  final Color _lightGreen = const Color(0xffE8F7EA);
  final Color _borderGreen = const Color(0xffB8E7BE);
  final Color _mutedText = const Color(0xff6B7C6E);

  double _ticketPrice = 30.0;

  @override
  void initState() {
    super.initState();
    _loadIdsAndFetch();
  }

  Future<void> _loadIdsAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _driverId = prefs.getInt('driverId');
      _busId = prefs.getInt('busId');
      _routeId = prefs.getInt('routeId');
    });
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    if (_driverId == null) {
      final prefs = await SharedPreferences.getInstance();
      _driverId = prefs.getInt('driverId');
      if (_driverId == null) {
        if (mounted) setState(() => _isFetching = false);
        return;
      }
    }
    
    if (mounted) setState(() => _isFetching = true);

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.driverTickets(_driverId!)}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _driverTicketsList = data is List ? data : [];
            if (_driverTicketsList.isNotEmpty) {
              final firstTicket = _driverTicketsList[0];
              _ticketPrice = (firstTicket['price'] as num?)?.toDouble() ?? 30.0;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching driver tickets: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _handleAddManualTickets() async {
    final prefs = await SharedPreferences.getInstance();
    _driverId = prefs.getInt('driverId');
    _busId = prefs.getInt('busId');
    _routeId = prefs.getInt('routeId');

    if (_driverId == null || _busId == null || _routeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Missing Data: Please restart the trip from Home"), 
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}${ApiConstants.createManualTicket}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "driverId": _driverId,
          "busId": _busId,
          "numberOfTickets": _ticketCount,
          "routeId": _routeId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? "Tickets created successfully"), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _ticketCount = 1;
          setState(() => _currentStep = AddTicketStep.list);
          _fetchTickets(); 
        }
      } else {
        throw Exception(responseData['message'] ?? "Failed to create tickets");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"), 
            backgroundColor: Colors.red, 
            behavior: SnackBarBehavior.floating
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _buildBody();
    if (widget.isTab) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(isDriver: true, showPoints: false),
      body: body,
    );
  }

  Widget _buildBody() {
    switch (_currentStep) {
      case AddTicketStep.list:
        return _buildTicketsList();
      case AddTicketStep.selectCount:
        return _buildSelectCount();
    }
  }

  Widget _buildTicketsList() {
    // فلترة التذاكر لعرض الـ Sold فقط
    final soldTickets = _driverTicketsList.where((t) {
      final status = t['status']?.toString().toLowerCase();
      return status == 'sold';
    }).toList();

    return Column(
      children: [
        Expanded(
          child: _isFetching
              ? Center(child: CircularProgressIndicator(color: _green))
              : RefreshIndicator(
                  onRefresh: _fetchTickets,
                  color: _green,
                  child: soldTickets.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 0.3.sh),
                            Center(
                              child: Text("No sold tickets yet", style: TextStyle(color: _mutedText)),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                          itemCount: soldTickets.length,
                          separatorBuilder: (_, __) => SizedBox(height: 20.h),
                          itemBuilder: (context, index) {
                            final ticket = soldTickets[index];
                            return CustomTicketCard(
                              busNumber: ticket['busNumber']?.toString() ?? "---",
                              price: ticket['price']?.toString() ?? "0",
                              time: ticket['time'] ?? "--:--",
                              date: ticket['date'] ?? "--/--",
                              route: ticket['route'], 
                              status: ticket['status'], 
                            );
                          },
                        ),
                ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: _buildUserPromptBox(),
        ),
      ],
    );
  }

  Widget _buildUserPromptBox() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(15.r)),
      margin: EdgeInsets.only(bottom: 20.h),
      child: Column(
        children: [
          Text("User doesn't have an account?", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 15.h),
          _buildActionButton("Add Ticket Here !", () {
             _loadIdsAndFetch();
             setState(() => _currentStep = AddTicketStep.selectCount);
          }),
        ],
      ),
    );
  }
  
  Widget _buildSelectCount() {
    final double totalAmount = _ticketCount * _ticketPrice;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.h),
            _PriceChip(price: _ticketPrice, green: _green, borderGreen: _borderGreen),
            SizedBox(height: 28.h),
            _InfoCard(
              label: "Number Of Manual Tickets",
              borderGreen: _borderGreen,
              valueWidget: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleIconBtn(
                    icon: Icons.remove_rounded,
                    green: _green,
                    borderGreen: _borderGreen,
                    onTap: () { if (_ticketCount > 1) setState(() => _ticketCount--); },
                  ),
                  SizedBox(width: 24.w),
                  Text("$_ticketCount", style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: _green)),
                  SizedBox(width: 24.w),
                  _CircleIconBtn(
                    icon: Icons.add_rounded,
                    green: _green,
                    borderGreen: _borderGreen,
                    onTap: () => setState(() => _ticketCount++),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            _InfoCard(
              label: "Total Amount",
              borderGreen: _borderGreen,
              valueWidget: Text("${totalAmount.toStringAsFixed(2)} EGP", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: _green)),
            ),
            const Spacer(),
            if (_isLoading)
              Center(child: CircularProgressIndicator(color: _green))
            else
              _buildActionButton("Confirm Add Tickets", _handleAddManualTickets),
            SizedBox(height: 12.h),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _currentStep = AddTicketStep.list),
                child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 14.sp, fontWeight: FontWeight.w500)),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 52.h,
    child: ElevatedButton(
      onPressed: onTap, 
      style: ElevatedButton.styleFrom(
        backgroundColor: _green, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        elevation: 0,
      ), 
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
    ),
  );
}

class _PriceChip extends StatelessWidget {
  final double price;
  final Color green, borderGreen;
  const _PriceChip({required this.price, required this.green, required this.borderGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderGreen, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("${price.toStringAsFixed(0)} - EGP", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black)),
          SizedBox(width: 8.w),
          Icon(Icons.keyboard_arrow_up, color: Colors.black54, size: 20.sp),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  final Color borderGreen;
  const _InfoCard({required this.label, required this.valueWidget, required this.borderGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
          SizedBox(height: 12.h),
          valueWidget,
        ],
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color green, borderGreen;
  const _CircleIconBtn({required this.icon, required this.onTap, required this.green, required this.borderGreen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: borderGreen, width: 2),
        ),
        child: Icon(icon, color: green, size: 24.sp),
      ),
    );
  }
}
