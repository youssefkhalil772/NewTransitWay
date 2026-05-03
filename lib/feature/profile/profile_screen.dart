import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/routes_manager.dart';
import '../home/presentation/widgets/custom_app_bar.dart';
import '../../core/widgets/common_profile_view.dart';
import '../notifications/data/notification_service.dart';
import 'report_complaint_screen.dart';
import 'user_edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onViewTickets;
  const ProfileScreen({super.key, this.onViewTickets});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User Name";
  String _userEmail = "email@example.com";
  String _userPhone = "";
  String _userPhoto = 'assets/logo/3.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? savedName = prefs.getString('fullName');
    String? savedEmail = prefs.getString('email');
    String? savedPhone = prefs.getString('phone') ?? prefs.getString('phoneNumber');
    String? savedPhoto = prefs.getString('userPhoto');

    debugPrint("--- DEBUG: LOADING PROFILE DATA ---");
    debugPrint("Name: $savedName");
    debugPrint("Email: $savedEmail");
    debugPrint("Phone: $savedPhone");
    debugPrint("Photo: $savedPhoto");
    debugPrint("-----------------------------------");

    setState(() {
      _userName = savedName ?? "Passenger User";
      _userEmail = savedEmail ?? "passenger@transit.com";
      _userPhone = savedPhone ?? "";
      _userPhoto = savedPhoto ?? 'assets/logo/3.png';
    });
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserEditProfileScreen(
          currentName: _userName,
          currentPhone: _userPhone,
          currentEmail: _userEmail,
          currentPhoto: _userPhoto,
        ),
      ),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  void _viewImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: _userPhoto.startsWith('http')
                  ? Image.network(_userPhoto, fit: BoxFit.contain)
                  : (_userPhoto.contains('assets') 
                      ? Image.asset(_userPhoto, fit: BoxFit.contain)
                      : Image.file(File(_userPhoto), fit: BoxFit.contain)),
            ),
            SizedBox(height: 15.h),
            CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(isDriver: false, showPoints: true),
      body: CommonProfileView(
        name: _userName,
        email: _userEmail,
        phone: _userPhone,
        imagePath: _userPhoto,
        isDriver: false,
        onImageTap: _viewImage,
        menuItems: [
          ProfileMenuItem(
            icon: Icons.edit_outlined,
            text: 'Edit Profile',
            iconColor: const Color(0xFF1B4D3E),
            onTap: _navigateToEditProfile,
          ),
          ProfileMenuItem(
            icon: Icons.star,
            text: 'Charge My Points',
            iconColor: Colors.amber,
            onTap: () => RoutesManager.navigateTo(context, RoutesManager.chargeMyPoints),
          ),
          ProfileMenuItem(
            icon: Icons.notifications_none_outlined,
            text: 'Notifications',
            iconColor: Colors.blueAccent,
            onTap: () => RoutesManager.navigateTo(context, RoutesManager.notifications),
            trailing: StreamBuilder<int>(
              stream: InAppNotificationService().unreadCountStream,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey);
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    count > 9 ? '+9' : count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          ProfileMenuItem(
            icon: Icons.confirmation_number_outlined,
            text: 'View My Tickets',
            iconColor: Colors.orangeAccent,
            onTap: () {
              if (widget.onViewTickets != null) {
                widget.onViewTickets!();
              } else {
                RoutesManager.navigateTo(context, RoutesManager.tickets);
              }
            },
          ),
          ProfileMenuItem(
            icon: Icons.report_problem_outlined,
            text: 'Report a Complaint',
            iconColor: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportComplaintScreen()),
            ),
          ),
          ProfileMenuItem(
            icon: Icons.logout,
            text: 'Log Out',
            iconColor: Colors.redAccent,
            isLogout: true,
          ),
        ],
      ),
    );
  }
}
